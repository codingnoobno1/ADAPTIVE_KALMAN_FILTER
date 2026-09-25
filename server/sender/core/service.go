package core

import (
	"context"
	"fmt"
	"io"
	"log/slog"
	"math/rand"
	"sync"
	"time"

	commonv1 "github.com/streaming-live-kalman/filter/gen/common/v1"
	rxv1 "github.com/streaming-live-kalman/filter/gen/rx/v1"
	txv1 "github.com/streaming-live-kalman/filter/gen/tx/v1"
	"github.com/streaming-live-kalman/filter/shared/config"
	"github.com/streaming-live-kalman/filter/shared/node"
)

type Server struct {
	txv1.UnimplementedTransmitterServiceServer
	mu       sync.RWMutex
	cfg      config.Sender
	active   *txv1.TxConfig
	pending  *txv1.TxConfig
	sequence uint64
	running  bool
	subs     map[uint64]chan *txv1.TxEvent
	nextSub  uint64
}

func (s *Server) NodeSnapshot() node.Snapshot {
	s.mu.RLock()
	defer s.mu.RUnlock()
	return node.Snapshot{Health: commonv1.HealthState_HEALTH_STATE_READY, Active: s.running, PeerConnected: s.running, RunID: s.cfg.RunID, ActiveConfigVersion: s.active.Version, LastSequence: s.sequence, Message: "sender ready"}
}

type frameParameters struct {
	version     uint64
	amplitude   float32
	noiseStddev float32
}

func New(cfg config.Sender) *Server {
	return &Server{cfg: cfg, active: &txv1.TxConfig{Version: 1, SymbolRate: cfg.SampleRateHz / cfg.SamplesPerSymbol, Amplitude: cfg.Amplitude, NoiseStddev: float32(cfg.NoiseStdDev)}, subs: map[uint64]chan *txv1.TxEvent{}}
}

func (s *Server) ApplyTransmitterConfig(_ context.Context, c *txv1.TxConfig) (*txv1.ApplyTxReply, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	if c.Version <= s.active.Version {
		return &txv1.ApplyTxReply{Reason: "version is not newer", AppliedVersion: s.active.Version}, nil
	}
	if c.Amplitude <= 0 || c.SymbolRate == 0 || c.NoiseStddev < 0 {
		return &txv1.ApplyTxReply{Reason: "invalid amplitude, symbol rate, or noise"}, nil
	}
	s.pending = c
	return &txv1.ApplyTxReply{Accepted: true, Reason: "prepared for sequence boundary", AppliedVersion: s.active.Version}, nil
}
func (s *Server) GetTxStatus(_ context.Context, _ *commonv1.Empty) (*txv1.TxStatus, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	return &txv1.TxStatus{ActiveVersion: s.active.Version, Running: s.running, Sequence: s.sequence, RunId: s.cfg.RunID}, nil
}
func (s *Server) WatchTxEvents(_ *commonv1.Empty, stream txv1.TransmitterService_WatchTxEventsServer) error {
	id, ch := s.subscribe()
	defer s.unsubscribe(id)
	for {
		select {
		case <-stream.Context().Done():
			return stream.Context().Err()
		case e := <-ch:
			if err := stream.Send(e); err != nil {
				return err
			}
		}
	}
}

func (s *Server) RunStream(ctx context.Context, client rxv1.ReceiverServiceClient) error {
	stream, err := client.ProcessSignal(ctx)
	if err != nil {
		return err
	}
	feedbackErr := make(chan error, 1)
	go func() {
		for {
			f, err := stream.Recv()
			if err != nil {
				feedbackErr <- err
				return
			}
			if f.Sequence%16 == 0 {
				slog.Info("receiver feedback", "sequence", f.Sequence, "snr_db", fmt.Sprintf("%.2f", f.SnrDb), "ber", fmt.Sprintf("%.4f", f.Ber), "latency_ms", fmt.Sprintf("%.2f", f.LatencyMs), "config", f.ActiveConfigVersion)
			}
		}
	}()
	rng := rand.New(rand.NewSource(s.cfg.Seed))
	ticker := time.NewTicker(time.Duration(float64(time.Second) * float64(s.cfg.SamplesPerFrame) / float64(s.cfg.SampleRateHz)))
	defer ticker.Stop()
	streamID := uint64(time.Now().UnixNano())
	sampleIndex := uint64(0)
	s.mu.Lock()
	s.running = true
	s.mu.Unlock()
	defer func() { s.mu.Lock(); s.running = false; s.mu.Unlock() }()
	for {
		select {
		case <-ctx.Done():
			_ = stream.CloseSend()
			return ctx.Err()
		case err := <-feedbackErr:
			if err == io.EOF {
				return nil
			}
			return err
		case <-ticker.C:
			s.mu.Lock()
			s.sequence++
			seq := s.sequence
			if s.pending != nil && seq >= s.pending.EffectiveSequence {
				s.active = s.pending
				s.pending = nil
				s.publishLocked(&txv1.TxEvent{Sequence: seq, Description: fmt.Sprintf("applied TX config v%d", s.active.Version)})
			}
			active := frameParameters{version: s.active.Version, amplitude: s.active.Amplitude, noiseStddev: s.active.NoiseStddev}
			s.mu.Unlock()
			frame := generateFrame(s.cfg, active, streamID, seq, sampleIndex, rng)
			sampleIndex += uint64(len(frame.Samples))
			if err := stream.Send(frame); err != nil {
				return err
			}
		}
	}
}

func generateFrame(cfg config.Sender, active frameParameters, streamID, seq, first uint64, rng *rand.Rand) *rxv1.TxFrame {
	symbols := cfg.SamplesPerFrame / int(cfg.SamplesPerSymbol)
	bits := make([]byte, (symbols+7)/8)
	samples := make([]float32, 0, symbols*int(cfg.SamplesPerSymbol))
	for i := 0; i < symbols; i++ {
		one := rng.Intn(2) == 1
		if one {
			bits[i/8] |= 1 << uint(i%8)
		}
		ideal := -active.amplitude
		if one {
			ideal = active.amplitude
		}
		for j := uint32(0); j < cfg.SamplesPerSymbol; j++ {
			samples = append(samples, ideal+float32(rng.NormFloat64()*float64(active.noiseStddev)))
		}
	}
	return &rxv1.TxFrame{RunId: cfg.RunID, StreamId: streamID, Sequence: seq, FirstSampleIndex: first, SampleRateHz: cfg.SampleRateHz, SamplesPerSymbol: cfg.SamplesPerSymbol, CaptureTimestampUs: uint64(time.Now().UnixMicro()), ConfigVersion: active.version, Samples: samples, ReferenceBits: bits, SampleFormat: 1}
}

func (s *Server) subscribe() (uint64, chan *txv1.TxEvent) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.nextSub++
	ch := make(chan *txv1.TxEvent, 8)
	s.subs[s.nextSub] = ch
	return s.nextSub, ch
}
func (s *Server) unsubscribe(id uint64) { s.mu.Lock(); defer s.mu.Unlock(); delete(s.subs, id) }
func (s *Server) publishLocked(e *txv1.TxEvent) {
	for _, ch := range s.subs {
		select {
		case ch <- e:
		default:
		}
	}
}
