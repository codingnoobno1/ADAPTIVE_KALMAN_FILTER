package core

import (
	"bytes"
	"encoding/binary"
	"encoding/json"
	"fmt"
	"hash"
	"hash/crc32"
	"net/http"
	"strings"
	"sync"
	"time"
	"unicode/utf8"

	commonv1 "github.com/streaming-live-kalman/filter/gen/common/v1"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"google.golang.org/protobuf/proto"
)

const (
	maxMediaBytes  = 64 << 20
	detectionBytes = 512
)

type mediaTransfer struct {
	descriptor *commonv1.MediaDescriptor
	nextOffset uint64
	received   uint64
	checksum   hash.Hash32
	prefix     []byte
}

type mediaSubscription struct {
	types map[commonv1.MediaType]bool
	ch    chan *commonv1.MediaEvent
}

type mediaPipeline struct {
	mu        sync.Mutex
	transfers map[string]*mediaTransfer
	subs      map[uint64]mediaSubscription
	nextSub   uint64
}

func newMediaPipeline() *mediaPipeline {
	return &mediaPipeline{transfers: map[string]*mediaTransfer{}, subs: map[uint64]mediaSubscription{}}
}

// process receives bytes only after BPSK demodulation. Reversing BYTE_SHIFT
// here is intentional: changing samples before symbol decisions corrupts DSP.
func (p *mediaPipeline) process(descriptor *commonv1.MediaDescriptor, offset uint64, encoded []byte, end bool) error {
	if descriptor == nil || descriptor.TransferId == "" {
		return fmt.Errorf("media transfer_id is required")
	}
	if descriptor.TotalSize > maxMediaBytes {
		return fmt.Errorf("media transfer exceeds %d bytes", maxMediaBytes)
	}
	if descriptor.Modulation != commonv1.Modulation_MODULATION_UNSPECIFIED && descriptor.Modulation != commonv1.Modulation_MODULATION_BPSK {
		return fmt.Errorf("unsupported modulation %s", descriptor.Modulation)
	}

	data := append([]byte(nil), encoded...)
	switch descriptor.Encoding {
	case commonv1.PayloadEncoding_PAYLOAD_ENCODING_UNSPECIFIED, commonv1.PayloadEncoding_PAYLOAD_ENCODING_RAW:
	case commonv1.PayloadEncoding_PAYLOAD_ENCODING_BYTE_SHIFT:
		key := byte(descriptor.ShiftKey % 256)
		for i := range data {
			data[i] -= key
		}
	default:
		return fmt.Errorf("unsupported payload encoding %s", descriptor.Encoding)
	}

	p.mu.Lock()
	t := p.transfers[descriptor.TransferId]
	if t == nil {
		if offset != 0 {
			p.mu.Unlock()
			return fmt.Errorf("new media transfer must begin at offset 0")
		}
		t = &mediaTransfer{descriptor: proto.Clone(descriptor).(*commonv1.MediaDescriptor), checksum: crc32.NewIEEE()}
		p.transfers[descriptor.TransferId] = t
	} else if descriptor.Modulation != t.descriptor.Modulation || descriptor.Encoding != t.descriptor.Encoding || descriptor.ShiftKey != t.descriptor.ShiftKey || descriptor.TotalSize != t.descriptor.TotalSize || descriptor.Crc32 != t.descriptor.Crc32 {
		delete(p.transfers, descriptor.TransferId)
		p.mu.Unlock()
		return fmt.Errorf("media transport parameters changed mid-transfer; begin a new transfer at offset 0")
	}
	if offset != t.nextOffset {
		delete(p.transfers, descriptor.TransferId)
		p.mu.Unlock()
		return fmt.Errorf("media offset %d does not follow %d", offset, t.nextOffset)
	}
	if t.received+uint64(len(data)) > maxMediaBytes || (t.descriptor.TotalSize > 0 && t.received+uint64(len(data)) > t.descriptor.TotalSize) {
		delete(p.transfers, descriptor.TransferId)
		p.mu.Unlock()
		return fmt.Errorf("media data exceeds declared or maximum size")
	}
	_, _ = t.checksum.Write(data)
	t.received += uint64(len(data))
	t.nextOffset = t.received
	if len(t.prefix) < detectionBytes {
		take := detectionBytes - len(t.prefix)
		if take > len(data) {
			take = len(data)
		}
		t.prefix = append(t.prefix, data[:take]...)
	}
	detectedType, contentType := detectMedia(t.prefix, t.descriptor)
	checksumValid := false
	message := "receiving"
	if end {
		checksumValid = t.descriptor.Crc32 == 0 || t.checksum.Sum32() == t.descriptor.Crc32
		if t.descriptor.TotalSize > 0 && t.received != t.descriptor.TotalSize {
			message = "size mismatch"
		} else if !checksumValid {
			message = "checksum mismatch"
		} else {
			message = "complete"
		}
		delete(p.transfers, descriptor.TransferId)
	}
	event := &commonv1.MediaEvent{Media: proto.Clone(t.descriptor).(*commonv1.MediaDescriptor), DetectedType: detectedType, DetectedContentType: contentType, Offset: offset, Data: data, EndOfStream: end, ReceivedSize: t.received, ChecksumValid: checksumValid, Message: message, ObservedAtUnixMs: uint64(time.Now().UnixMilli())}
	p.publishLocked(event)
	p.mu.Unlock()
	if end && message != "complete" {
		return fmt.Errorf("media transfer %s: %s", descriptor.TransferId, message)
	}
	return nil
}

