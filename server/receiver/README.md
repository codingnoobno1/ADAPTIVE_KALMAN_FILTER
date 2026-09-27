# Receiver server - Laptop 2

## Owns

- Bounded sample ingestion and stream continuity.
- Kalman state, BPSK decisions, BER/SNR/noise metrics and sequence-gap reset.
- `ReceiverService`, Controller adaptation client and ESP32 protobuf endpoint.
- One `common.v1.MediaStreamService/WatchMedia` endpoint for decoded text,
  image, audio and binary chunks, with optional type filtering.
- Automatic signature/UTF-8 media detection, ordered transfer reassembly,
  size limits and CRC-32 completion checks.
- Future AI signal classification through `extensions.MetricsEnricher`.

`main.go` wires listeners and the Controller client. Required DSP stays in `core/` and shared mathematical primitives stay under `shared/dsp/`.

```powershell
go build -o bin/receiver.exe ./server/receiver
.\bin\receiver.exe --config configs/local.json
```

Do not add UI rendering or transmitter generation here.

## Receive pipeline

The order is intentional:

1. Unpack `float32` or ESP32-friendly `int16` samples.
2. Apply Kalman filtering and make BPSK hard decisions.
3. Pack the decisions into application bytes.
4. Reverse `BYTE_SHIFT` encoding when selected.
5. Check offsets, total size and CRC-32.
6. Detect text/image/audio from the decoded bytes.
7. Publish every decoded chunk on the common media stream.

Do not apply a byte-shift key to signal samples. The sender shifts payload
bytes before modulation; the receiver reverses it after demodulation. A key or
modulation change must start on a new frame/transfer boundary. `BYTE_SHIFT` is
an educational reversible transform and is not encryption.

Clients can consume the gRPC stream on the receiver port or the NDJSON bridge:

```text
GET http://<receiver-host>:8082/api/v1/media
```
