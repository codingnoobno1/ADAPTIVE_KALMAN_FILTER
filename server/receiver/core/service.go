package core

import (
	"context"
	"fmt"
	"io"
	"log/slog"
	"math"
	"net/http"
	"sync"
	"time"

	commonv1 "github.com/streaming-live-kalman/filter/gen/common/v1"
	controlv1 "github.com/streaming-live-kalman/filter/gen/control/v1"
	rxv1 "github.com/streaming-live-kalman/filter/gen/rx/v1"
	"github.com/streaming-live-kalman/filter/shared/config"
	"github.com/streaming-live-kalman/filter/shared/dsp"
	"github.com/streaming-live-kalman/filter/shared/node"
	"google.golang.org/protobuf/proto"
)

const maxFrameBytes = 4 << 20

type Server struct {
	rxv1.UnimplementedReceiverServiceServer
	cfg          config.Receiver
	mu           sync.Mutex
	filter       *dsp.Kalman
	active       *rxv1.RxConfig
	pending      *rxv1.RxConfig
	lastSequence uint64
	streamID     uint64
	runID        string
	gaps         uint64
	metrics      chan *controlv1.ReceiverMetrics
}

func New(cfg config.Receiver) *Server {
	return &Server{cfg: cfg, filter: dsp.NewKalman(float64(cfg.KalmanQ), float64(cfg.KalmanR)), active: &rxv1.RxConfig{Version: 1, KalmanQ: cfg.KalmanQ, KalmanR: cfg.KalmanR}, metrics: make(chan *controlv1.ReceiverMetrics, cfg.QueueCapacity)}
}

func (s *Server) Metrics() <-chan *controlv1.ReceiverMetrics { return s.metrics }

func (s *Server) AcceptDecision(d *controlv1.PolicyDecision) {
	if d.ProposedKalmanQ <= 0 || d.ProposedKalmanR <= 0 || math.IsNaN(float64(d.ProposedKalmanR)) {
		slog.Warn("rejected controller decision", "command", d.CommandId)
		return
	}
	s.mu.Lock()
	defer s.mu.Unlock()
	if d.ProposedVersion <= s.active.Version {
		return
	}
	s.pending = &rxv1.RxConfig{CommandId: d.CommandId, Version: d.ProposedVersion, EffectiveSequence: d.EffectiveSequence, KalmanQ: d.ProposedKalmanQ, KalmanR: d.ProposedKalmanR, ResetState: d.ResetState}
	slog.Info("accepted controller decision", "version", d.ProposedVersion, "effective_sequence", d.EffectiveSequence)
}

func (s *Server) ProcessSignal(stream rxv1.ReceiverService_ProcessSignalServer) error {
	frames := make(chan *rxv1.TxFrame, s.cfg.QueueCapacity)
	errs := make(chan error, 1)
	go func() {
		defer close(frames)
		for {
			f, err := stream.Recv()
			if err != nil {
				errs <- err
				return
			}
			select {
			case frames <- f:
			case <-stream.Context().Done():
				errs <- stream.Context().Err()
				return
			}
		}
	}()
	for f := range frames {
		feedback, metrics, err := s.process(f, uint32(len(frames)))
		if err != nil {
			return err
		}
		if err := stream.Send(feedback); err != nil {
			return err
		}
		s.publish(metrics)
	}
	err := <-errs
	if err == io.EOF {
		return nil
	}
	return err
}

