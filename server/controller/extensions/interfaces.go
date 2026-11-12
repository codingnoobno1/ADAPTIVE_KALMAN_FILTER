// Package extensions defines controller policy and observability boundaries.
package extensions

import (
	"context"

	controlv1 "github.com/streaming-live-kalman/filter/gen/control/v1"
)

// AdaptationPolicy may be rule-based, statistical or AI-assisted. A nil
// decision means the active configuration should be retained.
type AdaptationPolicy interface {
	Evaluate(context.Context, []*controlv1.ReceiverMetrics) (*controlv1.PolicyDecision, error)
}

// QualityPredictor predicts the next window's channel-quality class from the
// current window's features (shared/quality.FeatureNames order). It returns
// the class name, its probability and all class probabilities in
// shared/quality.Classes order.
type QualityPredictor interface {
	PredictQuality(features []float32) (class string, confidence float64, probabilities []float64, err error)
	ModelVersion() string
	// ModelReport is the training/evaluation report (JSON), or nil.
	ModelReport() []byte
}

// EventSink supports future databases, UI gateways and audit exporters.
type EventSink interface {
	Publish(context.Context, *controlv1.ExperimentEvent) error
}
