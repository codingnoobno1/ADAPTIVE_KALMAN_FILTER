# Sender server - Laptop 1

## Owns

- BPSK/reference-bit generation and future hardware signal sources.
- Channel simulation and sample-frame construction.
- `TransmitterService` and the outbound `ReceiverService.ProcessSignal` client.
- Sender reconnect behavior, sequence numbers and capture timestamps.

`main.go` is the composition root. Keep algorithms and state in `core/`; add optional SDR/audio/file sources behind interfaces in `extensions/`.

Build and run only this server:

```powershell
go build -o bin/sender.exe ./server/sender
.\bin\sender.exe --config configs/local.json
```

Do not add receiver DSP or controller policy here.