func (p *mediaPipeline) reset(reason string) {
	p.mu.Lock()
	defer p.mu.Unlock()
	for id, t := range p.transfers {
		mediaType, contentType := detectMedia(t.prefix, t.descriptor)
		p.publishLocked(&commonv1.MediaEvent{Media: proto.Clone(t.descriptor).(*commonv1.MediaDescriptor), DetectedType: mediaType, DetectedContentType: contentType, ReceivedSize: t.received, EndOfStream: true, Message: "aborted: " + reason, ObservedAtUnixMs: uint64(time.Now().UnixMilli())})
		delete(p.transfers, id)
	}
}

func (p *mediaPipeline) subscribe(types []commonv1.MediaType) (uint64, <-chan *commonv1.MediaEvent) {
	p.mu.Lock()
	defer p.mu.Unlock()
	p.nextSub++
	filter := make(map[commonv1.MediaType]bool, len(types))
	for _, mediaType := range types {
		filter[mediaType] = true
	}
	ch := make(chan *commonv1.MediaEvent, 32)
	p.subs[p.nextSub] = mediaSubscription{types: filter, ch: ch}
	return p.nextSub, ch
}

func (p *mediaPipeline) unsubscribe(id uint64) {
	p.mu.Lock()
	defer p.mu.Unlock()
	delete(p.subs, id)
}

func (p *mediaPipeline) publishLocked(event *commonv1.MediaEvent) {
	for id, sub := range p.subs {
		if len(sub.types) > 0 && !sub.types[event.DetectedType] {
			continue
		}
		select {
		case sub.ch <- proto.Clone(event).(*commonv1.MediaEvent):
		default:
			// A media stream must never silently lose a chunk. Disconnect a slow
			// consumer so it can restart the transfer instead of saving corruption.
			close(sub.ch)
			delete(p.subs, id)
		}
	}
}

