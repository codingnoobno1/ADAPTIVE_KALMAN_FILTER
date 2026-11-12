// Package qualitymodel runs the channel-quality classifier exported by
// ml/train_quality.py through gonnx (pure Go, no cgo).
//
// Contract: input "features" float32[1,len(quality.FeatureNames)] (raw values,
// scaling is inside the graph) -> output "logits" float32[1,4] over
// good, moderate, poor, unstable. Softmax is applied here.
package qualitymodel

import (
	"encoding/json"
	"fmt"
	"math"
	"os"
	"path/filepath"
	"sync"

	"github.com/advancedclimatesystems/gonnx"
	"gorgonia.org/tensor"

	"github.com/streaming-live-kalman/filter/shared/quality"
)

const (
	InputName  = "features"
	OutputName = "logits"
)

// Prediction is one model output.
type Prediction struct {
	Class         quality.Class
	Confidence    float64
	Probabilities []float64 // in quality.Classes order
}

// Model wraps a loaded ONNX classifier and its training report.
type Model struct {
	mu      sync.Mutex // gonnx models are not documented as concurrency-safe
	model   *gonnx.Model
	Version string
	Report  json.RawMessage
}

// Load reads quality.onnx and, if present, quality_report.json from the same
// directory (for the model version and evaluation metrics).
func Load(path string) (*Model, error) {
	m, err := gonnx.NewModelFromFile(path)
	if err != nil {
		return nil, fmt.Errorf("load quality model %s: %w", path, err)
	}
	if !contains(m.InputNames(), InputName) || !contains(m.OutputNames(), OutputName) {
		return nil, fmt.Errorf("quality model %s must have input %q and output %q; retrain with ml/train_quality.py", path, InputName, OutputName)
	}
	out := &Model{model: m, Version: "unversioned"}
	if b, err := os.ReadFile(filepath.Join(filepath.Dir(path), "quality_report.json")); err == nil && json.Valid(b) {
		var meta struct {
			ModelVersion string `json:"model_version"`
			Features     []string
		}
		if json.Unmarshal(b, &meta) == nil {
			if len(meta.Features) > 0 && !equal(meta.Features, quality.FeatureNames) {
				return nil, fmt.Errorf("quality model was trained on features %v, server computes %v", meta.Features, quality.FeatureNames)
			}
			if meta.ModelVersion != "" {
				out.Version = meta.ModelVersion
			}
		}
		out.Report = b
	}
	return out, nil
}

// Logits returns the raw model output for one feature vector.
func (m *Model) Logits(features []float32) ([]float32, error) {
	if len(features) != len(quality.FeatureNames) {
		return nil, fmt.Errorf("quality model needs %d features, got %d", len(quality.FeatureNames), len(features))
	}
	for _, v := range features {
		if math.IsNaN(float64(v)) || math.IsInf(float64(v), 0) {
			return nil, fmt.Errorf("quality model input contains a non-finite value")
		}
	}
	input := tensor.New(tensor.WithShape(1, len(features)), tensor.WithBacking(append([]float32(nil), features...)))
	m.mu.Lock()
	outputs, err := m.model.Run(gonnx.Tensors{InputName: input})
	m.mu.Unlock()
	if err != nil {
		return nil, fmt.Errorf("quality inference: %w", err)
	}
	out, ok := outputs[OutputName]
	if !ok {
		return nil, fmt.Errorf("quality model output %q missing", OutputName)
	}
	values, ok := out.Data().([]float32)
	if !ok || len(values) != len(quality.Classes) {
		return nil, fmt.Errorf("quality model must output %d float32 logits, got %T", len(quality.Classes), out.Data())
	}
	return values, nil
}

// Predict applies softmax to the logits and returns the most likely class.
func (m *Model) Predict(features []float32) (Prediction, error) {
	logits, err := m.Logits(features)
	if err != nil {
		return Prediction{}, err
	}
	maxLogit := math.Inf(-1)
	for _, l := range logits {
		maxLogit = math.Max(maxLogit, float64(l))
	}
	probs := make([]float64, len(logits))
	var sum float64
	for i, l := range logits {
		probs[i] = math.Exp(float64(l) - maxLogit)
		sum += probs[i]
	}
	best := 0
	for i := range probs {
		probs[i] /= sum
		if probs[i] > probs[best] {
			best = i
		}
	}
	return Prediction{Class: quality.Classes[best], Confidence: probs[best], Probabilities: probs}, nil
}

// PredictQuality implements extensions.QualityPredictor.
func (m *Model) PredictQuality(features []float32) (string, float64, []float64, error) {
	p, err := m.Predict(features)
	if err != nil {
		return "", 0, nil, err
	}
	return p.Class.String(), p.Confidence, p.Probabilities, nil
}

// ModelVersion implements extensions.QualityPredictor.
func (m *Model) ModelVersion() string { return m.Version }

// ModelReport implements extensions.QualityPredictor.
func (m *Model) ModelReport() []byte { return m.Report }

func contains(values []string, want string) bool {
	for _, v := range values {
		if v == want {
			return true
		}
	}
	return false
}

func equal(a, b []string) bool {
	if len(a) != len(b) {
		return false
	}
	for i := range a {
		if a[i] != b[i] {
			return false
		}
	}
	return true
}
