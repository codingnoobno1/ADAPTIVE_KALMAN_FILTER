# Extending the three-server platform

The platform separates contracts, reusable SDKs, extension interfaces and process implementations. Add new behavior at the narrowest layer that owns it.

## Contract layers

| Contract | Implemented by | Purpose |
| --- | --- | --- |
| `common/v1.NodeService` | TX, RX and Controller | Discovery, capabilities and role-neutral health |
| `tx/v1.TransmitterService` | TX only | Desired transmitter configuration and status |
| `rx/v1.ReceiverService` | RX only | Sample streaming, DSP feedback and receiver configuration |
| `control/v1.ControllerService` | Controller only | Metrics adaptation and experiment event stream |

Keep messages in `common/v1` only when every role needs them. Do not move receiver metrics or transmitter configuration into the common package simply to avoid an import.

## Go extensions

Reusable clients live in `pkg/labclient`. Algorithm and hardware boundaries live in `pkg/extension`:

- Implement `SignalSource` for an SDR, audio device, serial bridge or recorded file.
- Implement `FrameProcessor` for a different Kalman state model, synchronization chain or demodulator.
- Implement `AdaptationPolicy` for a different controller algorithm.
- Implement `MetricsSink` for a database, OpenTelemetry exporter or experiment archive.

The three `server/<role>/main.go` files are composition roots: configuration and dependency wiring belong there, while reusable algorithms belong under the role's `core/`, `extensions/`, or the carefully controlled `shared/` packages.

## Dart extensions

`sdk/dart/livekalman_sdk` is independent of Flutter. It contains generated protobuf/gRPC clients and the `LiveKalmanClient` facade for all three endpoints. A desktop/mobile UI can use native gRPC; a browser UI should retain the Controller SSE gateway because browsers cannot directly use standard gRPC over HTTP/2 without a gRPC-Web proxy.

Each process composition root is now `server/<role>/main.go`. Required behavior lives under that role's `core/` package; future hardware, AI, UI-export and policy hooks live under its `extensions/` package. Shared code belongs under `shared/` only when at least two servers genuinely need it.

Regenerate both language SDKs after changing a `.proto` file:

```powershell
.\scripts\generate.ps1
.\scripts\generate-dart.ps1
```

Never reuse a removed field number. Add new fields with new numbers, reserve removed numbers, and introduce `v2` packages for breaking changes.
