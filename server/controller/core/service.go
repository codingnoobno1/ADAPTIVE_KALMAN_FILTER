package core

import (
	"context"
	"encoding/json"
	"fmt"
	"log/slog"
	"math"
	"net/http"
	"sync"
	"sync/atomic"
	"time"

	commonv1 "github.com/streaming-live-kalman/filter/gen/common/v1"
	controlv1 "github.com/streaming-live-kalman/filter/gen/control/v1"
	"github.com/streaming-live-kalman/filter/shared/config"
	"github.com/streaming-live-kalman/filter/shared/node"
)

type Server struct {
	controlv1.UnimplementedControllerServiceServer
	cfg          config.Controller
	mu           sync.RWMutex
	latest       map[string]*controlv1.ReceiverMetrics
	subs         map[uint64]chan *controlv1.ExperimentEvent
	nextSub      atomic.Uint64
	nextCommand  atomic.Uint64
	lastDecision map[string]uint64
}

func (s *Server) NodeSnapshot() node.Snapshot {
	s.mu.RLock()
	defer s.mu.RUnlock()
	var latest *controlv1.ReceiverMetrics
	for _, candidate := range s.latest {
		if latest == nil || candidate.ObservedAtUnixMs > latest.ObservedAtUnixMs {
			latest = candidate
		}
	}
	if latest == nil {
		return node.Snapshot{Health: commonv1.HealthState_HEALTH_STATE_READY, Message: "controller ready; awaiting metrics"}
	}
	return node.Snapshot{Health: commonv1.HealthState_HEALTH_STATE_READY, Active: true, PeerConnected: true, RunID: latest.RunId, ActiveConfigVersion: latest.ActiveConfigVersion, LastSequence: latest.Sequence, Message: "controller receiving metrics"}
}

func New(cfg config.Controller) *Server {
	return &Server{cfg: cfg, latest: map[string]*controlv1.ReceiverMetrics{}, subs: map[uint64]chan *controlv1.ExperimentEvent{}, lastDecision: map[string]uint64{}}
}

func (s *Server) Adapt(stream controlv1.ControllerService_AdaptServer) error {
	for {
		m, err := stream.Recv()
		if err != nil {
			return err
		}
		if m.RunId == "" {
			continue
		}
		s.mu.Lock()
		s.latest[m.RunId] = m
		last := s.lastDecision[m.RunId]
		s.mu.Unlock()
		s.publish(&controlv1.ExperimentEvent{RunId: m.RunId, Sequence: m.Sequence, Kind: "metrics", Description: "receiver metrics", Metrics: m, EmittedAtUnixMs: uint64(time.Now().UnixMilli())})
		if m.Sequence < last+s.cfg.DecisionCooldownFrames || m.Sequence == 0 {
			continue
		}
		targetR := float32(math.Max(float64(s.cfg.MinKalmanR), math.Min(float64(s.cfg.MaxKalmanR), float64(m.NoiseVariance))))
		version := m.ActiveConfigVersion + 1
		decision := &controlv1.PolicyDecision{CommandId: s.nextCommand.Add(1), ProposedVersion: version, EffectiveSequence: m.Sequence + 4, ProposedKalmanQ: 0.20, ProposedKalmanR: targetR, Reason: fmt.Sprintf("innovation/noise estimate %.4f", m.NoiseVariance)}
		if err := stream.Send(decision); err != nil {
			return err
		}
		s.mu.Lock()
		s.lastDecision[m.RunId] = m.Sequence
		s.mu.Unlock()
		s.publish(&controlv1.ExperimentEvent{RunId: m.RunId, Sequence: m.Sequence, Kind: "decision", Description: decision.Reason, Decision: decision, EmittedAtUnixMs: uint64(time.Now().UnixMilli())})
	}
}

func (s *Server) WatchExperiment(req *controlv1.WatchRequest, stream controlv1.ControllerService_WatchExperimentServer) error {
	id, ch := s.subscribe()
	defer s.unsubscribe(id)
	for {
		select {
		case <-stream.Context().Done():
			return stream.Context().Err()
		case e := <-ch:
			if req.RunId == "" || req.RunId == e.RunId {
				if err := stream.Send(e); err != nil {
					return err
				}
			}
		}
	}
}

func (s *Server) GetExperimentState(_ context.Context, req *controlv1.ExperimentStateRequest) (*controlv1.ExperimentState, error) {
	s.mu.RLock()
	latest := s.latest[req.RunId]
	s.mu.RUnlock()
	if latest == nil {
		return &controlv1.ExperimentState{RunId: req.RunId}, nil
	}
	return &controlv1.ExperimentState{RunId: req.RunId, Active: true, Latest: latest, DesiredConfigVersion: latest.ActiveConfigVersion}, nil
}

func (s *Server) HTTPHandler() http.Handler {
	mux := http.NewServeMux()
	mux.HandleFunc("/healthz", func(w http.ResponseWriter, _ *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		_, _ = w.Write([]byte(`{"status":"ok"}`))
	})
	mux.HandleFunc("/api/v1/state", func(w http.ResponseWriter, r *http.Request) {
		s.mu.RLock()
		defer s.mu.RUnlock()
		w.Header().Set("Content-Type", "application/json")
		_ = json.NewEncoder(w).Encode(s.latest)
	})
	mux.HandleFunc("/api/v1/events", s.sse)
	return cors(mux)
}

func (s *Server) sse(w http.ResponseWriter, r *http.Request) {
	flusher, ok := w.(http.Flusher)
	if !ok {
		http.Error(w, "streaming unsupported", 500)
		return
	}
	w.Header().Set("Content-Type", "text/event-stream")
	w.Header().Set("Cache-Control", "no-cache")
	w.Header().Set("Connection", "keep-alive")
	id, ch := s.subscribe()
	defer s.unsubscribe(id)
	for {
		select {
		case <-r.Context().Done():
			return
		case e := <-ch:
			b, _ := json.Marshal(e)
			_, _ = fmt.Fprintf(w, "data: %s\n\n", b)
			flusher.Flush()
		}
	}
}

func (s *Server) subscribe() (uint64, chan *controlv1.ExperimentEvent) {
	id := s.nextSub.Add(1)
	ch := make(chan *controlv1.ExperimentEvent, 32)
	s.mu.Lock()
	s.subs[id] = ch
	s.mu.Unlock()
	return id, ch
}
func (s *Server) unsubscribe(id uint64) { s.mu.Lock(); delete(s.subs, id); s.mu.Unlock() }
func (s *Server) publish(e *controlv1.ExperimentEvent) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	for id, ch := range s.subs {
		select {
		case ch <- e:
		default:
			slog.Warn("dropping slow dashboard event", "subscriber", id)
		}
	}
}

func cors(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type")
		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusNoContent)
			return
		}
		next.ServeHTTP(w, r)
	})
}
