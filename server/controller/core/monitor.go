package core

import (
	"encoding/json"
	"io"
	"log/slog"
	"math"
	"net/http"
	"sort"
	"time"

	controlv1 "github.com/streaming-live-kalman/filter/gen/control/v1"
	"github.com/streaming-live-kalman/filter/server/controller/extensions"
	"github.com/streaming-live-kalman/filter/shared/quality"
)

// MonitorSchemaVersion changes whenever the /api/v1/monitor shape changes.
const MonitorSchemaVersion = "1"

const assessmentHistory = 50

// runState is the Controller's live view of one receiver run.
type runState struct {
	streamOpen     bool // the receiver's Adapt stream is currently connected
	lastMetricAt   time.Time
	latest         *controlv1.ReceiverMetrics
	lastDecision   *controlv1.PolicyDecision
	assessWindow   []*controlv1.ReceiverMetrics
	assessments    []*controlv1.ChannelAssessment
	firstSeenAt    time.Time
	metricsCounter uint64
}

// SetQualityPredictor enables ML channel-quality prediction. Without it the
// Controller still publishes rule-based measured classes.
func (s *Server) SetQualityPredictor(p extensions.QualityPredictor) { s.quality = p }

// SetMetricsRecorder appends every received ReceiverMetrics to w as JSON lines
// (one object per line) so real runs can be used as training data.
func (s *Server) SetMetricsRecorder(w io.Writer) {
	s.recorderMu.Lock()
	defer s.recorderMu.Unlock()
	s.recorder = json.NewEncoder(w)
}

func (s *Server) record(m *controlv1.ReceiverMetrics) {
	s.recorderMu.Lock()
	defer s.recorderMu.Unlock()
	if s.recorder == nil {
		return
	}
	if err := s.recorder.Encode(m); err != nil {
		slog.Warn("metrics log write failed; disabling recorder", "error", err)
		s.recorder = nil
	}
}

func (s *Server) runLocked(id string) *runState {
	r := s.runs[id]
	if r == nil {
		r = &runState{firstSeenAt: time.Now()}
		s.runs[id] = r
	}
	return r
}

// observe updates live state for one metrics message and, once a full
// non-overlapping window has accumulated, returns a channel assessment.
func (s *Server) observe(m *controlv1.ReceiverMetrics) *controlv1.ChannelAssessment {
	s.mu.Lock()
	r := s.runLocked(m.RunId)
	r.streamOpen = true
	r.lastMetricAt = time.Now()
	r.latest = m
	r.metricsCounter++
	r.assessWindow = append(r.assessWindow, m)
	if len(r.assessWindow) < s.cfg.WindowSize {
		s.mu.Unlock()
		return nil
	}
	window := r.assessWindow
	r.assessWindow = nil
	s.mu.Unlock()

	w, err := quality.Summarise(window)
	if err != nil {
		slog.Warn("channel assessment skipped", "run", m.RunId, "error", err)
		return nil
	}
	a := &controlv1.ChannelAssessment{
		WindowFirstSequence: w.First,
		WindowLastSequence:  w.Last,
		MeasuredClass:       w.MeasuredClass().String(),
		Features:            w.Features(),
		FeatureNames:        quality.FeatureNames,
		HorizonFrames:       uint32(s.cfg.WindowSize),
	}
	if s.quality != nil {
		class, confidence, probs, err := s.quality.PredictQuality(a.Features)
		if err != nil {
			slog.Warn("quality prediction failed; publishing measured class only", "run", m.RunId, "error", err)
		} else {
			a.PredictedClass, a.Confidence, a.ModelVersion = class, float32(confidence), s.quality.ModelVersion()
			for _, p := range probs {
				a.ClassProbabilities = append(a.ClassProbabilities, float32(p))
			}
		}
	}
	s.mu.Lock()
	r.assessments = append(r.assessments, a)
	if len(r.assessments) > assessmentHistory {
		r.assessments = r.assessments[len(r.assessments)-assessmentHistory:]
	}
	s.mu.Unlock()
	return a
}

func (s *Server) streamClosed(runs map[string]bool) {
	s.mu.Lock()
	defer s.mu.Unlock()
	for id := range runs {
		if r := s.runs[id]; r != nil {
			r.streamOpen = false
		}
	}
}

func (s *Server) rememberDecision(run string, d *controlv1.PolicyDecision) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.runLocked(run).lastDecision = d
}

// ---- /api/v1/monitor --------------------------------------------------------

type monitorResponse struct {
	SchemaVersion string       `json:"schema_version"`
	GeneratedAt   string       `json:"generated_at"`
	DeviceID      string       `json:"device_id"`
	Policy        string       `json:"policy"`
	RecommendOnly bool         `json:"recommend_only"`
	ModelVersion  *string      `json:"quality_model_version"`
	Runs          []monitorRun `json:"runs"`
}

