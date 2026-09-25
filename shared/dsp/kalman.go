package dsp

import "math"

// Kalman is a scalar random-walk filter. It intentionally retains state across
// frame boundaries; Reset must be called on stream gaps or incompatible config.
type Kalman struct {
	X, P, Q, R float64
	Ready      bool
}

func NewKalman(q, r float64) *Kalman { return &Kalman{P: 1, Q: q, R: r} }

func (k *Kalman) Update(z float64) float64 {
	if !k.Ready {
		k.X, k.Ready = z, true
	}
	k.P += k.Q
	gain := k.P / (k.P + k.R)
	k.X += gain * (z - k.X)
	k.P *= 1 - gain
	return k.X
}

func (k *Kalman) Configure(q, r float64, reset bool) {
	k.Q, k.R = q, r
	if reset {
		k.Reset()
	}
}

func (k *Kalman) Reset() { k.X, k.P, k.Ready = 0, 1, false }

type FrameMetrics struct {
	SNRDB, NoiseVariance, BER float64
	Compared, Errors          uint64
}

// ProcessBPSK filters every sample, integrates each symbol and compares the
// hard decision with packed ground-truth bits. Samples are expected as +/-1.
func ProcessBPSK(k *Kalman, samples []float32, samplesPerSymbol int, reference []byte) FrameMetrics {
	if samplesPerSymbol <= 0 {
		return FrameMetrics{}
	}
	var noisePower, signalPower float64
	var compared, errors uint64
	for symbol, start := 0, 0; start+samplesPerSymbol <= len(samples); symbol, start = symbol+1, start+samplesPerSymbol {
		want := bitAt(reference, symbol)
		ideal := -1.0
		if want {
			ideal = 1
		}
		var sum float64
		for _, raw := range samples[start : start+samplesPerSymbol] {
			z := float64(raw)
			sum += k.Update(z)
			d := z - ideal
			noisePower += d * d
			signalPower += ideal * ideal
		}
		got := sum >= 0
		compared++
		if got != want {
			errors++
		}
	}
	if compared == 0 {
		return FrameMetrics{}
	}
	n := float64(compared * uint64(samplesPerSymbol))
	noisePower /= n
	signalPower /= n
	snr := 100.0
	if noisePower > 0 {
		snr = 10 * math.Log10(signalPower/noisePower)
	}
	return FrameMetrics{SNRDB: snr, NoiseVariance: noisePower, BER: float64(errors) / float64(compared), Compared: compared, Errors: errors}
}

func bitAt(packed []byte, index int) bool {
	b := index / 8
	if b >= len(packed) {
		return false
	}
	return packed[b]&(1<<uint(index%8)) != 0
}
