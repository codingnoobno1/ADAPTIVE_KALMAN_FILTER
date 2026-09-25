package main

import (
	"context"
	"flag"
	"log/slog"
	"net"
	"os"
	"os/signal"
	"syscall"
	"time"

	rxv1 "github.com/streaming-live-kalman/filter/gen/rx/v1"
	txv1 "github.com/streaming-live-kalman/filter/gen/tx/v1"
	"github.com/streaming-live-kalman/filter/internal/config"
	"github.com/streaming-live-kalman/filter/internal/netutil"
	txsvc "github.com/streaming-live-kalman/filter/internal/tx"
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
	lis, err := net.Listen("tcp", cfg.TX.Listen)
	if err != nil {
		slog.Error("listen", "error", err)
		os.Exit(1)
	}
	svc := txsvc.New(cfg.TX)
	gs := grpc.NewServer()
	txv1.RegisterTransmitterServiceServer(gs, svc)
	go func() { <-ctx.Done(); gs.GracefulStop() }()
	go runSignal(ctx, cfg.TX.Receiver, svc)
	slog.Info("transmitter gRPC listening", "address", cfg.TX.Listen)
	if err := gs.Serve(lis); err != nil {
		slog.Error("grpc server", "error", err)
	}
}
func runSignal(ctx context.Context, address string, svc *txsvc.Server) {
	for attempt := 0; ctx.Err() == nil; attempt++ {
		conn, err := netutil.Dial(ctx, address)
		if err == nil {
			attempt = 0
			err = svc.RunStream(ctx, rxv1.NewReceiverServiceClient(conn))
			_ = conn.Close()
		}
		if ctx.Err() != nil {
			return
		}
		slog.Warn("receiver stream disconnected", "error", err)
		select {
		case <-ctx.Done():
			return
		case <-time.After(netutil.Backoff(attempt)):
		}
	}
}
