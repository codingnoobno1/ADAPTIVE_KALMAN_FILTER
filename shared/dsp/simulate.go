package dsp

import (
	"math"
	"math/rand"
)

// Channel models slow, stateful impairments on top of white Gaussian noise.
// State (fading phase, DC offset) carries across frames like a real link, so
// one Channel must be used per stream. The zero value is an ideal AWGN channel
// and draws no extra random numbers, keeping existing seeds reproducible.
type Channel struct {
	// FadingDepth in [0,1) is the fraction of amplitude lost at a fade's deepest
	// point; FadingPeriodSamples is the length of one fade cycle.
	FadingDepth         float64
	FadingPeriodSamples float64
	// DriftStddev is the per-sample step of a mean-reverting (Ornstein-Uhlenbeck)
	// DC offset; DriftReversion in (0,1] pulls it back toward zero each sample.
	DriftStddev    float64
	DriftReversion float64
	// Each frame is a noise burst with BurstProbability, multiplying the noise
	// standard deviation by BurstNoiseMultiplier for that frame.
	BurstProbability     float64
	BurstNoiseMultiplier float64

	phase, dc   float64
	initialised bool
}

// Frame generates one frame of random BPSK symbols through the channel.
// Reference bits are packed least-significant bit first.
func (c *Channel) Frame(rng *rand.Rand, symbols, samplesPerSymbol int, amplitude float32, noiseStddev float64) ([]float32, []byte) {
	return c.FrameWithPayload(rng, nil, symbols, samplesPerSymbol, amplitude, noiseStddev)
}

// FrameWithPayload modulates payload bytes (least-significant bit first, the
// same packing as FrameMetrics.Decoded) into the first 8*len(payload) symbols
// and fills any remaining symbols with random bits. The returned reference
// bits are exactly the transmitted bits, so BER remains measurable.
func (c *Channel) FrameWithPayload(rng *rand.Rand, payload []byte, symbols, samplesPerSymbol int, amplitude float32, noiseStddev float64) ([]float32, []byte) {
	if c.FadingDepth > 0 && !c.initialised {
		c.phase = rng.Float64() * 2 * math.Pi
	}
	c.initialised = true
	if c.BurstProbability > 0 && rng.Float64() < c.BurstProbability {
		noiseStddev *= c.BurstNoiseMultiplier
	}
	step := 0.0
	if c.FadingDepth > 0 && c.FadingPeriodSamples > 0 {
		step = 2 * math.Pi / c.FadingPeriodSamples
	}
	bits := make([]byte, (symbols+7)/8)
	samples := make([]float32, 0, symbols*samplesPerSymbol)
	for i := 0; i < symbols; i++ {
		var one bool
		if i < 8*len(payload) {
			one = payload[i/8]&(1<<uint(i%8)) != 0
		} else {
			one = rng.Intn(2) == 1
		}
		if one {
			bits[i/8] |= 1 << uint(i%8)
		}
		ideal := -amplitude
		if one {
			ideal = amplitude
		}
		for j := 0; j < samplesPerSymbol; j++ {
			signal := ideal
			if c.FadingDepth > 0 {
				gain := 1 - c.FadingDepth*(1+math.Sin(c.phase))/2
				c.phase += step
				signal = float32(float64(ideal) * gain)
			}
			if c.DriftStddev > 0 {
				c.dc = c.dc*(1-c.DriftReversion) + rng.NormFloat64()*c.DriftStddev
				signal += float32(c.dc)
			}
			samples = append(samples, signal+float32(rng.NormFloat64()*noiseStddev))
		}
	}
	return samples, bits
}

// SimulateBPSK generates random BPSK symbols in additive white Gaussian noise
// (an ideal Channel). It is shared by the Sender and cmd/datagen so training
// data matches the live stream.
func SimulateBPSK(rng *rand.Rand, symbols, samplesPerSymbol int, amplitude float32, noiseStddev float64) ([]float32, []byte) {
	var ideal Channel
	return ideal.Frame(rng, symbols, samplesPerSymbol, amplitude, noiseStddev)
}

// DC returns the channel's current true DC offset (for evaluation only; a real
// receiver cannot observe it).
func (c *Channel) DC() float64 { return c.dc }
