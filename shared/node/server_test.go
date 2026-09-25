package node

import (
	"context"
	"testing"

	commonv1 "github.com/streaming-live-kalman/filter/gen/common/v1"
)

func TestNodeInfoAndStatus(t *testing.T) {
	server := New(Config{NodeID: "rx-test", DisplayName: "Test Receiver", Role: commonv1.NodeRole_NODE_ROLE_RECEIVER, ListenAddress: "127.0.0.1:55052", Capabilities: []*commonv1.Capability{{Name: "kalman-scalar", Version: "v1"}}, Snapshot: func() Snapshot {
		return Snapshot{Health: commonv1.HealthState_HEALTH_STATE_READY, Active: true, PeerConnected: true, RunID: "run-1", ActiveConfigVersion: 4, LastSequence: 99}
	}})
	info, err := server.GetNodeInfo(context.Background(), &commonv1.Empty{})
	if err != nil {
		t.Fatal(err)
	}
	if info.Role != commonv1.NodeRole_NODE_ROLE_RECEIVER || len(info.Capabilities) != 1 {
		t.Fatalf("unexpected info: %+v", info)
	}
	status, err := server.GetNodeStatus(context.Background(), &commonv1.Empty{})
	if err != nil {
		t.Fatal(err)
	}
	if !status.Active || !status.PeerConnected || status.LastSequence != 99 || status.ActiveRunId != "run-1" {
		t.Fatalf("unexpected status: %+v", status)
	}
}
