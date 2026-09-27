// Package extensions defines receiver-side DSP and AI extension boundaries.
package extensions

import (
	"context"

	commonv1 "github.com/streaming-live-kalman/filter/gen/common/v1"
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

// MediaDetector can replace the built-in signature/UTF-8 detector later with
// an AI classifier without changing the common media streaming API.
type MediaDetector interface {
	Detect(context.Context, []byte, *commonv1.MediaDescriptor) (commonv1.MediaType, string, error)
}