func (s *Server) process(f *rxv1.TxFrame, queueDepth uint32) (*rxv1.RxFeedback, *controlv1.ReceiverMetrics, error) {
	if f.RunId == "" || f.SamplesPerSymbol == 0 || (len(f.Samples) == 0 && len(f.PackedSamples) == 0) {
		return nil, nil, fmt.Errorf("invalid frame identity or samples")
	}
	if len(f.Samples) > 262144 {
		return nil, nil, fmt.Errorf("frame exceeds sample limit")
	}
	s.mu.Lock()
	defer s.mu.Unlock()
	if s.streamID != 0 && (f.StreamId != s.streamID || f.Sequence != s.lastSequence+1) {
		s.gaps++
		s.filter.Reset()
	}
	s.streamID = f.StreamId
	s.runID = f.RunId
	if s.pending != nil && f.Sequence >= s.pending.EffectiveSequence {
		s.active = s.pending
		s.pending = nil
		s.filter.Configure(float64(s.active.KalmanQ), float64(s.active.KalmanR), s.active.ResetState)
		slog.Info("applied receiver config", "version", s.active.Version, "sequence", f.Sequence)
	}
	started := time.Now()
	m := dsp.ProcessBPSK(s.filter, f.Samples, int(f.SamplesPerSymbol), f.ReferenceBits)
	latency := float64(time.Now().UnixMicro()-int64(f.CaptureTimestampUs)) / 1000.0
	if latency < 0 || latency > 60000 {
		latency = float64(time.Since(started).Microseconds()) / 1000
	}
	s.lastSequence = f.Sequence
	feedback := &rxv1.RxFeedback{Sequence: f.Sequence, SnrDb: float32(m.SNRDB), NoiseVariance: float32(m.NoiseVariance), ComparedBits: m.Compared, BitErrors: m.Errors, Ber: float32(m.BER), LatencyMs: latency, ActiveConfigVersion: s.active.Version, QueueDepth: queueDepth}
	metrics := &controlv1.ReceiverMetrics{RunId: f.RunId, Sequence: f.Sequence, SnrDb: feedback.SnrDb, NoiseVariance: feedback.NoiseVariance, ComparedBits: m.Compared, BitErrors: m.Errors, Ber: feedback.Ber, LatencyMs: latency, ActiveConfigVersion: s.active.Version, QueueDepth: queueDepth, ObservedAtUnixMs: uint64(time.Now().UnixMilli())}
	return feedback, metrics, nil
}

func (s *Server) publish(m *controlv1.ReceiverMetrics) {
	select {
	case s.metrics <- m:
	default:
		slog.Warn("controller metrics queue full", "sequence", m.Sequence)
	}
}

func (s *Server) ApplyReceiverConfig(_ context.Context, c *rxv1.RxConfig) (*rxv1.ApplyRxReply, error) {
	if c.KalmanQ <= 0 || c.KalmanR <= 0 {
		return &rxv1.ApplyRxReply{Reason: "Q and R must be positive"}, nil
	}
	s.mu.Lock()
	defer s.mu.Unlock()
	if c.Version <= s.active.Version {
		return &rxv1.ApplyRxReply{Reason: "version is not newer", AppliedVersion: s.active.Version}, nil
	}
	s.pending = c
	return &rxv1.ApplyRxReply{Accepted: true, Reason: "prepared for sequence boundary", AppliedVersion: s.active.Version}, nil
}

func (s *Server) GetRxStatus(_ context.Context, _ *commonv1.Empty) (*rxv1.RxStatus, error) {
	return s.Status(), nil
}

func (s *Server) HTTPHandler() http.Handler {
	mux := http.NewServeMux()
	mux.HandleFunc("/healthz", func(w http.ResponseWriter, _ *http.Request) { _, _ = w.Write([]byte(`{"status":"ok"}`)) })
	mux.HandleFunc("/api/v1/frames", s.ingestProtobuf)
	return mux
}

func (s *Server) ingestProtobuf(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		w.WriteHeader(http.StatusMethodNotAllowed)
		return
	}
	body, err := io.ReadAll(http.MaxBytesReader(w, r.Body, maxFrameBytes))
	if err != nil {
		http.Error(w, err.Error(), http.StatusRequestEntityTooLarge)
		return
	}
	f := new(rxv1.TxFrame)
	if err := proto.Unmarshal(body, f); err != nil {
		http.Error(w, "invalid protobuf: "+err.Error(), 400)
		return
	}
	feedback, metrics, err := s.process(f, 0)
	if err != nil {
		http.Error(w, err.Error(), 400)
		return
	}
	s.publish(metrics)
	out, _ := proto.Marshal(feedback)
	w.Header().Set("Content-Type", "application/x-protobuf")
	_, _ = w.Write(out)
}

func (s *Server) Status() *rxv1.RxStatus {
	s.mu.Lock()
	defer s.mu.Unlock()
	return &rxv1.RxStatus{ActiveVersion: s.active.Version, StreamActive: s.streamID != 0, LastSequence: s.lastSequence, SequenceGaps: s.gaps}
}

func (s *Server) NodeSnapshot() node.Snapshot {
	s.mu.Lock()
	defer s.mu.Unlock()
	return node.Snapshot{Health: commonv1.HealthState_HEALTH_STATE_READY, Active: s.streamID != 0, PeerConnected: s.streamID != 0, RunID: s.runID, ActiveConfigVersion: s.active.Version, LastSequence: s.lastSequence, Message: "receiver DSP ready"}
}
