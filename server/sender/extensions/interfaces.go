// Package extensions defines sender-side plug-in boundaries. Implementations
// may live in separate packages without changing sender/main.go or gRPC code.
package extensions

import (
	"context"

	rxv1 "github.com/streaming-live-kalman/filter/gen/rx/v1"
)

// SignalSource can be implemented by the simulator, an SDR, audio capture,
// serial input or a recorded experiment.
type SignalSource interface {
	NextFrame(context.Context) (*rxv1.TxFrame, error)
}

// ChannelModel applies a simulated channel impairment before transmission.
type ChannelModel interface {
	Apply(context.Context, *rxv1.TxFrame) error
}
