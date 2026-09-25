package main

import (
	"context"
	"flag"
	"log/slog"
	"net"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	controlv1 "github.com/streaming-live-kalman/filter/gen/control/v1"
	"github.com/streaming-live-kalman/filter/internal/config"
	controllersvc "github.com/streaming-live-kalman/filter/internal/controller"
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
	lis, err := net.Listen("tcp", cfg.Controller.Listen)
	if err != nil {
		slog.Error("listen", "error", err)
		os.Exit(1)
	}
	svc := controllersvc.New(cfg.Controller)
	grpcServer := grpc.NewServer()
	controlv1.RegisterControllerServiceServer(grpcServer, svc)
	httpServer := &http.Server{Addr: cfg.Controller.HTTPListen, Handler: svc.HTTPHandler(), ReadHeaderTimeout: 5 * time.Second}
	go func() {
		slog.Info("controller HTTP/SSE listening", "address", cfg.Controller.HTTPListen)
		if err := httpServer.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			slog.Error("http server", "error", err)
			stop()
		}
	}()
	go func() { <-ctx.Done(); grpcServer.GracefulStop(); _ = httpServer.Shutdown(context.Background()) }()
	slog.Info("controller gRPC listening", "address", cfg.Controller.Listen)
	if err := grpcServer.Serve(lis); err != nil {
		slog.Error("grpc server", "error", err)
	}
}
