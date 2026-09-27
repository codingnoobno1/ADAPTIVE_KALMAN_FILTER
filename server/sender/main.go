package main

import (
	"context"
	"flag"
	"log/slog"
	"net"
	"net/http"
	"os"
	"os/signal"
	"strings"
	"syscall"
	"time"

	commonv1 "github.com/streaming-live-kalman/filter/gen/common/v1"
	rxv1 "github.com/streaming-live-kalman/filter/gen/rx/v1"
	txv1 "github.com/streaming-live-kalman/filter/gen/tx/v1"
	"github.com/streaming-live-kalman/filter/server/sender/core"
	"github.com/streaming-live-kalman/filter/shared/config"
	"github.com/streaming-live-kalman/filter/shared/network"
	"github.com/streaming-live-kalman/filter/shared/node"
	"google.golang.org/grpc"
)

func main() {
	configPath := flag.String("config", "configs/local.json", "configuration JSON")
	var sendFiles fileList
	flag.Var(&sendFiles, "send", "file to transmit once the link is up (repeatable)")
	flag.Parse()
	cfg, err := config.Load(*configPath)
	if err != nil {
		slog.Error("load config", "error", err)
		os.Exit(1)
	}
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()
	lis, err := net.Listen("tcp", cfg.Sender.Listen)
	if err != nil {
		slog.Error("listen", "error", err)
		os.Exit(1)
	}
	svc := core.New(cfg.Sender)
	for _, path := range sendFiles {
		data, err := os.ReadFile(path)
		if err != nil {
			slog.Error("read file to send", "path", path, "error", err)
			os.Exit(1)
		}
		st, err := svc.EnqueueTransfer(core.TransferRequest{FileName: path, Data: data})
		if err != nil {
			slog.Error("queue file", "path", path, "error", err)
			os.Exit(1)
		}
		slog.Info("queued file", "name", st.FileName, "bytes", st.TotalBytes, "content_type", st.ContentType, "estimated_seconds", st.EstimatedSeconds)
	}
	if cfg.Sender.HTTPListen != "" {
		httpServer := &http.Server{Addr: cfg.Sender.HTTPListen, Handler: svc.HTTPHandler(), ReadHeaderTimeout: 5 * time.Second}
		go func() {
			slog.Info("sender HTTP file API listening", "address", cfg.Sender.HTTPListen)
			if err := httpServer.ListenAndServe(); err != nil && err != http.ErrServerClosed {
				slog.Error("sender http server", "error", err)
			}
		}()
		go func() { <-ctx.Done(); _ = httpServer.Shutdown(context.Background()) }()
	}
	gs := grpc.NewServer()
	txv1.RegisterTransmitterServiceServer(gs, svc)
	commonv1.RegisterNodeServiceServer(gs, node.New(node.Config{NodeID: "sender-1", DisplayName: "BPSK Sender", Role: commonv1.NodeRole_NODE_ROLE_TRANSMITTER, ListenAddress: cfg.Sender.Listen, Capabilities: []*commonv1.Capability{{Name: "bpsk-generator", Version: "v1"}, {Name: "awgn-channel", Version: "v1"}, {Name: "sample-stream", Version: "v1"}}, Snapshot: svc.NodeSnapshot}))
	go func() { <-ctx.Done(); gs.GracefulStop() }()
	go runSignal(ctx, cfg.Sender.Receiver, svc)
	slog.Info("sender gRPC listening", "address", cfg.Sender.Listen)
	if err := gs.Serve(lis); err != nil {
		slog.Error("grpc server", "error", err)
	}
}

type fileList []string

func (f *fileList) String() string     { return strings.Join(*f, ",") }
func (f *fileList) Set(v string) error { *f = append(*f, v); return nil }

func runSignal(ctx context.Context, address string, svc *core.Server) {
	for attempt := 0; ctx.Err() == nil; attempt++ {
		conn, err := network.Dial(ctx, address)
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
		case <-time.After(network.Backoff(attempt)):
		}
	}
}
