// Package quality turns real receiver measurements into channel-quality
// classes and model features, and computes image-quality metrics.
//
// The same functions run in the live Controller and in cmd/qualitygen (the
// training-data generator), so a feature or class can never be computed one
// way for training and another way at run time.
package quality

import (
	"errors"
	"math"

	controlv1 "github.com/streaming-live-kalman/filter/gen/control/v1"
)

// Class is a channel-quality category.
type Class int

const (
	Good Class = iota
	Moderate
	Poor
	Unstable
)

// Classes lists every class in model-output order.
var Classes = []Class{Good, Moderate, Poor, Unstable}

func (c Class) String() string {
	switch c {
	case Good:
		return "good"
	case Moderate:
		return "moderate"
	case Poor:
		return "poor"
	case Unstable:
		return "unstable"
	}
	return "unknown"
}

// Thresholds are the documented rules that define the measured class. They
// are deliberately simple so that every label can be explained in a viva.
const (
	// A window is unstable when its SNR swings by more than this (std, dB) or
	// when the receiver reports a new sequence gap inside the window.
	UnstableSNRStdDB = 3.0
	// BER bands (used when reference bits make BER measurable).
	GoodMaxBER     = 1e-3
	ModerateMaxBER = 2e-2
	// SNR bands (used only when no BER was measured in the window).
	GoodMinSNRDB     = 10.0
	ModerateMinSNRDB = 5.0
	// MaxSNRDB clips the receiver's 100 dB "noiseless" value.
	MaxSNRDB = 60.0
)

// FeatureNames is the model input order. Latency is not a feature: in the
// simulator it carries no channel information, and live it mostly measures
// host load. It is still reported by the monitor.
var FeatureNames = []string{
	"snr_db_mean", "snr_db_std", "snr_db_trend",
	"noise_var_mean", "noise_var_std",
	"ber_mean", "ber_std", "ber_available",
	"frame_mean_std", "frame_mean_step",
}

// ErrEmptyWindow is returned when a window has no usable metrics.
var ErrEmptyWindow = errors.New("quality: empty metrics window")

// Window summarises consecutive ReceiverMetrics.
type Window struct {
	First, Last  uint64
	SNRMean      float64
	SNRStd       float64
	SNRTrend     float64 // mean of second half minus first half (dB)
	NoiseMean    float64
	NoiseStd     float64
	BERMean      float64
	BERStd       float64
	BERAvailable bool
	FrameStd     float64
	FrameStep    float64
	NewGaps      uint64
	LatencyMean  float64
}

// Summarise validates and summarises a metrics window. Frames without
// compared bits do not contribute to BER; NaN or infinite values are rejected.
func Summarise(window []*controlv1.ReceiverMetrics) (Window, error) {
	var snr, nv, fm, ber, lat []float64
	var w Window
	for i, m := range window {
		if m == nil {
			continue
		}
		s, n := float64(m.SnrDb), float64(m.NoiseVariance)
		if !finite(s) || !finite(n) || !finite(float64(m.FrameMean)) {
			return Window{}, errors.New("quality: non-finite metric in window")
		}
		if len(snr) == 0 {
			w.First = m.Sequence
		}
		w.Last = m.Sequence
		snr = append(snr, math.Min(s, MaxSNRDB))
		nv = append(nv, n)
		fm = append(fm, float64(m.FrameMean))
		lat = append(lat, m.LatencyMs)
		if m.ComparedBits > 0 {
			ber = append(ber, float64(m.Ber))
		}
		if i > 0 && window[i-1] != nil && m.SequenceGaps > window[i-1].SequenceGaps {
			w.NewGaps += m.SequenceGaps - window[i-1].SequenceGaps
		}
	}
	if len(snr) == 0 {
		return Window{}, ErrEmptyWindow
	}
	w.SNRMean, w.SNRStd = meanStd(snr)
	half := len(snr) / 2
	if half > 0 {
		a, _ := meanStd(snr[:half])
		b, _ := meanStd(snr[half:])
		w.SNRTrend = b - a
	}
	w.NoiseMean, w.NoiseStd = meanStd(nv)
	if len(ber) > 0 {
		w.BERAvailable = true
		w.BERMean, w.BERStd = meanStd(ber)
	}
	_, w.FrameStd = meanStd(fm)
	for i := 1; i < len(fm); i++ {
		w.FrameStep += math.Abs(fm[i] - fm[i-1])
	}
	if len(fm) > 1 {
		w.FrameStep /= float64(len(fm) - 1)
	}
	w.LatencyMean, _ = meanStd(lat)
	return w, nil
}

// MeasuredClass applies the documented rules to an already measured window.
func (w Window) MeasuredClass() Class {
	if w.SNRStd > UnstableSNRStdDB || w.NewGaps > 0 {
		return Unstable
	}
	if w.BERAvailable {
		switch {
		case w.BERMean <= GoodMaxBER:
			return Good
		case w.BERMean <= ModerateMaxBER:
			return Moderate
		default:
			return Poor
		}
	}
	switch {
	case w.SNRMean >= GoodMinSNRDB:
		return Good
	case w.SNRMean >= ModerateMinSNRDB:
		return Moderate
	default:
		return Poor
	}
}

// Features returns the model input vector in FeatureNames order.
func (w Window) Features() []float32 {
	avail := float32(0)
	if w.BERAvailable {
		avail = 1
	}
	return []float32{
		float32(w.SNRMean), float32(w.SNRStd), float32(w.SNRTrend),
		float32(w.NoiseMean), float32(w.NoiseStd),
		float32(w.BERMean), float32(w.BERStd), avail,
		float32(w.FrameStd), float32(w.FrameStep),
	}
}

func finite(v float64) bool { return !math.IsNaN(v) && !math.IsInf(v, 0) }

func meanStd(v []float64) (float64, float64) {
	if len(v) == 0 {
		return 0, 0
	}
	var sum float64
	for _, x := range v {
		sum += x
	}
	mean := sum / float64(len(v))
	var sq float64
	for _, x := range v {
		sq += (x - mean) * (x - mean)
	}
	return mean, math.Sqrt(sq / float64(len(v)))
}
