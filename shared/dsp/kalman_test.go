package dsp

import (
	"math"
	"math/rand"
	"testing"
)

func TestProcessBPSKNoiseless(t *testing.T) {
	bits := []byte{0b00001101}
	samples := make([]float32, 0, 32)
	for i := 0; i < 8; i++ {
		v := float32(-1)
		if bits[0]&(1<<i) != 0 {
			v = 1
		}
		for j := 0; j < 4; j++ {
			samples = append(samples, v)
		}
	}
	m := ProcessBPSK(NewKalman(.01, .1), samples, 4, bits)
	if m.Compared != 8 {
		t.Fatalf("compared=%d", m.Compared)
	}
	if m.Errors != 0 {
		t.Fatalf("errors=%d", m.Errors)
	}
	if len(m.Decoded) != 1 || m.Decoded[0] != bits[0] {
		t.Fatalf("decoded=%08b want=%08b", m.Decoded, bits)
	}
}

func TestResetClearsState(t *testing.T) {
	k := NewKalman(.1, .2)
	k.Update(1)
	k.Reset()
	if k.Ready || k.P != 1 {
		t.Fatalf("reset left state: %+v", k)
	}
}

func TestSignalQualityDoesNotUseReferenceBits(t *testing.T) {
	samples := []float32{-1.1, -0.9, 1.1, 0.9, -1.0, -1.2, 1.0, 1.2}
	truth := []byte{0b01000100}
	incorrectTruth := []byte{0b10111011}
	a := ProcessBPSK(NewKalman(.1, .2), samples, 2, truth)
	b := ProcessBPSK(NewKalman(.1, .2), samples, 2, incorrectTruth)
	if a.ReceivedPower != b.ReceivedPower || a.NoiseVariance != b.NoiseVariance || a.SNRDB != b.SNRDB {
		t.Fatalf("signal-quality estimate changed with reference bits: a=%+v b=%+v", a, b)
	}
	if a.BER == b.BER {
		t.Fatal("BER should still use reference bits for simulation scoring")
	}
}

func TestDCTrackerRemovesOffsetThatHurtsPlainDecisions(t *testing.T) {
	// A +0.8 offset with noise pushes many "-1" symbols above zero. The offset
	// is below the symbol amplitude, as with drift that builds up gradually.
	rng := rand.New(rand.NewSource(9))
	var samples []float32
	var ref []byte
	for f := 0; f < 40; f++ {
		s, b := SimulateBPSK(rng, 64, 8, 1, 0.8)
		for i := range s {
			s[i] += 0.8
		}
		samples, ref = append(samples, s...), append(ref, b...)
	}
	var plainErrors int // integrate-and-dump with no DC removal
	for sym := 0; sym*8 < len(samples); sym++ {
		var sum float32
		for _, z := range samples[sym*8 : sym*8+8] {
			sum += z
		}
		if (sum >= 0) != bitAt(ref, sym) {
			plainErrors++
		}
	}
	plainBER := float64(plainErrors) / float64(len(samples)/8)
	tracked := ProcessBPSK(NewKalman(1e-4, 1), samples, 8, ref)
	if plainBER < 0.05 || tracked.BER > plainBER/5 {
		t.Fatalf("plain BER %.4f, tracked BER %.4f; want tracking to cut BER at least 5x", plainBER, tracked.BER)
	}
	if math.Abs(tracked.DCEstimate-0.8) > 0.1 || math.Abs(tracked.FrameMean-0.8) > 0.3 {
		t.Fatalf("dc estimate %.3f, frame mean %.3f, want ~0.8", tracked.DCEstimate, tracked.FrameMean)
	}
}
