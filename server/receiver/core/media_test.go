package core

import (
	"bytes"
	"hash/crc32"
	"testing"
	"time"

	commonv1 "github.com/streaming-live-kalman/filter/gen/common/v1"
	rxv1 "github.com/streaming-live-kalman/filter/gen/rx/v1"
	"github.com/streaming-live-kalman/filter/shared/config"
)

func TestDetectMedia(t *testing.T) {
	tests := []struct {
		name string
		data []byte
		kind commonv1.MediaType
		mime string
	}{
		{"text", []byte("Kalman receiver online\n"), commonv1.MediaType_MEDIA_TYPE_TEXT, "text/plain; charset=utf-8"},
		{"json", []byte(`{"snr":12.4}`), commonv1.MediaType_MEDIA_TYPE_TEXT, "application/json"},
		{"png", append([]byte("\x89PNG\r\n\x1a\n"), make([]byte, 16)...), commonv1.MediaType_MEDIA_TYPE_IMAGE, "image/png"},
		{"jpeg", []byte{0xff, 0xd8, 0xff, 0xe0}, commonv1.MediaType_MEDIA_TYPE_IMAGE, "image/jpeg"},
		{"wav", []byte("RIFF0000WAVEfmt "), commonv1.MediaType_MEDIA_TYPE_AUDIO, "audio/wav"},
		{"flac", []byte("fLaC0000"), commonv1.MediaType_MEDIA_TYPE_AUDIO, "audio/flac"},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			kind, mime := detectMedia(tt.data, nil)
			if kind != tt.kind || mime != tt.mime {
				t.Fatalf("got (%s, %q), want (%s, %q)", kind, mime, tt.kind, tt.mime)
			}
		})
	}
}

func TestReceiverDemodulatesUnshiftsAndPublishesText(t *testing.T) {
	payload := []byte("streamed text from BPSK")
	const key = byte(19)
	encoded := append([]byte(nil), payload...)
	for i := range encoded {
		encoded[i] += key
	}
	samples := bpskSamples(encoded, 8)
	svc := New(config.Receiver{QueueCapacity: 4, KalmanQ: 100, KalmanR: .001})
	_, events := svc.media.subscribe(nil)
	frame := &rxv1.TxFrame{
		RunId: "media-test", StreamId: 1, Sequence: 1,
		SampleRateHz: 48000, SamplesPerSymbol: 8, CaptureTimestampUs: uint64(time.Now().UnixMicro()),
		SampleFormat: commonv1.SampleFormat_SAMPLE_FORMAT_FLOAT32_LE, Samples: samples,
		Media:    &commonv1.MediaDescriptor{TransferId: "text-1", FileName: "message.txt", TotalSize: uint64(len(payload)), Crc32: crc32.ChecksumIEEE(payload), Modulation: commonv1.Modulation_MODULATION_BPSK, Encoding: commonv1.PayloadEncoding_PAYLOAD_ENCODING_BYTE_SHIFT, ShiftKey: uint32(key)},
		MediaEnd: true, PayloadByteCount: uint32(len(payload)),
	}
	if _, _, err := svc.process(frame, 0); err != nil {
		t.Fatal(err)
	}
	select {
	case event := <-events:
		if !bytes.Equal(event.Data, payload) || event.DetectedType != commonv1.MediaType_MEDIA_TYPE_TEXT || !event.ChecksumValid || event.Message != "complete" {
			t.Fatalf("unexpected media event: %+v", event)
		}
	case <-time.After(time.Second):
		t.Fatal("timed out waiting for media event")
	}
}

func TestMediaPipelineStreamsTextImageAndAudio(t *testing.T) {
	tests := []struct {
		name string
		data []byte
		kind commonv1.MediaType
	}{
		{"text", []byte("hello receiver"), commonv1.MediaType_MEDIA_TYPE_TEXT},
		{"image", append([]byte("\x89PNG\r\n\x1a\n"), make([]byte, 16)...), commonv1.MediaType_MEDIA_TYPE_IMAGE},
		{"audio", []byte("RIFF0000WAVEfmt "), commonv1.MediaType_MEDIA_TYPE_AUDIO},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			pipeline := newMediaPipeline()
			_, events := pipeline.subscribe([]commonv1.MediaType{tt.kind})
			descriptor := &commonv1.MediaDescriptor{TransferId: tt.name, TotalSize: uint64(len(tt.data)), Crc32: crc32.ChecksumIEEE(tt.data), Modulation: commonv1.Modulation_MODULATION_BPSK, Encoding: commonv1.PayloadEncoding_PAYLOAD_ENCODING_RAW}
			if err := pipeline.process(descriptor, 0, tt.data, true); err != nil {
				t.Fatal(err)
			}
			select {
			case event := <-events:
				if event.DetectedType != tt.kind || !bytes.Equal(event.Data, tt.data) || !event.ChecksumValid {
					t.Fatalf("unexpected event: %+v", event)
				}
			default:
				t.Fatal("filtered subscriber did not receive matching media")
			}
		})
	}
}

func TestMediaPipelineRejectsMidTransferKeyChange(t *testing.T) {
	pipeline := newMediaPipeline()
	descriptor := &commonv1.MediaDescriptor{TransferId: "key-change", TotalSize: 2, Modulation: commonv1.Modulation_MODULATION_BPSK, Encoding: commonv1.PayloadEncoding_PAYLOAD_ENCODING_BYTE_SHIFT, ShiftKey: 1}
	if err := pipeline.process(descriptor, 0, []byte{'b'}, false); err != nil {
		t.Fatal(err)
	}
	descriptor.ShiftKey = 2
	if err := pipeline.process(descriptor, 1, []byte{'d'}, true); err == nil {
		t.Fatal("mid-transfer key change was accepted")
	}
}

func bpskSamples(data []byte, samplesPerSymbol int) []float32 {
	out := make([]float32, 0, len(data)*8*samplesPerSymbol)
	for _, b := range data {
		for bit := 0; bit < 8; bit++ {
			value := float32(-1)
			if b&(1<<uint(bit)) != 0 {
				value = 1
			}
			for sample := 0; sample < samplesPerSymbol; sample++ {
				out = append(out, value)
			}
		}
	}
	return out
}
