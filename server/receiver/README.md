# Receiver server - Laptop 2

## Owns

- Bounded sample ingestion and stream continuity.
- Kalman state, BPSK decisions, BER/SNR/noise metrics and sequence-gap reset.
- `ReceiverService`, Controller adaptation client and ESP32 protobuf endpoint.
- Future AI signal classification through `extensions.MetricsEnricher`.

`main.go` wires listeners and the Controller client. Required DSP stays in `core/` and shared mathematical primitives stay under `shared/dsp/`.

```powershell
go build -o bin/receiver.exe ./server/receiver
.\bin\receiver.exe --config configs/local.json
```

Do not add UI rendering or transmitter generation here.

