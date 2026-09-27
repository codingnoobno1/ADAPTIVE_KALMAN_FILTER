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
	ReceivedPower, SNRDB, NoiseVariance, BER float64
	// FrameMean is the raw sample mean. BPSK symbols are balanced, so it is a
	// policy-independent view of the DC offset for drift-aware adaptation.
	FrameMean float64
	// DCEstimate is the Kalman filter's tracked DC offset after this frame.
	DCEstimate       float64
	Compared, Errors uint64
	// Decoded contains hard-decision bits packed least-significant bit first.
	Decoded []byte
}

// DCBlockSymbols is how many symbols each DC measurement averages.
const DCBlockSymbols = 8

// ProcessBPSK demodulates one frame with a decision-free Kalman DC tracker.
//
// The Kalman state is the channel's slowly drifting DC offset, not the symbol
// value. BPSK symbols are zero-mean, so the mean of every block of
// DCBlockSymbols symbols is an unbiased measurement of the offset that does not
// depend on any decision; the filter smooths these block means. Each symbol is
// decided by integrate-and-dump (the matched filter for BPSK in white noise)
// after subtracting the estimate from the previous blocks.
//
// Only Q/R matters: a larger ratio follows fast drift but passes more symbol
// and noise jitter into the estimate; a smaller one averages longer. With
// Q -> 0 it becomes a running mean (from P = 1), the best estimate of a
// constant offset. Because no decision feeds back into the estimate, the loop
// cannot run away at low SNR, which a decision-directed tracker does.
//
// (The first design smoothed the samples themselves before integration. That
// spreads each symbol into the next and never reduced BER; see docs/ml-policy.md.)
//
// Signal-quality estimates (SNR, noise variance, frame mean) are computed from
// the raw samples, independent of the filter and the reference bits, so they
// are stable features for the Controller. Reference bits are optional and
// used only for simulation BER scoring.
func ProcessBPSK(k *Kalman, samples []float32, samplesPerSymbol int, reference []byte) FrameMetrics {
	if samplesPerSymbol <= 0 {
		return FrameMetrics{}
	}
	var amplitudeSum, receivedPower, sampleSum float64
	for _, raw := range samples {
		z := float64(raw)
		amplitudeSum += math.Abs(z)
		receivedPower += z * z
		sampleSum += z
	}
	if len(samples) == 0 {
		return FrameMetrics{}
	}
	amplitude := amplitudeSum / float64(len(samples))
	if !k.Ready {
		k.X, k.Ready = 0, true // no DC offset assumed until measured
	}
	var blockSum float64
	var blockSamples int
	var noisePower float64
	var compared, errors uint64
	decoded := make([]byte, (len(samples)/samplesPerSymbol+7)/8)
	for symbol, start := 0, 0; start+samplesPerSymbol <= len(samples); symbol, start = symbol+1, start+samplesPerSymbol {
		var sum float64
		dc := k.X
		for _, raw := range samples[start : start+samplesPerSymbol] {
			z := float64(raw)
			sum += z - dc
			decision := -amplitude
			if z >= 0 {
				decision = amplitude
			}
			d := z - decision
			noisePower += d * d
		}
		got := sum >= 0
		for _, raw := range samples[start : start+samplesPerSymbol] {
			blockSum += float64(raw)
		}
		blockSamples += samplesPerSymbol
		if (symbol+1)%DCBlockSymbols == 0 {
			k.Update(blockSum / float64(blockSamples))
			blockSum, blockSamples = 0, 0
		}
		if got {
			decoded[symbol/8] |= 1 << uint(symbol%8)
		}
		if symbol/8 < len(reference) {
			compared++
			if got != bitAt(reference, symbol) {
				errors++
			}
		}
	}
	symbols := len(samples) / samplesPerSymbol
	if symbols == 0 {
		return FrameMetrics{}
	}
	n := float64(symbols * samplesPerSymbol)
	noisePower /= n
	snr := 100.0
	if noisePower > 0 {
		snr = 10 * math.Log10((amplitude*amplitude)/noisePower)
	}
	ber := 0.0
	if compared > 0 {
		ber = float64(errors) / float64(compared)
	}
	return FrameMetrics{ReceivedPower: receivedPower / float64(len(samples)), SNRDB: snr, NoiseVariance: noisePower, FrameMean: sampleSum / float64(len(samples)), DCEstimate: k.X, BER: ber, Compared: compared, Errors: errors, Decoded: decoded}
}

func bitAt(packed []byte, index int) bool {
	b := index / 8
	if b >= len(packed) {
		return false
	}
	return packed[b]&(1<<uint(index%8)) != 0
}
