package core

import (
	"context"
	"fmt"
	"math"

	controlv1 "github.com/streaming-live-kalman/filter/gen/control/v1"
	"github.com/streaming-live-kalman/filter/shared/config"
)

// DefaultTrackingRatio is Q/R for the receiver's DC tracker when no model is
// used: the single fixed ratio with the lowest mean BER on the training set
// (ml/models/report.json, "best_fixed_rho").
const DefaultTrackingRatio = 0.0268

// RulePolicy is the rule-based baseline: R follows the latest receiver noise
// variance estimate, clamped to the configured bounds, and Q keeps the fixed
// tracking ratio Q/R = DefaultTrackingRatio.
type RulePolicy struct {
	MinR, MaxR float32
}

func NewRulePolicy(cfg config.Controller) *RulePolicy {
	return &RulePolicy{MinR: cfg.MinKalmanR, MaxR: cfg.MaxKalmanR}
}

func (p *RulePolicy) Evaluate(_ context.Context, window []*controlv1.ReceiverMetrics) (*controlv1.PolicyDecision, error) {
	if len(window) == 0 {
		return nil, nil
	}
	m := window[len(window)-1]
	targetR := float32(math.Max(float64(p.MinR), math.Min(float64(p.MaxR), float64(m.NoiseVariance))))
	return &controlv1.PolicyDecision{ProposedKalmanQ: targetR * DefaultTrackingRatio, ProposedKalmanR: targetR, Reason: fmt.Sprintf("rule: noise %.4f, fixed Q/R %.3g", m.NoiseVariance, DefaultTrackingRatio)}, nil
}
