// Package mlpolicy runs a trained ONNX model as the Controller's adaptation
// policy using gonnx, a pure-Go ONNX runtime (no cgo, no native DLLs).
//
// The Receiver's Kalman filter tracks the channel's DC drift, and only the ratio
// rho = Q/R sets how fast it follows. The model contract is produced by
// ml/train.py and documented in docs/ml-policy.md:
//
//	input  "features" float32[1,6] = snr_db_mean, snr_db_std, noise_var_mean,
//	                                 noise_var_std, frame_mean_std, frame_mean_step
//	output "log_rho"  float32[1,1] = natural log of Q/R
//
// Feature scaling is baked into the graph, so callers pass raw metrics. The
// decision sends R = noise variance (clamped to the configured bounds) and
// Q = rho * R.
package mlpolicy

import (
	"context"
	"fmt"
	"math"
	"sync"

	"github.com/advancedclimatesystems/gonnx"
	"gorgonia.org/tensor"

	controlv1 "github.com/streaming-live-kalman/filter/gen/control/v1"
)

const (
	InputName  = "features"
	OutputName = "log_rho"
	// MaxSNRDB matches cmd/datagen: the receiver reports 100 dB for a
	// noiseless frame, which is clipped so it cannot dominate the features.
	MaxSNRDB = 60
	// MinRho and MaxRho are the range the model was trained on (cmd/datagen).
	MinRho = 1e-7
	MaxRho = 10
)

type Policy struct {
	mu         sync.Mutex // gonnx models are not documented as concurrency-safe
	model      *gonnx.Model
	minR, maxR float32
	minWindow  int
}

// Load reads an ONNX model and checks it exposes the expected contract.
func Load(path string, minR, maxR float32, minWindow int) (*Policy, error) {
	model, err := gonnx.NewModelFromFile(path)
	if err != nil {
		return nil, fmt.Errorf("load onnx model %s: %w", path, err)
	}
	if !contains(model.InputNames(), InputName) || !contains(model.OutputNames(), OutputName) {
		return nil, fmt.Errorf("onnx model %s must have input %q and output %q (got %v -> %v); retrain with ml/train.py", path, InputName, OutputName, model.InputNames(), model.OutputNames())
	}
	if minWindow < 2 {
		minWindow = 2
	}
	return &Policy{model: model, minR: minR, maxR: maxR, minWindow: minWindow}, nil
}

// Features converts a metrics window into the model's input vector. It must
// match windowFeatures in cmd/datagen.
func Features(window []*controlv1.ReceiverMetrics) []float32 {
	snr := make([]float64, len(window))
	nv := make([]float64, len(window))
	fm := make([]float64, len(window))
	for i, m := range window {
		snr[i] = math.Min(float64(m.SnrDb), MaxSNRDB)
		nv[i] = float64(m.NoiseVariance)
		fm[i] = float64(m.FrameMean)
	}
	snrMean, snrStd := meanStd(snr)
	nvMean, nvStd := meanStd(nv)
	_, fmStd := meanStd(fm)
	var step float64
	for i := 1; i < len(fm); i++ {
		step += math.Abs(fm[i] - fm[i-1])
	}
	if len(fm) > 1 {
		step /= float64(len(fm) - 1)
	}
	return []float32{float32(snrMean), float32(snrStd), float32(nvMean), float32(nvStd), float32(fmStd), float32(step)}
}

// PredictRho returns the unclamped model output exp(log_rho).
func (p *Policy) PredictRho(features []float32) (float64, error) {
	input := tensor.New(tensor.WithShape(1, len(features)), tensor.WithBacking(append([]float32(nil), features...)))
	p.mu.Lock()
	outputs, err := p.model.Run(gonnx.Tensors{InputName: input})
	p.mu.Unlock()
	if err != nil {
		return 0, fmt.Errorf("onnx inference: %w", err)
	}
	out, ok := outputs[OutputName]
	if !ok {
		return 0, fmt.Errorf("onnx output %q missing", OutputName)
	}
	values, ok := out.Data().([]float32)
	if !ok || len(values) != 1 {
		return 0, fmt.Errorf("onnx output %q must be one float32, got %T", OutputName, out.Data())
	}
	return math.Exp(float64(values[0])), nil
}

// Evaluate implements extensions.AdaptationPolicy. It waits for a full
// feature window, and any non-finite prediction is rejected rather than sent.
func (p *Policy) Evaluate(_ context.Context, window []*controlv1.ReceiverMetrics) (*controlv1.PolicyDecision, error) {
	if len(window) < p.minWindow {
		return nil, nil
	}
	features := Features(window)
	rho, err := p.PredictRho(features)
	if err != nil {
		return nil, err
	}
	if math.IsNaN(rho) || math.IsInf(rho, 0) {
		return nil, fmt.Errorf("onnx model produced non-finite rho")
	}
	rho = math.Max(MinRho, math.Min(MaxRho, rho))
	r := math.Max(float64(p.minR), math.Min(float64(p.maxR), float64(features[2])))
	return &controlv1.PolicyDecision{
		ProposedKalmanQ: float32(rho * r),
		ProposedKalmanR: float32(r),
		Reason:          fmt.Sprintf("onnx: snr %.1f dB, drift step %.3f -> Q/R %.3g", features[0], features[5], rho),
	}, nil
}

func meanStd(v []float64) (float64, float64) {
	if len(v) == 0 {
		return 0, 0
	}
	var sum, sq float64
	for _, x := range v {
		sum += x
	}
	mean := sum / float64(len(v))
	for _, x := range v {
		sq += (x - mean) * (x - mean)
	}
	return mean, math.Sqrt(sq / float64(len(v)))
}

func contains(values []string, want string) bool {
	for _, v := range values {
		if v == want {
			return true
		}
	}
	return false
}
