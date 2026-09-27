package dsp

import (
	"bytes"
	"math/bits"
	"testing"
)

func TestScrambleIsSelfInverseAndSequenceKeyed(t *testing.T) {
	orig := []byte("AAAAAAAA")
	a := append([]byte(nil), orig...)
	Scramble(a, 42)
	if bytes.Equal(a, orig) {
		t.Fatal("scrambling changed nothing")
	}
	b := append([]byte(nil), orig...)
	Scramble(b, 43)
	if bytes.Equal(a, b) {
		t.Fatal("different sequences produced the same keystream")
	}
	Scramble(a, 42)
	if !bytes.Equal(a, orig) {
		t.Fatalf("descrambled %q, want %q", a, orig)
	}
}

// A constant payload (worst case: all-zero bits) must come out balanced.
func TestScrambleBalancesConstantPayload(t *testing.T) {
	var ones, total int
	for seq := uint64(1); seq <= 500; seq++ {
		buf := make([]byte, 8)
		Scramble(buf, seq)
		for _, v := range buf {
			ones += bits.OnesCount8(v)
		}
		total += 64
	}
	if frac := float64(ones) / float64(total); frac < 0.48 || frac > 0.52 {
		t.Fatalf("fraction of ones %.3f, want ~0.5", frac)
	}
}

// Pins the keystream so ports (ESP32, Dart) can check against it.
func TestScrambleKnownVector(t *testing.T) {
	buf := make([]byte, 4)
	Scramble(buf, 1)
	want := []byte{0x19, 0x3e, 0x3a, 0xb5}
	if !bytes.Equal(buf, want) {
		t.Fatalf("keystream for sequence 1 = % x", buf)
	}
}
