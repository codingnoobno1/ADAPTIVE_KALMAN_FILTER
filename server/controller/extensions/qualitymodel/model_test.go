package qualitymodel

import (
	"encoding/json"
	"math"
	"os"
	"testing"
)

const modelPath = "../../../../ml/models/quality.onnx"

// TestGonnxMatchesPython replays the onnxruntime outputs recorded by
// ml/train_quality.py through the Go runtime.
func TestGonnxMatchesPython(t *testing.T) {
	m, err := Load(modelPath)
	if err != nil {
		t.Fatal(err)
	}
	b, err := os.ReadFile("../../../../ml/models/quality.golden.json")
	if err != nil {
		t.Fatal(err)
	}
	var golden struct {
		ModelVersion string `json:"model_version"`
		Vectors      []struct {
			Features []float32 `json:"features"`
			Logits   []float32 `json:"logits"`
		} `json:"vectors"`
	}
	if err := json.Unmarshal(b, &golden); err != nil {
		t.Fatal(err)
	}
	if len(golden.Vectors) == 0 {
		t.Fatal("no golden vectors")
	}
	if m.Version != golden.ModelVersion {
		t.Fatalf("model version %q does not match golden %q", m.Version, golden.ModelVersion)
	}
	for i, v := range golden.Vectors {
		got, err := m.Logits(v.Features)
		if err != nil {
			t.Fatal(err)
		}
		for j := range got {
			if math.Abs(float64(got[j]-v.Logits[j])) > 1e-4 {
				t.Fatalf("vector %d logit %d: gonnx %v, onnxruntime %v", i, j, got[j], v.Logits[j])
			}
		}
		p, err := m.Predict(v.Features)
		if err != nil {
			t.Fatal(err)
		}
		var sum float64
		for _, q := range p.Probabilities {
			sum += q
		}
		if math.Abs(sum-1) > 1e-6 || p.Confidence < 0.25 || p.Confidence > 1 {
			t.Fatalf("vector %d: invalid probabilities %+v", i, p)
		}
	}
}

func TestRejectsInvalidInput(t *testing.T) {
	m, err := Load(modelPath)
	if err != nil {
		t.Fatal(err)
	}
	if _, err := m.Predict([]float32{1, 2}); err == nil {
		t.Fatal("wrong feature count was accepted")
	}
	bad := make([]float32, 10)
	bad[3] = float32(math.NaN())
	if _, err := m.Predict(bad); err == nil {
		t.Fatal("NaN feature was accepted")
	}
}
