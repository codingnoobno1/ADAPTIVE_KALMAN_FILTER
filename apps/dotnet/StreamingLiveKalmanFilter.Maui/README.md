# MAUI real-time signal demonstration

The MAUI Blazor Hybrid application uses one executable for all three laptops.
On startup, select Sender, Receiver or Controller and enter the four lab
endpoints. The role can be switched without restarting.

Unlike the earlier metrics-only screen, these panels use bounded protobuf
diagnostic streams emitted by the real processing path:

- Sender: original, byte-shifted and scrambled bytes; BPSK bits; clean symbols;
  noisy samples; file offset; and gRPC send confirmation.
- Receiver: received noisy samples, Kalman DC estimate, hard-decision bytes,
  decoded bytes, BER, reassembly progress and CRC state.
- Controller: active RULE/ONNX policy, six model features, predicted Q/R ratio,
  proposed Q and R, effective sequence, and BER before/after application.

## Demo

```powershell
.\scripts\build-servers.ps1
.\scripts\run-all.ps1 -Config configs\local-impaired.json
dotnet run --project apps\dotnet\StreamingLiveKalmanFilter.Maui -f net10.0-windows10.0.19041.0
```

Use these defaults in the setup screen:

```text
Sender gRPC       127.0.0.1:55051
Receiver gRPC     127.0.0.1:55052
Controller gRPC   127.0.0.1:55053
Sender file API   127.0.0.1:8081
```

Choose a small TXT, BMP or WAV file in Sender mode. `local-impaired.json`
enables the ONNX policy and channel impairments, so CRC failure is possible and
is a valid result rather than a disconnected stream.

The generated C# protobuf client files in `Generated/` are committed so the
MAUI project can build without requiring a system `protoc` installation.
