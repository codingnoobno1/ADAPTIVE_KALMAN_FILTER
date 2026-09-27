# Device 2 Receiver implementation status

## Completed

- Go Receiver service with gRPC streaming and ESP32 protobuf HTTP endpoint.
- Stateful scalar Kalman filtering, BPSK symbol integration, BER, estimated
  noise variance/SNR, latency, sequence-gap reset, and Controller feedback.
- Controller-driven R adaptation with versioning and future effective sequence.
- Receiver validation now rejects nil/malformed frames, missing identity and
  timing metadata, unsupported sample formats, non-finite samples, incomplete
  BPSK symbols, reference-bit length mismatches, and invalid Q/R values.
- Signal power is measured from received samples. Noise variance and SNR are
  decision-directed estimates that do not read reference bits; reference bits
  remain simulation-only BER scoring input.
- Packed little-endian `float32` and normalized `int16` input for embedded
  producers, with optional simulation reference bits.
- BPSK payload reconstruction, optional post-demodulation byte-shift reversal,
  CRC/size/offset checks, automatic text/image/audio detection, and common
  gRPC plus NDJSON media streams.

## Not implemented

- Complex I/Q sample framing, QPSK, 8-PSK, phase features, innovation/NIS
  metrics, and AI-assisted Q/R inference.
- Hardware deployment verification. The ESP32-compatible software endpoint is
  implemented, but no physical-device test is claimed.

## Verification status

Go tests, vet, Dart analysis and the server build were run on 2026-09-27 and
pass. Go and Dart protobufs have been regenerated. See `TEST_REPORT.md`.
