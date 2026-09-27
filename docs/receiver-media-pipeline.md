# Receiver media pipeline

The receiver has one output contract for every application payload:
`common.v1.MediaStreamService.WatchMedia`. A client may subscribe to all
events or filter by `TEXT`, `IMAGE`, `AUDIO` or `BINARY`; it does not need a
different endpoint for each kind of data.

## Where modulation and shifting belong

```text
sender bytes -> optional byte shift -> bits -> BPSK modulation -> samples
samples -> Kalman/filter -> BPSK demodulation -> shifted bytes
        -> reverse byte shift -> CRC/reassembly -> type detection -> clients
```

- Modulation converts bits into physical signal symbols. It happens last on
  the sender and first (after signal conditioning) on the receiver.
- The byte-shift transform operates on reconstructed bytes, never on noisy
  samples. Reversing it earlier destroys the meaning of the DSP samples.
- Modulation, encoding and key metadata are fixed for a transfer. Change them
  only at a frame/transfer boundary, reset demodulator state, and begin the new
  transfer at offset zero.
- BPSK is currently the only implemented modulation. The explicit enum makes
  unsupported QPSK or future schemes fail instead of being decoded wrongly.
- `BYTE_SHIFT` provides no security. Use authenticated encryption before
  modulation if confidentiality is required later.

## Detection

The receiver prefers byte signatures for PNG, JPEG, GIF, WAV, FLAC, Ogg and
MP3. Valid mostly-printable UTF-8 is classified as text, with JSON recognized
separately. Producer hints are only a fallback; unknown content remains binary.

Each event carries decoded bytes, offset, accumulated size, detected content
type and final CRC status. A sequence gap aborts active media transfers so a
damaged file cannot be reported as complete.
