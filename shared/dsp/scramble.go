package dsp

// Scramble XORs buf in place with a pseudo-random keystream keyed by the frame
// sequence number. Applying it twice restores the original bytes.
//
// Why: file bytes are not random (ASCII has a zero top bit, images repeat
// values), so their bits are unbalanced. The receiver's DC tracker measures
// drift as the mean of blocks of symbols, which is only unbiased when ones and
// zeros are equally likely; unscrambled content leaks into the DC estimate.
// Scrambling makes the transmitted bits balanced, as in 802.11 and DVB.
//
// The keystream restarts every frame, so each frame descrambles on its own and
// a lost frame cannot desynchronise later ones. It is xorshift32 seeded from
// the sequence number, simple to port to C (ESP32) or Dart:
//
//	x = uint32((sequence * 0x9E3779B97F4A7C15) >> 32) | 1
//	for each byte: x ^= x << 13; x ^= x >> 17; x ^= x << 5; byte ^= uint8(x)
//
// This is line coding, not security.
func Scramble(buf []byte, sequence uint64) {
	x := uint32((sequence*0x9E3779B97F4A7C15)>>32) | 1
	for i := range buf {
		x ^= x << 13
		x ^= x >> 17
		x ^= x << 5
		buf[i] ^= byte(x)
	}
}
