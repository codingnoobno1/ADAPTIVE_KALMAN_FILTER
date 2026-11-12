package main

import (
	"context"
	"flag"
	"log/slog"
	"net"
	"net/http"
	"os"
	"os/signal"
	"path/filepath"
	"syscall"
	"time"

	commonv1 "github.com/streaming-live-kalman/filter/gen/common/v1"
	controlv1 "github.com/streaming-live-kalman/filter/gen/control/v1"
	"github.com/streaming-live-kalman/filter/server/controller/core"
	"github.com/streaming-live-kalman/filter/server/controller/extensions"
	"github.com/streaming-live-kalman/filter/server/controller/extensions/mlpolicy"
	"github.com/streaming-live-kalman/filter/server/controller/extensions/qualitymodel"
	"github.com/streaming-live-kalman/filter/shared/config"
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
	lis, err := net.Listen("tcp", cfg.Controller.Listen)
	if err != nil {
		slog.Error("listen", "error", err)
		os.Exit(1)
	}
	var policy extensions.AdaptationPolicy
	if cfg.Controller.Policy == "onnx" {
		p, err := mlpolicy.Load(cfg.Controller.OnnxModel, cfg.Controller.MinKalmanR, cfg.Controller.MaxKalmanR, cfg.Controller.WindowSize)
		if err != nil {
			slog.Error("load onnx policy", "error", err)
			os.Exit(1)
		}
		policy = p
	}
	slog.Info("adaptation policy", "policy", cfg.Controller.Policy, "model", cfg.Controller.OnnxModel)
	svc := core.New(cfg.Controller, policy)
	if cfg.Controller.QualityModel != "" {
		qm, err := qualitymodel.Load(cfg.Controller.QualityModel)
		if err != nil {
			// Not fatal: the data path and adaptation keep working; only the
			// ML prediction is missing and the monitor reports it as null.
			slog.Error("channel-quality model unavailable; publishing measured classes only", "error", err)
		} else {
			svc.SetQualityPredictor(qm)
			slog.Info("channel-quality model loaded", "model", cfg.Controller.QualityModel, "version", qm.Version)
		}
	}
	if cfg.Controller.MetricsLog != "" {
		if err := os.MkdirAll(filepath.Dir(cfg.Controller.MetricsLog), 0o755); err != nil {
			slog.Error("metrics log directory", "error", err)
			os.Exit(1)
		}
		f, err := os.OpenFile(cfg.Controller.MetricsLog, os.O_CREATE|os.O_APPEND|os.O_WRONLY, 0o644)
		if err != nil {
			slog.Error("open metrics log", "error", err)
			os.Exit(1)
		}
		defer f.Close()
		svc.SetMetricsRecorder(f)
		slog.Info("recording receiver metrics", "path", cfg.Controller.MetricsLog)
	}
	grpcServer := grpc.NewServer()
	controlv1.RegisterControllerServiceServer(grpcServer, svc)
	commonv1.RegisterNodeServiceServer(grpcServer, node.New(node.Config{NodeID: "controller-1", DisplayName: "Experiment Controller", Role: commonv1.NodeRole_NODE_ROLE_CONTROLLER, ListenAddress: cfg.Controller.Listen, Capabilities: []*commonv1.Capability{{Name: "adaptive-policy", Version: "v1"}, {Name: "experiment-events", Version: "v1"}, {Name: "dashboard-sse", Version: "v1"}, {Name: "channel-quality-monitor", Version: "v1"}}, Snapshot: svc.NodeSnapshot}))
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
