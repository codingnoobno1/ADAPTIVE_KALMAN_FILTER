# Device 2 Receiver interface

The Receiver preserves the existing `livekalman.rx.v1.ReceiverService`
contract. `ProcessSignal` consumes and emits streams, while
`ApplyReceiverConfig` prepares a versioned Q/R update for a frame boundary.

## Current accepted frame

`TxFrame` must contain a non-empty `run_id`, non-zero `stream_id`, `sequence`,
`sample_rate_hz`, `samples_per_symbol`, and `capture_timestamp_us`. The current
DSP accepts repeated `SAMPLE_FORMAT_FLOAT32_LE` samples or packed little-endian
`float32`/`int16` real-valued BPSK samples. The sample count must be a positive
multiple of `samples_per_symbol` and all samples must be finite.
`reference_bits`, when supplied by a simulator, must occupy exactly
`ceil(symbol_count / 8)` bytes (least-significant-bit first). It may be omitted
for real payloads; BER comparison is then unavailable but decoding continues.

`MediaDescriptor.modulation` explicitly accepts BPSK for application payloads.
There is still no complex I/Q frame representation, so QPSK/8-PSK are rejected
and require a coordinated contract and DSP extension.

Optional media fields associate demodulated bytes with a transfer, offset,
total size, CRC, encoding and key. The receiver exposes all detected payloads
through `common.v1.MediaStreamService.WatchMedia` and `GET /api/v1/media`.

## Q/R validation

Receiver configuration and Controller decisions accept only finite, strictly
positive Q and R values. Existing Controller bounds remain the policy authority
for R; this validation does not add a competing adaptation mechanism.