type monitorRun struct {
	RunID            string            `json:"run_id"`
	DeviceID         string            `json:"device_id"`
	ConnectionStatus string            `json:"connection_status"` // connected | connection_lost
	StreamStatus     string            `json:"stream_status"`     // data_flow_active | data_flow_inactive
	SequenceNumber   uint64            `json:"sequence_number"`
	Timestamp        string            `json:"timestamp"`
	AgeMs            int64             `json:"age_ms"`
	FramesReceived   uint64            `json:"frames_received"`
	FramesLost       uint64            `json:"frames_lost"`
	SNR              *float64          `json:"snr"`
	BER              *float64          `json:"ber"`
	BERNote          string            `json:"ber_note,omitempty"`
	NoiseVariance    *float64          `json:"noise_variance"`
	PhaseError       *float64          `json:"phase_error"`
	PhaseErrorNote   string            `json:"phase_error_note"`
	LatencyMs        *float64          `json:"latency_ms"`
	PSNR             *float64          `json:"psnr"`
	SSIM             *float64          `json:"ssim"`
	ImageNote        string            `json:"image_metrics_note"`
	QueueDepth       uint32            `json:"queue_depth"`
	Applied          appliedParams     `json:"applied"`
	Recommended      *recommendedParam `json:"recommended"`
	ML               *mlBlock          `json:"ml"`
}

type appliedParams struct {
	ConfigVersion uint64   `json:"config_version"`
	KalmanQ       *float64 `json:"kalman_q"`
	KalmanR       *float64 `json:"kalman_r"`
	Rho           *float64 `json:"rho"`
}

type recommendedParam struct {
	Policy         string   `json:"policy"`
	KalmanQ        *float64 `json:"kalman_q"`
	KalmanR        *float64 `json:"kalman_r"`
	Rho            *float64 `json:"rho"`
	Version        uint64   `json:"proposed_version"`
	EffectiveSeq   uint64   `json:"effective_sequence"`
	SentToReceiver bool     `json:"sent_to_receiver"`
	Reason         string   `json:"reason"`
}

type mlBlock struct {
	MeasuredClass  string             `json:"measured_class"`
	PredictedClass *string            `json:"predicted_class"`
	Confidence     *float64           `json:"confidence"`
	Probabilities  map[string]float64 `json:"probabilities,omitempty"`
	ModelVersion   *string            `json:"model_version"`
	WindowFirstSeq uint64             `json:"window_first_sequence"`
	WindowLastSeq  uint64             `json:"window_last_sequence"`
	HorizonFrames  uint32             `json:"horizon_frames"`
	Features       map[string]float64 `json:"features"`
}

func num(v float64) *float64 {
	if math.IsNaN(v) || math.IsInf(v, 0) {
		return nil
	}
	return &v
}

func str(v string) *string {
	if v == "" {
		return nil
	}
	return &v
}

func (s *Server) staleAfter() time.Duration {
	if s.cfg.StaleAfterMs > 0 {
		return time.Duration(s.cfg.StaleAfterMs) * time.Millisecond
	}
	return 2 * time.Second
}

