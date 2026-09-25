package node

import (
	"context"
	"time"

	commonv1 "github.com/streaming-live-kalman/filter/gen/common/v1"
)

// Snapshot is the role-neutral runtime state exposed by every node.
type Snapshot struct {
	Health              commonv1.HealthState
	Active              bool
	PeerConnected       bool
	RunID               string
	ActiveConfigVersion uint64
	LastSequence        uint64
	Message             string
}

type Config struct {
	NodeID        string
	DisplayName   string
	Role          commonv1.NodeRole
	ListenAddress string
	Capabilities  []*commonv1.Capability
	Snapshot      func() Snapshot
}

type Server struct {
	commonv1.UnimplementedNodeServiceServer
	config  Config
	started time.Time
}

func New(config Config) *Server { return &Server{config: config, started: time.Now()} }

func (s *Server) GetNodeInfo(context.Context, *commonv1.Empty) (*commonv1.NodeInfo, error) {
	return &commonv1.NodeInfo{NodeId: s.config.NodeID, DisplayName: s.config.DisplayName, Role: s.config.Role, ApiVersion: "v1", ListenAddress: s.config.ListenAddress, Capabilities: s.config.Capabilities}, nil
}

func (s *Server) GetNodeStatus(context.Context, *commonv1.Empty) (*commonv1.NodeStatus, error) {
	return s.status(), nil
}

func (s *Server) WatchNodeStatus(req *commonv1.WatchNodeRequest, stream commonv1.NodeService_WatchNodeStatusServer) error {
	interval := time.Duration(req.IntervalMs) * time.Millisecond
	if interval < 250*time.Millisecond {
		interval = time.Second
	}
	if interval > 30*time.Second {
		interval = 30 * time.Second
	}
	ticker := time.NewTicker(interval)
	defer ticker.Stop()
	for {
		if err := stream.Send(s.status()); err != nil {
			return err
		}
		select {
		case <-stream.Context().Done():
			return stream.Context().Err()
		case <-ticker.C:
		}
	}
}

func (s *Server) status() *commonv1.NodeStatus {
	snapshot := Snapshot{Health: commonv1.HealthState_HEALTH_STATE_READY, Message: "ready"}
	if s.config.Snapshot != nil {
		snapshot = s.config.Snapshot()
	}
	return &commonv1.NodeStatus{NodeId: s.config.NodeID, Role: s.config.Role, Health: snapshot.Health, Active: snapshot.Active, PeerConnected: snapshot.PeerConnected, ActiveRunId: snapshot.RunID, ActiveConfigVersion: snapshot.ActiveConfigVersion, LastSequence: snapshot.LastSequence, UptimeMs: uint64(time.Since(s.started).Milliseconds()), Message: snapshot.Message, ObservedAtUnixMs: uint64(time.Now().UnixMilli())}
}
