package core

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strconv"
	"strings"

	commonv1 "github.com/streaming-live-kalman/filter/gen/common/v1"
)

// HTTPHandler serves the file-transfer API:
//
//	POST /api/v1/transfers?name=photo.bmp[&encoding=raw|byte_shift&key=N]
//	     body = raw file bytes, Content-Type optional (else from the extension)
//	GET  /api/v1/transfers  -> active, queued and recent transfers
func (s *Server) HTTPHandler() http.Handler {
	mux := http.NewServeMux()
	mux.HandleFunc("/healthz", func(w http.ResponseWriter, _ *http.Request) { _, _ = w.Write([]byte(`{"status":"ok"}`)) })
	mux.HandleFunc("/api/v1/transfers", s.transfersHTTP)
	return cors(mux)
}

func (s *Server) transfersHTTP(w http.ResponseWriter, r *http.Request) {
	switch r.Method {
	case http.MethodGet:
		active, queued, recent := s.Transfers()
		writeJSON(w, http.StatusOK, map[string]any{"active": active, "queued": queued, "recent": recent, "bytesPerSecond": s.BytesPerSecond(), "maxTransferBytes": MaxTransferBytes})
	case http.MethodPost:
		data, err := io.ReadAll(io.LimitReader(r.Body, MaxTransferBytes+1))
		if err != nil {
			writeJSON(w, http.StatusBadRequest, map[string]string{"error": err.Error()})
			return
		}
		encoding, err := parseEncoding(r.URL.Query().Get("encoding"))
		if err != nil {
			writeJSON(w, http.StatusBadRequest, map[string]string{"error": err.Error()})
			return
		}
		var key uint64
		if k := r.URL.Query().Get("key"); k != "" {
			if key, err = strconv.ParseUint(k, 10, 8); err != nil {
				writeJSON(w, http.StatusBadRequest, map[string]string{"error": "key must be 0-255"})
				return
			}
		}
		status, err := s.EnqueueTransfer(TransferRequest{FileName: r.URL.Query().Get("name"), ContentType: r.Header.Get("Content-Type"), Data: data, Encoding: encoding, ShiftKey: uint32(key)})
		if err != nil {
			writeJSON(w, http.StatusBadRequest, map[string]string{"error": err.Error()})
			return
		}
		writeJSON(w, http.StatusAccepted, status)
	case http.MethodOptions:
		w.WriteHeader(http.StatusNoContent)
	default:
		w.WriteHeader(http.StatusMethodNotAllowed)
	}
}

func parseEncoding(v string) (commonv1.PayloadEncoding, error) {
	switch strings.ToLower(v) {
	case "", "raw":
		return commonv1.PayloadEncoding_PAYLOAD_ENCODING_RAW, nil
	case "byte_shift", "shift":
		return commonv1.PayloadEncoding_PAYLOAD_ENCODING_BYTE_SHIFT, nil
	default:
		return 0, fmt.Errorf("encoding must be raw or byte_shift")
	}
}

func writeJSON(w http.ResponseWriter, code int, v any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(code)
	_ = json.NewEncoder(w).Encode(v)
}

func cors(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type")
		next.ServeHTTP(w, r)
	})
}
