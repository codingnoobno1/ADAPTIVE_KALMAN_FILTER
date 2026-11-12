package quality

import (
	"math"
	"os"
	"testing"

	controlv1 "github.com/streaming-live-kalman/filter/gen/control/v1"
)

func metrics(seq uint64, snr, ber float32, compared uint64, gaps uint64) *controlv1.ReceiverMetrics {
	return &controlv1.ReceiverMetrics{Sequence: seq, SnrDb: snr, Ber: ber, ComparedBits: compared, NoiseVariance: 0.1, SequenceGaps: gaps}
}

func TestMeasuredClassRules(t *testing.T) {
	cases := []struct {
		name string
		win  []*controlv1.ReceiverMetrics
		want Class
	}{
		{"good by BER", []*controlv1.ReceiverMetrics{metrics(1, 12, 0, 64, 0), metrics(2, 12, 0.0005, 64, 0)}, Good},
		{"moderate by BER", []*controlv1.ReceiverMetrics{metrics(1, 8, 0.01, 64, 0), metrics(2, 8, 0.01, 64, 0)}, Moderate},
		{"poor by BER", []*controlv1.ReceiverMetrics{metrics(1, 3, 0.1, 64, 0), metrics(2, 3, 0.12, 64, 0)}, Poor},
		{"unstable by SNR swing", []*controlv1.ReceiverMetrics{metrics(1, 2, 0, 64, 0), metrics(2, 14, 0, 64, 0)}, Unstable},
		{"unstable by new gap", []*controlv1.ReceiverMetrics{metrics(1, 12, 0, 64, 3), metrics(2, 12, 0, 64, 4)}, Unstable},
		{"no reference bits: SNR bands", []*controlv1.ReceiverMetrics{metrics(1, 7, 0, 0, 0), metrics(2, 7, 0, 0, 0)}, Moderate},
	}
	for _, c := range cases {
		w, err := Summarise(c.win)
		if err != nil {
			t.Fatalf("%s: %v", c.name, err)
		}
		if got := w.MeasuredClass(); got != c.want {
			t.Errorf("%s: got %s, want %s (window %+v)", c.name, got, c.want, w)
		}
	}
}

func TestSummariseRejectsBadInput(t *testing.T) {
	if _, err := Summarise(nil); err != ErrEmptyWindow {
		t.Fatalf("empty window: got %v", err)
	}
	bad := metrics(1, float32(math.NaN()), 0, 64, 0)
	if _, err := Summarise([]*controlv1.ReceiverMetrics{bad}); err == nil {
		t.Fatal("NaN SNR was accepted")
	}
}

func TestBERIgnoresFramesWithoutReferenceBits(t *testing.T) {
	w, err := Summarise([]*controlv1.ReceiverMetrics{metrics(1, 9, 0.5, 0, 0), metrics(2, 9, 0.02, 64, 0)})
	if err != nil {
		t.Fatal(err)
	}
	if !w.BERAvailable || math.Abs(w.BERMean-0.02) > 1e-9 {
		t.Fatalf("BER mean %v should only use frames with compared bits", w.BERMean)
	}
	if len(w.Features()) != len(FeatureNames) {
		t.Fatalf("feature vector has %d values, names %d", len(w.Features()), len(FeatureNames))
	}
}

func testImage(w, h int) Image {
	im := Image{Width: w, Height: h, RGB: make([]uint8, w*h*3)}
	for i := range im.RGB {
		im.RGB[i] = uint8((i*37 + i/3*11) % 200)
	}
	return im
}

func TestCompareIdenticalAndShifted(t *testing.T) {
	a := testImage(32, 24)
	m, err := Compare(a, a)
	if err != nil {
		t.Fatal(err)
	}
	if m.MSE != 0 || !math.IsInf(m.PSNR, 1) || math.Abs(m.SSIM-1) > 1e-12 {
		t.Fatalf("identical images: %+v", m)
	}
	b := Image{Width: a.Width, Height: a.Height, RGB: append([]uint8(nil), a.RGB...)}
	for i := range b.RGB {
		b.RGB[i] += 10 // every sample off by 10 -> MSE 100
	}
	m, err = Compare(a, b)
	if err != nil {
		t.Fatal(err)
	}
	if math.Abs(m.MSE-100) > 1e-9 || math.Abs(m.PSNR-28.1308036) > 1e-6 {
		t.Fatalf("shifted image: MSE %v PSNR %v", m.MSE, m.PSNR)
	}
	if m.SSIM >= 1 || m.SSIM < 0.9 {
		t.Fatalf("brightness shift should lower SSIM only slightly, got %v", m.SSIM)
	}
}

func TestSSIMMatchesReferenceImplementation(t *testing.T) {
	// Reference value from an independent NumPy implementation of Wang et
	// al. (2004) with the same 11x11, sigma 1.5 Gaussian window (see
	// ml/quality_reference.py), on this deterministic image pair.
	a := testImage(20, 16)
	b := Image{Width: a.Width, Height: a.Height, RGB: make([]uint8, len(a.RGB))}
	for i := range b.RGB {
		b.RGB[i] = uint8((int(a.RGB[i]) + (i*7)%23) % 256)
	}
	got := SSIM(a.Luma(), b.Luma(), a.Width, a.Height)
	const want = 0.9896971288 // printed by: python ml/quality_reference.py
	if math.Abs(got-want) > 1e-6 {
		t.Fatalf("SSIM %.10f, reference %.10f", got, want)
	}
}

func TestCompareBMPUsesOriginalGeometry(t *testing.T) {
	orig, err := os.ReadFile("../../examples/media/kalman.bmp")
	if err != nil {
		t.Skip("example image not available:", err)
	}
	recon := append([]byte(nil), orig...)
	recon[0], recon[18] = 'X', 0xFF // corrupt the header like a bit error would
	recon[len(recon)-1] ^= 0x10     // and one pixel byte
	m, err := CompareBMP(orig, recon)
	if err != nil {
		t.Fatal(err)
	}
	if m.Width != 64 || m.Height != 48 || m.MSE <= 0 || m.SSIM >= 1 || m.PSNR < 40 {
		t.Fatalf("unexpected metrics for a one-byte error: %+v", m)
	}
	if _, err := CompareBMP(orig, recon[:100]); err == nil {
		t.Fatal("a truncated reconstruction must not produce metrics")
	}
}
