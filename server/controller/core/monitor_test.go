package core

import (
	"bytes"
	"encoding/json"
	"errors"
	"math"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	controlv1 "github.com/streaming-live-kalman/filter/gen/control/v1"
	"github.com/streaming-live-kalman/filter/shared/config"
)

type fakePredictor struct{ fail bool }

func (f fakePredictor) PredictQuality(features []float32) (string, float64, []float64, error) {
	if f.fail {
		return "", 0, nil, errors.New("boom")
	}
	return "poor", 0.7, []float64{0.1, 0.1, 0.7, 0.1}, nil
}
func (fakePredictor) ModelVersion() string { return "test-v1" }
func (fakePredictor) ModelReport() []byte  { return []byte(`{"model_version":"test-v1"}`) }

func newTestServer(window int) *Server {
	return New(config.Controller{WindowSize: window, MinKalmanR: 0.02, MaxKalmanR: 4, StaleAfterMs: 500}, nil)
}

func TestAssessmentEveryFullWindow(t *testing.T) {
	s := newTestServer(3)
	s.SetQualityPredictor(fakePredictor{})
	var got []*controlv1.ChannelAssessment
	for i := uint64(1); i <= 7; i++ {
		if a := s.observe(&controlv1.ReceiverMetrics{RunId: "r", Sequence: i, SnrDb: 4, Ber: 0.05, ComparedBits: 64, NoiseVariance: 0.3}); a != nil {
			got = append(got, a)
		}
	}
	if len(got) != 2 {
		t.Fatalf("7 frames with window 3 should give 2 assessments, got %d", len(got))
	}
	a := got[0]
	if a.WindowFirstSequence != 1 || a.WindowLastSequence != 3 || a.MeasuredClass != "poor" || a.PredictedClass != "poor" || a.ModelVersion != "test-v1" || len(a.ClassProbabilities) != 4 {
		t.Fatalf("unexpected assessment %+v", a)
	}
}

func TestPredictionFailureKeepsMeasuredClass(t *testing.T) {
	s := newTestServer(2)
	s.SetQualityPredictor(fakePredictor{fail: true})
	s.observe(&controlv1.ReceiverMetrics{RunId: "r", Sequence: 1, SnrDb: 20})
	a := s.observe(&controlv1.ReceiverMetrics{RunId: "r", Sequence: 2, SnrDb: 20})
	if a == nil || a.MeasuredClass != "good" || a.PredictedClass != "" {
		t.Fatalf("expected a measured-only assessment, got %+v", a)
	}
}

func TestMonitorSnapshotValuesAndNulls(t *testing.T) {
	s := newTestServer(2)
	now := time.Now()
	s.observe(&controlv1.ReceiverMetrics{RunId: "r", Sequence: 9, SnrDb: float32(math.Inf(1)), NoiseVariance: 0.2, ComparedBits: 0, LatencyMs: 1.5, ObservedAtUnixMs: uint64(now.UnixMilli()), ActiveConfigVersion: 3, ActiveKalmanQ: 0.01, ActiveKalmanR: 0.5, SequenceGaps: 2})
	s.rememberDecision("r", &controlv1.PolicyDecision{Policy: "rule", ProposedKalmanQ: 0.02, ProposedKalmanR: 0.5, ProposedVersion: 4, SentToReceiver: false})
	m := s.Monitor(now)
	if len(m.Runs) != 1 {
		t.Fatalf("runs: %+v", m.Runs)
	}
	r := m.Runs[0]
	if r.ConnectionStatus != "connected" || r.StreamStatus != "data_flow_active" || r.SequenceNumber != 9 || r.FramesLost != 2 {
		t.Fatalf("status fields: %+v", r)
	}
	if r.SNR != nil || r.BER != nil || r.PhaseError != nil || r.PSNR != nil || r.SSIM != nil {
		t.Fatalf("unmeasured or non-finite values must be null: %+v", r)
	}
	if r.Applied.Rho == nil || math.Abs(*r.Applied.Rho-0.02) > 1e-6 || r.Recommended == nil || r.Recommended.SentToReceiver {
		t.Fatalf("applied/recommended: %+v %+v", r.Applied, r.Recommended)
	}
	var buf bytes.Buffer
	if err := json.NewEncoder(&buf).Encode(m); err != nil {
		t.Fatalf("snapshot must always be valid JSON: %v", err)
	}

	// Stale data: no metrics for longer than staleAfterMs.
	if got := s.Monitor(now.Add(time.Second)).Runs[0].StreamStatus; got != "data_flow_inactive" {
		t.Fatalf("stale stream reported as %s", got)
	}
	// Receiver disconnects.
	s.streamClosed(map[string]bool{"r": true})
	if got := s.Monitor(now).Runs[0].ConnectionStatus; got != "connection_lost" {
		t.Fatalf("closed stream reported as %s", got)
	}
}

func TestMonitorHTTPRoutes(t *testing.T) {
	s := newTestServer(2)
	h := s.HTTPHandler()
	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, httptest.NewRequest("GET", "/api/v1/monitor", nil))
	if rec.Code != 200 || !strings.Contains(rec.Body.String(), `"schema_version":"1"`) {
		t.Fatalf("monitor: %d %s", rec.Code, rec.Body.String())
	}
	rec = httptest.NewRecorder()
	h.ServeHTTP(rec, httptest.NewRequest("GET", "/api/v1/ml/model", nil))
	if rec.Code != 404 {
		t.Fatalf("model endpoint without a model should be 404, got %d", rec.Code)
	}
	s.SetQualityPredictor(fakePredictor{})
	rec = httptest.NewRecorder()
	h.ServeHTTP(rec, httptest.NewRequest("GET", "/api/v1/ml/model", nil))
	if rec.Code != 200 || !json.Valid(rec.Body.Bytes()) {
		t.Fatalf("model endpoint: %d %s", rec.Code, rec.Body.String())
	}
}

func TestMetricsRecorderWritesJSONLines(t *testing.T) {
	s := newTestServer(2)
	var buf bytes.Buffer
	s.SetMetricsRecorder(&buf)
	s.record(&controlv1.ReceiverMetrics{RunId: "r", Sequence: 1})
	s.record(&controlv1.ReceiverMetrics{RunId: "r", Sequence: 2})
	lines := strings.Split(strings.TrimSpace(buf.String()), "\n")
	if len(lines) != 2 || !json.Valid([]byte(lines[0])) {
		t.Fatalf("recorder output: %q", buf.String())
	}
}
