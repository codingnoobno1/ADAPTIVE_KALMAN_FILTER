package core

import (
	"context"
	"encoding/binary"
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
	commonv1.UnimplementedMediaStreamServiceServer
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
	media        *mediaPipeline
}

func New(cfg config.Receiver) *Server {
	return &Server{cfg: cfg, filter: dsp.NewKalman(float64(cfg.KalmanQ), float64(cfg.KalmanR)), active: &rxv1.RxConfig{Version: 1, KalmanQ: cfg.KalmanQ, KalmanR: cfg.KalmanR}, metrics: make(chan *controlv1.ReceiverMetrics, cfg.QueueCapacity), media: newMediaPipeline()}
}

func (s *Server) Metrics() <-chan *controlv1.ReceiverMetrics { return s.metrics }

func (s *Server) AcceptDecision(d *controlv1.PolicyDecision) {
	if d == nil {
		slog.Warn("rejected nil controller decision")
		return
	}
	if !validKalmanCovariances(d.ProposedKalmanQ, d.ProposedKalmanR) {
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
	if err := validateFrame(f); err != nil {
		return nil, nil, err
	}
	samples, err := frameSamples(f)
	if err != nil {
		return nil, nil, err
	}
	s.mu.Lock()
	defer s.mu.Unlock()
	if s.streamID != 0 && (f.StreamId != s.streamID || f.Sequence != s.lastSequence+1) {
		s.gaps++
		s.filter.Reset()
		s.media.reset("signal sequence gap")
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
	m := dsp.ProcessBPSK(s.filter, samples, int(f.SamplesPerSymbol), f.ReferenceBits)
	if f.Media != nil {
		count := int(f.PayloadByteCount)
		if count == 0 {
			count = len(m.Decoded)
		}
		if count > len(m.Decoded) {
			return nil, nil, fmt.Errorf("payload_byte_count %d exceeds %d decoded bytes", count, len(m.Decoded))
		}
		// A damaged (CRC mismatch) or out-of-order transfer is already reported
		// to media clients as an event. It must not tear down the signal stream:
		// bit errors are expected at low SNR and are what the demo shows.
		payload := m.Decoded[:count]
		if f.Scrambled {
			payload = append([]byte(nil), payload...)
			dsp.Scramble(payload, f.Sequence)
		}
		if err := s.media.process(f.Media, f.MediaOffset, payload, f.MediaEnd); err != nil {
			slog.Warn("media transfer", "transfer", f.Media.TransferId, "error", err)
		}
	}
	latency := float64(time.Now().UnixMicro()-int64(f.CaptureTimestampUs)) / 1000.0
	if latency < 0 || latency > 60000 {
		latency = float64(time.Since(started).Microseconds()) / 1000
	}
	s.lastSequence = f.Sequence
	feedback := &rxv1.RxFeedback{Sequence: f.Sequence, SnrDb: float32(m.SNRDB), NoiseVariance: float32(m.NoiseVariance), ComparedBits: m.Compared, BitErrors: m.Errors, Ber: float32(m.BER), LatencyMs: latency, ActiveConfigVersion: s.active.Version, QueueDepth: queueDepth}
	metrics := &controlv1.ReceiverMetrics{RunId: f.RunId, Sequence: f.Sequence, SnrDb: feedback.SnrDb, NoiseVariance: feedback.NoiseVariance, ComparedBits: m.Compared, BitErrors: m.Errors, Ber: feedback.Ber, LatencyMs: latency, ActiveConfigVersion: s.active.Version, QueueDepth: queueDepth, ObservedAtUnixMs: uint64(time.Now().UnixMilli()), FrameMean: float32(m.FrameMean), DcEstimate: float32(m.DCEstimate)}
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
	if c == nil || !validKalmanCovariances(c.KalmanQ, c.KalmanR) {
		return &rxv1.ApplyRxReply{Reason: "Q and R must be finite positive values"}, nil
	}
	s.mu.Lock()
	defer s.mu.Unlock()
	if c.Version <= s.active.Version {
		return &rxv1.ApplyRxReply{Reason: "version is not newer", AppliedVersion: s.active.Version}, nil
	}
	s.pending = c
	return &rxv1.ApplyRxReply{Accepted: true, Reason: "prepared for sequence boundary", AppliedVersion: s.active.Version}, nil
}

// validateFrame is deliberately local to the receiver: it validates the
// existing v1 BPSK wire contract without adding a new cross-device protocol.
func validateFrame(f *rxv1.TxFrame) error {
	if f == nil {
		return fmt.Errorf("frame is required")
	}
	if f.RunId == "" || f.StreamId == 0 || f.Sequence == 0 {
		return fmt.Errorf("run_id, stream_id, and sequence are required")
	}
	if f.SampleRateHz == 0 || f.SamplesPerSymbol == 0 || f.CaptureTimestampUs == 0 {
		return fmt.Errorf("sample_rate_hz, samples_per_symbol, and capture_timestamp_us must be non-zero")
	}
	if f.Media != nil && f.Media.Modulation != commonv1.Modulation_MODULATION_UNSPECIFIED && f.Media.Modulation != commonv1.Modulation_MODULATION_BPSK {
		return fmt.Errorf("unsupported media modulation %s", f.Media.Modulation)
	}
	samples, err := frameSamples(f)
	if err != nil {
		return err
	}
	if len(samples) == 0 || len(samples) > 262144 {
		return fmt.Errorf("sample count must be between 1 and 262144")
	}
	if len(samples)%int(f.SamplesPerSymbol) != 0 {
		return fmt.Errorf("sample count must be an exact multiple of samples_per_symbol")
	}
	for _, sample := range samples {
		if math.IsNaN(float64(sample)) || math.IsInf(float64(sample), 0) {
			return fmt.Errorf("samples must be finite")
		}
	}
	symbols := len(samples) / int(f.SamplesPerSymbol)
	expectedReferenceBytes := (symbols + 7) / 8
	if len(f.ReferenceBits) != 0 && len(f.ReferenceBits) != expectedReferenceBytes {
		return fmt.Errorf("reference_bits length %d does not match %d BPSK symbols", len(f.ReferenceBits), symbols)
	}
	if f.Media != nil && int(f.PayloadByteCount) > expectedReferenceBytes {
		return fmt.Errorf("payload_byte_count exceeds decoded frame capacity")
	}
	return nil
}

func frameSamples(f *rxv1.TxFrame) ([]float32, error) {
	if len(f.Samples) > 0 {
		if len(f.PackedSamples) > 0 {
			return nil, fmt.Errorf("use samples or packed_samples, not both")
		}
		if f.SampleFormat != commonv1.SampleFormat_SAMPLE_FORMAT_FLOAT32_LE {
			return nil, fmt.Errorf("sample_format for repeated samples must be SAMPLE_FORMAT_FLOAT32_LE")
		}
		return f.Samples, nil
	}
	switch f.SampleFormat {
	case commonv1.SampleFormat_SAMPLE_FORMAT_FLOAT32_LE:
		if len(f.PackedSamples)%4 != 0 {
			return nil, fmt.Errorf("FLOAT32_LE sample bytes must be divisible by 4")
		}
		out := make([]float32, len(f.PackedSamples)/4)
		for i := range out {
			out[i] = math.Float32frombits(binary.LittleEndian.Uint32(f.PackedSamples[i*4:]))
		}
		return out, nil
	case commonv1.SampleFormat_SAMPLE_FORMAT_INT16_LE:
		if len(f.PackedSamples)%2 != 0 {
			return nil, fmt.Errorf("INT16_LE sample bytes must be divisible by 2")
		}
		out := make([]float32, len(f.PackedSamples)/2)
		for i := range out {
			out[i] = float32(int16(binary.LittleEndian.Uint16(f.PackedSamples[i*2:]))) / 32768
		}
		return out, nil
	default:
		return nil, fmt.Errorf("packed_samples require an explicit sample_format")
	}
}

func validKalmanCovariances(q, r float32) bool {
	return q > 0 && r > 0 && !math.IsNaN(float64(q)) && !math.IsNaN(float64(r)) && !math.IsInf(float64(q), 0) && !math.IsInf(float64(r), 0)
}

func (s *Server) GetRxStatus(_ context.Context, _ *commonv1.Empty) (*rxv1.RxStatus, error) {
	return s.Status(), nil
}

func (s *Server) HTTPHandler() http.Handler {
	mux := http.NewServeMux()
	mux.HandleFunc("/healthz", func(w http.ResponseWriter, _ *http.Request) { _, _ = w.Write([]byte(`{"status":"ok"}`)) })
	mux.HandleFunc("/api/v1/frames", s.ingestProtobuf)
	mux.HandleFunc("/api/v1/media", s.streamMediaHTTP)
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