func detectMedia(data []byte, hint *commonv1.MediaDescriptor) (commonv1.MediaType, string) {
	switch {
	case bytes.HasPrefix(data, []byte("\x89PNG\r\n\x1a\n")):
		return commonv1.MediaType_MEDIA_TYPE_IMAGE, "image/png"
	case bytes.HasPrefix(data, []byte{0xff, 0xd8, 0xff}):
		return commonv1.MediaType_MEDIA_TYPE_IMAGE, "image/jpeg"
	case bytes.HasPrefix(data, []byte("GIF87a")) || bytes.HasPrefix(data, []byte("GIF89a")):
		return commonv1.MediaType_MEDIA_TYPE_IMAGE, "image/gif"
	case isBMP(data):
		return commonv1.MediaType_MEDIA_TYPE_IMAGE, "image/bmp"
	case len(data) >= 12 && string(data[:4]) == "RIFF" && string(data[8:12]) == "WAVE":
		return commonv1.MediaType_MEDIA_TYPE_AUDIO, "audio/wav"
	case bytes.HasPrefix(data, []byte("fLaC")):
		return commonv1.MediaType_MEDIA_TYPE_AUDIO, "audio/flac"
	case bytes.HasPrefix(data, []byte("OggS")):
		return commonv1.MediaType_MEDIA_TYPE_AUDIO, "audio/ogg"
	case bytes.HasPrefix(data, []byte("ID3")) || (len(data) >= 2 && data[0] == 0xff && data[1]&0xe0 == 0xe0):
		return commonv1.MediaType_MEDIA_TYPE_AUDIO, "audio/mpeg"
	case looksLikeText(data):
		trimmed := strings.TrimSpace(string(data))
		if strings.HasPrefix(trimmed, "{") || strings.HasPrefix(trimmed, "[") {
			return commonv1.MediaType_MEDIA_TYPE_TEXT, "application/json"
		}
		return commonv1.MediaType_MEDIA_TYPE_TEXT, "text/plain; charset=utf-8"
	case hint != nil && hint.MediaTypeHint != commonv1.MediaType_MEDIA_TYPE_UNSPECIFIED:
		return hint.MediaTypeHint, hint.ContentTypeHint
	default:
		return commonv1.MediaType_MEDIA_TYPE_BINARY, "application/octet-stream"
	}
}

// isBMP checks the "BM" signature plus a known DIB header size, so text that
// merely starts with "BM" is not misclassified as an image.
func isBMP(data []byte) bool {
	if len(data) < 18 || data[0] != 'B' || data[1] != 'M' {
		return false
	}
	switch binary.LittleEndian.Uint32(data[14:18]) {
	case 12, 40, 52, 56, 108, 124:
		return true
	}
	return false
}

func looksLikeText(data []byte) bool {
	if len(data) == 0 || !utf8.Valid(data) {
		return false
	}
	printable := 0
	for _, r := range string(data) {
		if r == '\n' || r == '\r' || r == '\t' || r >= 0x20 {
			printable++
		}
	}
	return printable*100/utf8.RuneCount(data) >= 90
}

func (s *Server) WatchMedia(req *commonv1.WatchMediaRequest, stream commonv1.MediaStreamService_WatchMediaServer) error {
	var types []commonv1.MediaType
	if req != nil {
		types = req.Types
	}
	id, events := s.media.subscribe(types)
	defer s.media.unsubscribe(id)
	for {
		select {
		case <-stream.Context().Done():
			return stream.Context().Err()
		case event, ok := <-events:
			if !ok {
				return status.Error(codes.ResourceExhausted, "media subscriber fell behind; reconnect before the next transfer")
			}
			if err := stream.Send(event); err != nil {
				return err
			}
		}
	}
}

// streamMediaHTTP provides the same all-media stream to clients without gRPC.
// Each line is JSON and byte data is standard base64 through encoding/json.
func (s *Server) streamMediaHTTP(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		w.WriteHeader(http.StatusMethodNotAllowed)
		return
	}
	flusher, ok := w.(http.Flusher)
	if !ok {
		http.Error(w, "streaming unsupported", http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/x-ndjson")
	w.Header().Set("Cache-Control", "no-cache")
	id, events := s.media.subscribe(nil)
	defer s.media.unsubscribe(id)
	encoder := json.NewEncoder(w)
	for {
		select {
		case <-r.Context().Done():
			return
		case event, ok := <-events:
			if !ok {
				http.Error(w, "media subscriber fell behind; reconnect", http.StatusServiceUnavailable)
				return
			}
			if err := encoder.Encode(event); err != nil {
				return
			}
			flusher.Flush()
		}
	}
}
