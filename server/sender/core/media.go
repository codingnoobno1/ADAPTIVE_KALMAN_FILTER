package core

import (
	"fmt"
	"hash/crc32"
	"mime"
	"path/filepath"
	"strings"
	"time"

	commonv1 "github.com/streaming-live-kalman/filter/gen/common/v1"
	txv1 "github.com/streaming-live-kalman/filter/gen/tx/v1"
)

// MaxTransferBytes bounds one queued file. At the default 8 samples/symbol,
// 512-sample frames and 48 kHz the link carries ~750 B/s, so 1 MiB is ~23 min.
const MaxTransferBytes = 1 << 20

const recentTransfers = 20

// TransferStatus is the JSON view of a file transfer served by the sender API.
type TransferStatus struct {
	TransferID       string  `json:"transferId"`
	FileName         string  `json:"fileName"`
	MediaType        string  `json:"mediaType"`
	ContentType      string  `json:"contentType"`
	Encoding         string  `json:"encoding"`
	TotalBytes       int     `json:"totalBytes"`
	SentBytes        int     `json:"sentBytes"`
	CRC32            uint32  `json:"crc32"`
	State            string  `json:"state"` // queued | sending | sent
	EstimatedSeconds float64 `json:"estimatedSeconds"`
	QueuedAtUnixMs   int64   `json:"queuedAtUnixMs"`
	FinishedAtUnixMs int64   `json:"finishedAtUnixMs,omitempty"`
}

type transfer struct {
	descriptor *commonv1.MediaDescriptor
	encoded    []byte // payload after the byte-shift encoding, ready to modulate
	offset     int
	status     TransferStatus
}

// TransferRequest describes a file to send over the modulated link.
type TransferRequest struct {
	FileName    string
	ContentType string // optional; derived from the file extension if empty
	Data        []byte
	Encoding    commonv1.PayloadEncoding
	ShiftKey    uint32
}

// EnqueueTransfer validates a file and queues it behind any active transfer.
// The CRC covers the original bytes; the receiver checks it after demodulation
// and after reversing the byte shift.
func (s *Server) EnqueueTransfer(req TransferRequest) (TransferStatus, error) {
	if len(req.Data) == 0 {
		return TransferStatus{}, fmt.Errorf("file is empty")
	}
	if len(req.Data) > MaxTransferBytes {
		return TransferStatus{}, fmt.Errorf("file is %d bytes; the limit is %d", len(req.Data), MaxTransferBytes)
	}
	switch req.Encoding {
	case commonv1.PayloadEncoding_PAYLOAD_ENCODING_UNSPECIFIED:
		req.Encoding = commonv1.PayloadEncoding_PAYLOAD_ENCODING_RAW
	case commonv1.PayloadEncoding_PAYLOAD_ENCODING_RAW, commonv1.PayloadEncoding_PAYLOAD_ENCODING_BYTE_SHIFT:
	default:
		return TransferStatus{}, fmt.Errorf("unsupported payload encoding %s", req.Encoding)
	}
	name := filepath.Base(strings.ReplaceAll(req.FileName, "\\", "/"))
	if name == "." || name == "/" || name == "" {
		name = "payload.bin"
	}
	mediaType, contentType := classify(name, req.ContentType)
	encoded := append([]byte(nil), req.Data...)
	if req.Encoding == commonv1.PayloadEncoding_PAYLOAD_ENCODING_BYTE_SHIFT {
		key := byte(req.ShiftKey % 256)
		for i := range encoded {
			encoded[i] += key
		}
	}

	s.mu.Lock()
	defer s.mu.Unlock()
	s.nextTransfer++
	id := fmt.Sprintf("tx-%d-%d", time.Now().Unix(), s.nextTransfer)
	crc := crc32.ChecksumIEEE(req.Data)
	t := &transfer{
		descriptor: &commonv1.MediaDescriptor{TransferId: id, FileName: name, MediaTypeHint: mediaType, ContentTypeHint: contentType, TotalSize: uint64(len(req.Data)), Crc32: crc, Modulation: commonv1.Modulation_MODULATION_BPSK, Encoding: req.Encoding, ShiftKey: req.ShiftKey},
		encoded:    encoded,
		status:     TransferStatus{TransferID: id, FileName: name, MediaType: strings.TrimPrefix(mediaType.String(), "MEDIA_TYPE_"), ContentType: contentType, Encoding: strings.TrimPrefix(req.Encoding.String(), "PAYLOAD_ENCODING_"), TotalBytes: len(req.Data), CRC32: crc, State: "queued", QueuedAtUnixMs: time.Now().UnixMilli()},
	}
	s.queue = append(s.queue, t)
	s.publishLocked(&txv1.TxEvent{Sequence: s.sequence, Description: fmt.Sprintf("queued %s (%d bytes, %s)", name, len(req.Data), contentType)})
	return s.statusLocked(t), nil
}

