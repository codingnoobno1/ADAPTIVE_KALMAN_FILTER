package main

import (
	"context"
	"flag"
	"io"
	"log/slog"
	"net"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	controlv1 "github.com/streaming-live-kalman/filter/gen/control/v1"
	rxv1 "github.com/streaming-live-kalman/filter/gen/rx/v1"
	"github.com/streaming-live-kalman/filter/internal/config"
	"github.com/streaming-live-kalman/filter/internal/netutil"
	rxsvc "github.com/streaming-live-kalman/filter/internal/rx"
	"google.golang.org/grpc"
)

func main() {
	configPath := flag.String("config", "configs/local.json", "configuration JSON")
	flag.Parse()
	cfg, err := config.Load(*configPath)
	if err != nil {
		slog.Error("load config", "error", err)
		os.Exit(1)
	}
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()
	lis, err := net.Listen("tcp", cfg.RX.Listen)
	if err != nil {
		slog.Error("listen", "error", err)
		os.Exit(1)
	}
	svc := rxsvc.New(cfg.RX)
	gs := grpc.NewServer()
	rxv1.RegisterReceiverServiceServer(gs, svc)
	hs := &http.Server{Addr: cfg.RX.HTTPListen, Handler: svc.HTTPHandler(), ReadHeaderTimeout: 5 * time.Second}
	go runAdapt(ctx, cfg.RX.Controller, svc)
	go func() {
		slog.Info("ESP32 protobuf ingest listening", "address", cfg.RX.HTTPListen)
		if err := hs.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			slog.Error("http server", "error", err)
			stop()
		}
	}()
	go func() { <-ctx.Done(); gs.GracefulStop(); _ = hs.Shutdown(context.Background()) }()
	slog.Info("receiver gRPC listening", "address", cfg.RX.Listen)
	if err := gs.Serve(lis); err != nil {
		slog.Error("grpc server", "error", err)
	}
}

func runAdapt(ctx context.Context, address string, svc *rxsvc.Server) {
	for attempt := 0; ctx.Err() == nil; attempt++ {
		conn, err := netutil.Dial(ctx, address)
		if err == nil {
			client := controlv1.NewControllerServiceClient(conn)
			stream, e := client.Adapt(ctx)
			if e == nil {
				attempt = 0
				err = adaptSession(ctx, stream, svc)
			} else {
				err = e
			}
			_ = conn.Close()
		}
		if ctx.Err() != nil {
			return
		}
		slog.Warn("controller stream disconnected", "error", err)
		select {
		case <-ctx.Done():
			return
		case <-time.After(netutil.Backoff(attempt)):
		}
	}
}
func adaptSession(ctx context.Context, stream controlv1.ControllerService_AdaptClient, svc *rxsvc.Server) error {
	recvErr := make(chan error, 1)
	go func() {
		for {
			d, err := stream.Recv()
			if err != nil {
				recvErr <- err
				return
			}
			svc.AcceptDecision(d)
		}
	}()
	for {
		select {
		case <-ctx.Done():
			return ctx.Err()
		case err := <-recvErr:
			if err == io.EOF {
				return nil
			}
			return err
		case m := <-svc.Metrics():
			if err := stream.Send(m); err != nil {
				return err
			}
		}
	}
}
