// Command mediagen writes small demo payloads for the file-transfer link.
// They are deliberately uncompressed (plain text, PCM WAV, 24-bit BMP): a bit
// error then shows up as a wrong character, a click or a speckled pixel, while
// the same error in PNG/JPEG/MP3 usually makes the whole file undecodable.
// At ~750 B/s the three files take roughly 1 s, 11 s and 12 s to send.
package main

import (
	"bytes"
	"encoding/binary"
	"flag"
	"fmt"
	"log"
	"math"
	"os"
	"path/filepath"
)

func main() {
	dir := flag.String("out", "examples/media", "output directory")
	flag.Parse()
	if err := os.MkdirAll(*dir, 0o755); err != nil {
		log.Fatal(err)
	}
	files := map[string][]byte{
		"hello.txt":  []byte("Adaptive Kalman filtering over a BPSK link.\nIf you can read this, the demodulator recovered every bit.\n"),
		"tone.wav":   wav(8000, 1.0),
		"kalman.bmp": bmp(64, 48),
	}
	for name, data := range files {
		path := filepath.Join(*dir, name)
		if err := os.WriteFile(path, data, 0o644); err != nil {
			log.Fatal(err)
		}
		fmt.Printf("%-12s %6d bytes  ~%4.1f s at 750 B/s\n", name, len(data), float64(len(data))/750)
	}
}

// wav returns 8-bit mono PCM: a 440 Hz tone rising to 880 Hz, easy to hear
// degrade as noise corrupts bits.
func wav(rate int, seconds float64) []byte {
	n := int(float64(rate) * seconds)
	var b bytes.Buffer
	le := func(v any) { _ = binary.Write(&b, binary.LittleEndian, v) }
	b.WriteString("RIFF")
	le(uint32(36 + n))
	b.WriteString("WAVEfmt ")
	le(uint32(16))
	le(uint16(1)) // PCM
	le(uint16(1)) // mono
	le(uint32(rate))
	le(uint32(rate)) // byte rate
	le(uint16(1))    // block align
	le(uint16(8))    // bits per sample
	b.WriteString("data")
	le(uint32(n))
	phase := 0.0
	for i := 0; i < n; i++ {
		freq := 440 + 440*float64(i)/float64(n)
		phase += 2 * math.Pi * freq / float64(rate)
		b.WriteByte(byte(128 + 100*math.Sin(phase)))
	}
	return b.Bytes()
}

// bmp returns a bottom-up 24-bit BMP with a colour gradient and a white
// sine-wave trace, so single-bit errors are visible as off-colour pixels.
func bmp(w, h int) []byte {
	rowSize := (w*3 + 3) &^ 3
	pixels := rowSize * h
	var b bytes.Buffer
	le := func(v any) { _ = binary.Write(&b, binary.LittleEndian, v) }
	b.WriteString("BM")
	le(uint32(54 + pixels))
	le(uint32(0))
	le(uint32(54))
	le(uint32(40)) // BITMAPINFOHEADER
	le(int32(w))
	le(int32(h))
	le(uint16(1))
	le(uint16(24))
	le(uint32(0)) // no compression
	le(uint32(pixels))
	le(int32(2835))
	le(int32(2835))
	le(uint32(0))
	le(uint32(0))
	for y := 0; y < h; y++ {
		row := make([]byte, rowSize)
		for x := 0; x < w; x++ {
			r, g, bl := byte(255*x/(w-1)), byte(255*y/(h-1)), byte(160)
			wave := float64(h)/2 + float64(h)/3*math.Sin(2*math.Pi*float64(x)/float64(w))
			if math.Abs(float64(y)-wave) < 1.5 {
				r, g, bl = 255, 255, 255
			}
			row[x*3], row[x*3+1], row[x*3+2] = bl, g, r // BGR
		}
		b.Write(row)
	}
	return b.Bytes()
}
