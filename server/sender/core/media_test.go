package core

import (
	"bytes"
	"hash/crc32"
	"strings"
	"testing"

	commonv1 "github.com/streaming-live-kalman/filter/gen/common/v1"
	"github.com/streaming-live-kalman/filter/shared/config"
)

func testServer() *Server {
	return New(config.Sender{RunID: "t", SampleRateHz: 48000, SamplesPerSymbol: 8, SamplesPerFrame: 512, Amplitude: 1})
}

func TestTransferIsChunkedIntoFramesWithContiguousOffsets(t *testing.T) {
	s := testServer()
	data := []byte("hello, adaptive kalman world") // 28 bytes = 3 full frames + 4
	st, err := s.EnqueueTransfer(TransferRequest{FileName: `C:\docs\note.txt`, Data: data})
	if err != nil {
		t.Fatal(err)
	}
	if st.FileName != "note.txt" || st.MediaType != "TEXT" || st.CRC32 != crc32.ChecksumIEEE(data) || st.State != "queued" {
		t.Fatalf("status=%+v", st)
	}
	var got []byte
	for seq := uint64(1); ; seq++ {
		s.mu.Lock()
		payload, media, offset, end := s.nextPayloadLocked(seq)
		s.mu.Unlock()
		if media == nil {
			t.Fatal("transfer stopped before its end flag")
		}
		if offset != uint64(len(got)) || len(payload) > 8 {
			t.Fatalf("frame %d: offset %d after %d bytes, payload %d", seq, offset, len(got), len(payload))
		}
		got = append(got, payload...)
		if end {
			break
		}
	}
	if !bytes.Equal(got, data) {
		t.Fatalf("reassembled %q", got)
	}
	s.mu.Lock()
	_, media, _, _ := s.nextPayloadLocked(99)
	s.mu.Unlock()
	if media != nil {
		t.Fatal("idle link still carried media")
	}
	if _, _, recent := s.Transfers(); len(recent) != 1 || recent[0].State != "sent" || recent[0].SentBytes != len(data) {
		t.Fatalf("recent=%+v", recent)
	}
}

func TestByteShiftIsAppliedBeforeModulationAndCRCCoversOriginal(t *testing.T) {
	s := testServer()
	data := []byte{0, 1, 250}
	if _, err := s.EnqueueTransfer(TransferRequest{FileName: "a.bin", Data: data, Encoding: commonv1.PayloadEncoding_PAYLOAD_ENCODING_BYTE_SHIFT, ShiftKey: 10}); err != nil {
		t.Fatal(err)
	}
	s.mu.Lock()
	payload, media, _, end := s.nextPayloadLocked(1)
	s.mu.Unlock()
	if !bytes.Equal(payload, []byte{10, 11, 4}) || !end {
		t.Fatalf("payload=%v end=%v", payload, end)
	}
	if media.Crc32 != crc32.ChecksumIEEE(data) || media.ShiftKey != 10 || media.Encoding != commonv1.PayloadEncoding_PAYLOAD_ENCODING_BYTE_SHIFT {
		t.Fatalf("descriptor=%v", media)
	}
}

func TestReconnectRestartsPartialTransfer(t *testing.T) {
	s := testServer()
	if _, err := s.EnqueueTransfer(TransferRequest{FileName: "b.bin", Data: make([]byte, 20)}); err != nil {
		t.Fatal(err)
	}
	s.mu.Lock()
	s.nextPayloadLocked(1)
	s.restartActiveLocked()
	_, _, offset, _ := s.nextPayloadLocked(2)
	s.mu.Unlock()
	if offset != 0 {
		t.Fatalf("offset after reconnect = %d, want 0", offset)
	}
}

func TestEnqueueRejectsInvalidFiles(t *testing.T) {
	s := testServer()
	for _, req := range []TransferRequest{
		{FileName: "empty.txt"},
		{FileName: "big.bin", Data: make([]byte, MaxTransferBytes+1)},
		{FileName: "x.bin", Data: []byte{1}, Encoding: commonv1.PayloadEncoding(99)},
	} {
		if _, err := s.EnqueueTransfer(req); err == nil {
			t.Fatalf("accepted %s", req.FileName)
		}
	}
}

func TestClassifyByExtension(t *testing.T) {
	for name, want := range map[string]string{"a.txt": "TEXT", "b.json": "TEXT", "c.bmp": "IMAGE", "d.png": "IMAGE", "e.wav": "AUDIO", "f.dat": "BINARY"} {
		mt, _ := classify(name, "")
		if got := strings.TrimPrefix(mt.String(), "MEDIA_TYPE_"); got != want {
			t.Errorf("%s: %s, want %s", name, got, want)
		}
	}
}

func TestGenericContentTypeFallsBackToExtension(t *testing.T) {
	if mt, ct := classify("tone.wav", "application/x-www-form-urlencoded"); mt != commonv1.MediaType_MEDIA_TYPE_AUDIO || !strings.Contains(ct, "wav") {
		t.Fatalf("got %s %q", mt, ct)
	}
}

func TestLinkThroughput(t *testing.T) {
	if bps := testServer().BytesPerSecond(); bps != 750 {
		t.Fatalf("bytes/s = %v, want 750 (8 bytes/frame at 93.75 frames/s)", bps)
	}
}
