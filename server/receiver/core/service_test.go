package core

import (
	"encoding/binary"
	"fmt"
	"github.com/streaming-live-kalman/filter/shared/dsp"
	"hash/crc32"
	"math"
	"math/rand"
	"strings"
	"testing"

	commonv1 "github.com/streaming-live-kalman/filter/gen/common/v1"
	controlv1 "github.com/streaming-live-kalman/filter/gen/control/v1"
	rxv1 "github.com/streaming-live-kalman/filter/gen/rx/v1"
	"github.com/streaming-live-kalman/filter/shared/config"
)

func validFrame() *rxv1.TxFrame {
	return &rxv1.TxFrame{
		RunId: "test-run", StreamId: 1, Sequence: 1, SampleRateHz: 48000,
		SamplesPerSymbol: 2, CaptureTimestampUs: 1, SampleFormat: commonv1.SampleFormat_SAMPLE_FORMAT_FLOAT32_LE,
		Samples: []float32{-1, -1, 1, 1}, ReferenceBits: []byte{0b00000010},
	}
}

func TestValidateFrameAcceptsValidBPSKFrame(t *testing.T) {
	if err := validateFrame(validFrame()); err != nil {
		t.Fatalf("valid frame rejected: %v", err)
	}
}

func TestValidateFrameRejectsMalformedInputs(t *testing.T) {
	tests := []struct {
		name string
		edit func(*rxv1.TxFrame)
		want string
	}{
		{"nil", func(_ *rxv1.TxFrame) {}, "frame is required"},
		{"missing identity", func(f *rxv1.TxFrame) { f.StreamId = 0 }, "stream_id"},
		{"missing metadata", func(f *rxv1.TxFrame) { f.CaptureTimestampUs = 0 }, "capture_timestamp_us"},
		{"unsupported sample format", func(f *rxv1.TxFrame) { f.SampleFormat = commonv1.SampleFormat_SAMPLE_FORMAT_INT16_LE }, "sample_format"},
		{"misaligned samples", func(f *rxv1.TxFrame) { f.Samples = append(f.Samples, 1) }, "exact multiple"},
		{"non finite sample", func(f *rxv1.TxFrame) { f.Samples[0] = float32(math.NaN()) }, "finite"},
		{"reference length mismatch", func(f *rxv1.TxFrame) { f.ReferenceBits = []byte{1, 2} }, "reference_bits length"},
		{"mixed sample representations", func(f *rxv1.TxFrame) { f.PackedSamples = []byte{1} }, "packed_samples"},
		{"unsupported media modulation", func(f *rxv1.TxFrame) { f.Media = &commonv1.MediaDescriptor{Modulation: commonv1.Modulation(99)} }, "unsupported media modulation"},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if tt.name == "nil" {
				if err := validateFrame(nil); err == nil || !strings.Contains(err.Error(), tt.want) {
					t.Fatalf("error=%v; want %q", err, tt.want)
				}
				return
			}
			f := validFrame()
			tt.edit(f)
			if err := validateFrame(f); err == nil || !strings.Contains(err.Error(), tt.want) {
				t.Fatalf("error=%v; want %q", err, tt.want)
			}
		})
	}
}

func TestValidateFrameAcceptsPackedInt16Samples(t *testing.T) {
	f := validFrame()
	f.Samples = nil
	f.SampleFormat = commonv1.SampleFormat_SAMPLE_FORMAT_INT16_LE
	f.PackedSamples = make([]byte, 8)
	values := []int16{-32768, -32768, 32767, 32767}
	for i, value := range values {
		binary.LittleEndian.PutUint16(f.PackedSamples[i*2:], uint16(value))
	}
	if err := validateFrame(f); err != nil {
		t.Fatalf("packed int16 frame rejected: %v", err)
	}
}

func TestProcessRejectsMalformedFrameWithoutPanic(t *testing.T) {
	s := New(config.Receiver{QueueCapacity: 1, KalmanQ: .2, KalmanR: .5})
	f := validFrame()
	f.Samples[0] = float32(math.Inf(1))
	if _, _, err := s.process(f, 0); err == nil {
		t.Fatal("malformed frame was accepted")
	}
}

func TestReceiverRejectsInvalidKalmanCovariances(t *testing.T) {
	s := New(config.Receiver{QueueCapacity: 1, KalmanQ: .2, KalmanR: .5})
	for _, cfg := range []*rxv1.RxConfig{
		{Version: 2, KalmanQ: 0, KalmanR: .5},
		{Version: 2, KalmanQ: .2, KalmanR: float32(math.Inf(1))},
	} {
		reply, err := s.ApplyReceiverConfig(nil, cfg)
		if err != nil || reply.Accepted {
			t.Fatalf("invalid config accepted: reply=%+v err=%v", reply, err)
		}
	}
	s.AcceptDecision(&controlv1.PolicyDecision{ProposedVersion: 2, ProposedKalmanQ: float32(math.NaN()), ProposedKalmanR: .5})
	if s.pending != nil {
		t.Fatal("invalid controller decision was queued")
	}
}

// A scrambled, noisy transfer that ends with a checksum mismatch must be
// descrambled, reported to media clients, and must not fail the frame (which
// would tear down the whole signal stream).
func TestScrambledMediaIsDescrambledAndCRCMismatchIsNotFatal(t *testing.T) {
	svc := New(config.Receiver{QueueCapacity: 4, KalmanQ: .0134, KalmanR: .5})
	_, events := svc.media.subscribe(nil)
	payload := []byte("scrambled")[:8]
	send := func(seq uint64, crc uint32) *commonv1.MediaEvent {
		onAir := append([]byte(nil), payload...)
		dsp.Scramble(onAir, seq)
		var ch dsp.Channel
		samples, ref := ch.FrameWithPayload(rand.New(rand.NewSource(1)), onAir, 64, 8, 1, 0)
		f := &rxv1.TxFrame{RunId: "s", StreamId: 1, Sequence: seq, SampleRateHz: 48000, SamplesPerSymbol: 8, CaptureTimestampUs: 1,
			SampleFormat: commonv1.SampleFormat_SAMPLE_FORMAT_FLOAT32_LE, Samples: samples, ReferenceBits: ref, Scrambled: true,
			Media:    &commonv1.MediaDescriptor{TransferId: fmt.Sprint("t", seq), FileName: "a.txt", TotalSize: 8, Crc32: crc, Modulation: commonv1.Modulation_MODULATION_BPSK},
			MediaEnd: true, PayloadByteCount: 8}
		if _, _, err := svc.process(f, 0); err != nil {
			t.Fatalf("frame %d failed: %v", seq, err)
		}
		return <-events
	}
	if e := send(1, crc32.ChecksumIEEE(payload)); string(e.Data) != string(payload) || e.Message != "complete" {
		t.Fatalf("descrambled %q (%s), want %q complete", e.Data, e.Message, payload)
	}
	if e := send(2, 12345); e.Message != "checksum mismatch" || e.ChecksumValid {
		t.Fatalf("bad CRC reported as %q valid=%v", e.Message, e.ChecksumValid)
	}
}
