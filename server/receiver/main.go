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

	commonv1 "github.com/streaming-live-kalman/filter/gen/common/v1"
	controlv1 "github.com/streaming-live-kalman/filter/gen/control/v1"
	rxv1 "github.com/streaming-live-kalman/filter/gen/rx/v1"
	"github.com/streaming-live-kalman/filter/server/receiver/core"
	"github.com/streaming-live-kalman/filter/shared/config"
	"github.com/streaming-live-kalman/filter/shared/network"
	"github.com/streaming-live-kalman/filter/shared/node"
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
	lis, err := net.Listen("tcp", cfg.Receiver.Listen)
	if err != nil {
		slog.Error("listen", "error", err)
		os.Exit(1)
	}
	svc := core.New(cfg.Receiver)
	gs := grpc.NewServer()
	rxv1.RegisterReceiverServiceServer(gs, svc)
	commonv1.RegisterNodeServiceServer(gs, node.New(node.Config{NodeID: "receiver-1", DisplayName: "Kalman DSP Receiver", Role: commonv1.NodeRole_NODE_ROLE_RECEIVER, ListenAddress: cfg.Receiver.Listen, Capabilities: []*commonv1.Capability{{Name: "bpsk-demodulation", Version: "v1"}, {Name: "kalman-scalar", Version: "v1"}, {Name: "esp32-protobuf-ingest", Version: "v1"}}, Snapshot: svc.NodeSnapshot}))
	hs := &http.Server{Addr: cfg.Receiver.HTTPListen, Handler: svc.HTTPHandler(), ReadHeaderTimeout: 5 * time.Second}
	go runAdapt(ctx, cfg.Receiver.Controller, svc)
	go func() {
		slog.Info("ESP32 protobuf ingest listening", "address", cfg.Receiver.HTTPListen)
		if err := hs.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			slog.Error("http server", "error", err)
			stop()
		}
	}()
	go func() { <-ctx.Done(); gs.GracefulStop(); _ = hs.Shutdown(context.Background()) }()
	slog.Info("receiver gRPC listening", "address", cfg.Receiver.Listen)
	if err := gs.Serve(lis); err != nil {
		slog.Error("grpc server", "error", err)
	}
}

func runAdapt(ctx context.Context, address string, svc *core.Server) {
	for attempt := 0; ctx.Err() == nil; attempt++ {
		conn, err := network.Dial(ctx, address)
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
		case <-time.After(network.Backoff(attempt)):
		}
	}
}
func adaptSession(ctx context.Context, stream controlv1.ControllerService_AdaptClient, svc *core.Server) error {
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