// Transfers returns the active transfer, the queue and recently finished ones.
func (s *Server) Transfers() (active *TransferStatus, queued, recent []TransferStatus) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	if s.current != nil {
		st := s.statusLocked(s.current)
		active = &st
	}
	for _, t := range s.queue {
		queued = append(queued, s.statusLocked(t))
	}
	recent = append(recent, s.recent...)
	return active, queued, recent
}

// BytesPerSecond is the payload throughput of the modulated link.
func (s *Server) BytesPerSecond() float64 {
	return float64(s.frameCapacity()) * float64(s.cfg.SampleRateHz) / float64(s.cfg.SamplesPerFrame)
}

func (s *Server) frameCapacity() int {
	return s.cfg.SamplesPerFrame / int(s.cfg.SamplesPerSymbol) / 8
}

// nextPayloadLocked takes the next chunk of the active transfer, starting a
// queued one if the link is idle. It returns nil media for an idle frame.
func (s *Server) nextPayloadLocked(sequence uint64) (payload []byte, media *commonv1.MediaDescriptor, offset uint64, end bool) {
	if s.current == nil {
		if len(s.queue) == 0 {
			return nil, nil, 0, false
		}
		s.current, s.queue = s.queue[0], s.queue[1:]
		s.current.status.State = "sending"
		s.publishLocked(&txv1.TxEvent{Sequence: sequence, Description: "sending " + s.current.status.FileName})
	}
	t := s.current
	n := s.frameCapacity()
	if remaining := len(t.encoded) - t.offset; remaining < n {
		n = remaining
	}
	payload = t.encoded[t.offset : t.offset+n]
	offset = uint64(t.offset)
	t.offset += n
	end = t.offset == len(t.encoded)
	if end {
		t.status.State = "sent"
		t.status.FinishedAtUnixMs = time.Now().UnixMilli()
		t.status.SentBytes = t.offset
		s.recent = append([]TransferStatus{t.status}, s.recent...)
		if len(s.recent) > recentTransfers {
			s.recent = s.recent[:recentTransfers]
		}
		s.current = nil
		s.publishLocked(&txv1.TxEvent{Sequence: sequence, Description: fmt.Sprintf("sent %s (%d bytes)", t.status.FileName, len(t.encoded))})
	}
	return payload, t.descriptor, offset, end
}

// restartActiveLocked rewinds a partially sent transfer. A new signal stream
// is a sequence gap for the receiver, which aborts partial transfers, so the
// file must begin again at offset zero.
func (s *Server) restartActiveLocked() {
	if s.current != nil && s.current.offset > 0 {
		s.current.offset = 0
		s.publishLocked(&txv1.TxEvent{Sequence: s.sequence, Description: "restarting " + s.current.status.FileName + " after reconnect"})
	}
}

func (s *Server) statusLocked(t *transfer) TransferStatus {
	st := t.status
	st.SentBytes = t.offset
	remaining := len(t.encoded) - t.offset
	for _, q := range s.queue {
		if q == t {
			break
		}
		remaining += len(q.encoded)
	}
	if t != s.current && s.current != nil && st.State == "queued" {
		remaining += len(s.current.encoded) - s.current.offset
	}
	if bps := s.BytesPerSecond(); bps > 0 && st.State != "sent" {
		st.EstimatedSeconds = float64(remaining) / bps
	}
	return st
}

func classify(name, contentType string) (commonv1.MediaType, string) {
	// Generic types say nothing about the file (curl sends form-urlencoded by
	// default), so fall back to the extension for them.
	switch strings.ToLower(strings.TrimSpace(strings.SplitN(contentType, ";", 2)[0])) {
	case "", "application/octet-stream", "application/x-www-form-urlencoded", "multipart/form-data":
		contentType = ""
	}
	if contentType == "" {
		contentType = mime.TypeByExtension(strings.ToLower(filepath.Ext(name)))
	}
	if contentType == "" {
		contentType = "application/octet-stream"
	}
	base := strings.ToLower(strings.TrimSpace(strings.SplitN(contentType, ";", 2)[0]))
	switch {
	case strings.HasPrefix(base, "text/") || base == "application/json":
		return commonv1.MediaType_MEDIA_TYPE_TEXT, contentType
	case strings.HasPrefix(base, "image/"):
		return commonv1.MediaType_MEDIA_TYPE_IMAGE, contentType
	case strings.HasPrefix(base, "audio/"):
		return commonv1.MediaType_MEDIA_TYPE_AUDIO, contentType
	default:
		return commonv1.MediaType_MEDIA_TYPE_BINARY, contentType
	}
}