// Monitor builds the structured monitoring snapshot. Every value comes from a
// received ReceiverMetrics, PolicyDecision or ChannelAssessment; values the
// pipeline does not measure are null with an explanatory note.
func (s *Server) Monitor(now time.Time) monitorResponse {
	s.mu.RLock()
	defer s.mu.RUnlock()
	resp := monitorResponse{SchemaVersion: MonitorSchemaVersion, GeneratedAt: now.UTC().Format(time.RFC3339Nano), DeviceID: "controller-1", Policy: s.cfg.Policy, RecommendOnly: s.cfg.RecommendOnly, Runs: []monitorRun{}}
	if resp.Policy == "" {
		resp.Policy = "rule"
	}
	if s.quality != nil {
		resp.ModelVersion = str(s.quality.ModelVersion())
	}
	ids := make([]string, 0, len(s.runs))
	for id := range s.runs {
		ids = append(ids, id)
	}
	sort.Strings(ids)
	for _, id := range ids {
		r := s.runs[id]
		m := r.latest
		if m == nil {
			continue
		}
		age := now.Sub(r.lastMetricAt)
		run := monitorRun{
			RunID: id, DeviceID: "receiver-1",
			ConnectionStatus: "connection_lost", StreamStatus: "data_flow_inactive",
			SequenceNumber: m.Sequence, Timestamp: time.UnixMilli(int64(m.ObservedAtUnixMs)).UTC().Format(time.RFC3339Nano),
			AgeMs: age.Milliseconds(), FramesReceived: r.metricsCounter, FramesLost: m.SequenceGaps,
			SNR: num(float64(m.SnrDb)), NoiseVariance: num(float64(m.NoiseVariance)), LatencyMs: num(m.LatencyMs),
			PhaseErrorNote: "not measured: the BPSK pipeline carries real-valued samples and the receiver has no carrier-phase tracker",
			ImageNote:      "PSNR/SSIM need the original and reconstructed image; computed by the dashboard or cmd/imgquality, not by the controller",
			QueueDepth:     m.QueueDepth,
			Applied:        appliedParams{ConfigVersion: m.ActiveConfigVersion},
		}
		if r.streamOpen {
			run.ConnectionStatus = "connected"
		}
		if r.streamOpen && age <= s.staleAfter() {
			run.StreamStatus = "data_flow_active"
		}
		if m.ComparedBits > 0 {
			run.BER = num(float64(m.Ber))
		} else {
			run.BERNote = "no reference bits in this frame, BER not measurable"
		}
		if m.ActiveKalmanQ > 0 && m.ActiveKalmanR > 0 {
			run.Applied.KalmanQ, run.Applied.KalmanR = num(float64(m.ActiveKalmanQ)), num(float64(m.ActiveKalmanR))
			run.Applied.Rho = num(float64(m.ActiveKalmanQ) / float64(m.ActiveKalmanR))
		}
		if d := r.lastDecision; d != nil {
			rec := &recommendedParam{Policy: d.Policy, KalmanQ: num(float64(d.ProposedKalmanQ)), KalmanR: num(float64(d.ProposedKalmanR)), Version: d.ProposedVersion, EffectiveSeq: d.EffectiveSequence, SentToReceiver: d.SentToReceiver, Reason: d.Reason}
			if d.ProposedKalmanR > 0 {
				rec.Rho = num(float64(d.ProposedKalmanQ) / float64(d.ProposedKalmanR))
			}
			run.Recommended = rec
		}
		if n := len(r.assessments); n > 0 {
			run.ML = mlFromAssessment(r.assessments[n-1])
		}
		resp.Runs = append(resp.Runs, run)
	}
	return resp
}

func mlFromAssessment(a *controlv1.ChannelAssessment) *mlBlock {
	b := &mlBlock{MeasuredClass: a.MeasuredClass, PredictedClass: str(a.PredictedClass), ModelVersion: str(a.ModelVersion), WindowFirstSeq: a.WindowFirstSequence, WindowLastSeq: a.WindowLastSequence, HorizonFrames: a.HorizonFrames, Features: map[string]float64{}}
	for i, name := range a.FeatureNames {
		if i < len(a.Features) {
			if v := num(float64(a.Features[i])); v != nil {
				b.Features[name] = *v
			}
		}
	}
	if a.PredictedClass != "" {
		b.Confidence = num(float64(a.Confidence))
		b.Probabilities = map[string]float64{}
		for i, c := range quality.Classes {
			if i < len(a.ClassProbabilities) {
				b.Probabilities[c.String()] = float64(a.ClassProbabilities[i])
			}
		}
	}
	return b
}

// assessmentHistoryJSON returns the recent assessments for one run (or all).
func (s *Server) assessmentHistoryJSON(run string) map[string][]*mlBlock {
	s.mu.RLock()
	defer s.mu.RUnlock()
	out := map[string][]*mlBlock{}
	for id, r := range s.runs {
		if run != "" && id != run {
			continue
		}
		for _, a := range r.assessments {
			out[id] = append(out[id], mlFromAssessment(a))
		}
	}
	return out
}

func writeJSON(w http.ResponseWriter, status int, v any) {
	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("Cache-Control", "no-store")
	w.WriteHeader(status)
	if err := json.NewEncoder(w).Encode(v); err != nil {
		slog.Warn("write JSON response", "error", err)
	}
}

func (s *Server) registerMonitorRoutes(mux *http.ServeMux) {
	mux.HandleFunc("/api/v1/monitor", func(w http.ResponseWriter, r *http.Request) {
		writeJSON(w, http.StatusOK, s.Monitor(time.Now()))
	})
	mux.HandleFunc("/api/v1/ml/history", func(w http.ResponseWriter, r *http.Request) {
		writeJSON(w, http.StatusOK, s.assessmentHistoryJSON(r.URL.Query().Get("run")))
	})
	mux.HandleFunc("/api/v1/ml/model", func(w http.ResponseWriter, r *http.Request) {
		if s.quality == nil || len(s.quality.ModelReport()) == 0 {
			writeJSON(w, http.StatusNotFound, map[string]string{"error": "no channel-quality model is loaded (set controller.qualityModel)"})
			return
		}
		w.Header().Set("Content-Type", "application/json")
		w.Header().Set("Cache-Control", "no-store")
		_, _ = w.Write(s.quality.ModelReport())
	})
}
