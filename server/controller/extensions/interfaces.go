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

// EventSink supports future databases, UI gateways and audit exporters.
type EventSink interface {
	Publish(context.Context, *controlv1.ExperimentEvent) error
}
