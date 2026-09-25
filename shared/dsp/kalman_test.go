package dsp

import "testing"

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
}

func TestResetClearsState(t *testing.T) {
	k := NewKalman(.1, .2)
	k.Update(1)
	k.Reset()
	if k.Ready || k.P != 1 {
		t.Fatalf("reset left state: %+v", k)
	}
}
