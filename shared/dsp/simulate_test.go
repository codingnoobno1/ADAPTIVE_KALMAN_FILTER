package dsp

import (
	"math"
	"math/rand"
	"testing"
)

// The ideal channel must reproduce the original Sender synthesis exactly, so
// existing seeds and recorded runs are unchanged.
func TestIdealChannelMatchesOriginalSynthesis(t *testing.T) {
	a, ab := SimulateBPSK(rand.New(rand.NewSource(7)), 64, 8, 1, 0.7)
	rng := rand.New(rand.NewSource(7))
	var want []float32
	wantBits := make([]byte, 8)
	for i := 0; i < 64; i++ {
		one := rng.Intn(2) == 1
		ideal := float32(-1)
		if one {
			wantBits[i/8] |= 1 << uint(i%8)
			ideal = 1
		}
		for j := 0; j < 8; j++ {
			want = append(want, ideal+float32(rng.NormFloat64()*0.7))
		}
	}
	for i := range want {
		if a[i] != want[i] {
			t.Fatalf("sample %d = %v, want %v", i, a[i], want[i])
		}
	}
	for i := range wantBits {
		if ab[i] != wantBits[i] {
			t.Fatalf("bits differ at byte %d", i)
		}
	}
}

func TestFadingReducesAmplitudeAndCarriesStateAcrossFrames(t *testing.T) {
	c := &Channel{FadingDepth: 0.9, FadingPeriodSamples: 4096}
	rng := rand.New(rand.NewSource(1))
	minAbs, maxAbs := math.Inf(1), 0.0
	for f := 0; f < 16; f++ {
		samples, _ := c.Frame(rng, 64, 8, 1, 0)
		for _, s := range samples {
			v := math.Abs(float64(s))
			minAbs, maxAbs = math.Min(minAbs, v), math.Max(maxAbs, v)
		}
	}
	if maxAbs > 1.0001 || minAbs > 0.2 {
		t.Fatalf("fading range [%v,%v], want deep fade below 0.2 and no gain above 1", minAbs, maxAbs)
	}
}

func TestDriftAddsBoundedDCOffset(t *testing.T) {
	c := &Channel{DriftStddev: 0.02, DriftReversion: 0.001}
	rng := rand.New(rand.NewSource(3))
	var maxDC float64
	for f := 0; f < 50; f++ {
		c.Frame(rng, 64, 8, 1, 0)
		maxDC = math.Max(maxDC, math.Abs(c.dc))
	}
	if maxDC == 0 || maxDC > 5 {
		t.Fatalf("max |dc| = %v, want non-zero and bounded", maxDC)
	}
}

func TestPayloadRoundTripsThroughDemodulator(t *testing.T) {
	payload := []byte("Kalman!")
	var c Channel
	samples, ref := c.FrameWithPayload(rand.New(rand.NewSource(5)), payload, 64, 8, 1, 0)
	m := ProcessBPSK(NewKalman(0.2, 0.02), samples, 8, ref)
	if m.Errors != 0 {
		t.Fatalf("noiseless payload had %d bit errors", m.Errors)
	}
	if string(m.Decoded[:len(payload)]) != string(payload) || string(ref[:len(payload)]) != string(payload) {
		t.Fatalf("decoded %q ref %q, want %q", m.Decoded[:len(payload)], ref[:len(payload)], payload)
	}
}
