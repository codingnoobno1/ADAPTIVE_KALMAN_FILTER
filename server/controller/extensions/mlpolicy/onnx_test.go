package mlpolicy

import (
	"context"
	"encoding/json"
	"math"
	"os"
	"path/filepath"
	"testing"

	controlv1 "github.com/streaming-live-kalman/filter/gen/control/v1"
)

var modelPath = filepath.Join("..", "..", "..", "..", "ml", "models", "r_policy.onnx")

func loadTestPolicy(t *testing.T) *Policy {
	t.Helper()
	if _, err := os.Stat(modelPath); err != nil {
		t.Skip("model not trained yet; run ml/train.py")
	}
	p, err := Load(modelPath, 0.02, 4.0, 12)
	if err != nil {
		t.Fatal(err)
	}
	return p
}

// TestGonnxMatchesPython replays vectors that ml/train.py produced with
// onnxruntime, proving the pure-Go runtime computes the same model.
func TestGonnxMatchesPython(t *testing.T) {
	p := loadTestPolicy(t)
	raw, err := os.ReadFile(filepath.Join(filepath.Dir(modelPath), "r_policy.golden.json"))
	if err != nil {
		t.Fatal(err)
	}
	var golden []struct {
		Features []float32 `json:"features"`
		LogRho   float64   `json:"log_rho"`
	}
	if err := json.Unmarshal(raw, &golden); err != nil {
		t.Fatal(err)
	}
	if len(golden) == 0 {
		t.Fatal("no golden vectors")
	}
	for i, g := range golden {
		rho, err := p.PredictRho(g.Features)
		if err != nil {
			t.Fatal(err)
		}
		if diff := math.Abs(math.Log(rho) - g.LogRho); diff > 1e-4 {
			t.Fatalf("vector %d: gonnx log_rho=%.6f python=%.6f", i, math.Log(rho), g.LogRho)
		}
	}
}

func TestEvaluateWaitsForWindowAndClamps(t *testing.T) {
	p := loadTestPolicy(t)
	window := make([]*controlv1.ReceiverMetrics, 0, 12)
	for i := 0; i < 12; i++ {
		window = append(window, &controlv1.ReceiverMetrics{SnrDb: 3, NoiseVariance: 0.5})
		d, err := p.Evaluate(context.Background(), window)
		if err != nil {
			t.Fatal(err)
		}
		if i < 11 && d != nil {
			t.Fatalf("decision before the window was full (len %d)", len(window))
		}
		if i == 11 {
			if d == nil {
				t.Fatal("no decision with a full window")
			}
			rho := float64(d.ProposedKalmanQ / d.ProposedKalmanR)
			if d.ProposedKalmanR != 0.5 || rho < MinRho*0.999 || rho > MaxRho*1.001 {
				t.Fatalf("decision outside bounds: %+v", d)
			}
		}
	}
}

func TestFeaturesClipNoiselessSNR(t *testing.T) {
	f := Features([]*controlv1.ReceiverMetrics{{SnrDb: 100, NoiseVariance: 0, FrameMean: 0.1}, {SnrDb: 100, NoiseVariance: 0, FrameMean: 0.4}})
	if f[0] != MaxSNRDB || f[1] != 0 || math.Abs(float64(f[5])-0.3) > 1e-6 || math.Abs(float64(f[4])-0.15) > 1e-6 {
		t.Fatalf("features=%v", f)
	}
}
