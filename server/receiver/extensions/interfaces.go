// Package extensions defines receiver-side DSP and AI extension boundaries.
package extensions

import (
	"context"

	controlv1 "github.com/streaming-live-kalman/filter/gen/control/v1"
	rxv1 "github.com/streaming-live-kalman/filter/gen/rx/v1"
)

// FrameProcessor owns state that survives across sequential sample frames.
type FrameProcessor interface {
	Process(context.Context, *rxv1.TxFrame) (*rxv1.RxFeedback, *controlv1.ReceiverMetrics, error)
	Reset(reason string)
}

// MetricsEnricher is the future integration point for AI classification,
// anomaly detection or additional signal-quality estimates.
type MetricsEnricher interface {
	Enrich(context.Context, *controlv1.ReceiverMetrics) error
}
