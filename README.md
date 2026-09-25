# STREAMING_LIVEKALMANFILTER

A runnable three-server adaptive BPSK/Kalman lab based on the attached design. It includes independent Go gRPC services, reproducible protobuf contracts, a .NET MAUI Blazor Hybrid monitor, a Flutter desktop/mobile monitor, and a protobuf endpoint suitable for an ESP32.

## One-command local demo

From PowerShell in this directory:

```powershell
.\scripts\dev-all.ps1 -Dashboard flutter
```

That command downloads a project-local Go/protoc toolchain, generates protobuf code, runs tests, builds all targets, starts Controller -> RX -> TX, and launches the selected dashboard. Use `-Dashboard maui` or `-Dashboard none` as needed.

For faster later runs:

```powershell
.\scripts\run-all.ps1 -Dashboard flutter
.\scripts\stop-all.ps1
```

Runtime logs are written to `logs/`; exact child PIDs are kept in `run/`. The stop script only terminates binaries whose resolved path is inside this project's `bin/` directory.

## Three-laptop deployment

1. Copy `configs/lan.example.json` to `configs/lan.json` on each machine.
2. Replace the sample IPs with the TX, RX, and Controller Wi-Fi addresses.
3. Run `.\scripts\build-all.ps1` on each development machine, or copy the three files from `bin/`.
4. Open only the required inbound firewall port on each laptop.
5. Start in order:

```powershell
# Laptop 3
.\scripts\run-role.ps1 -Role controller
# Laptop 2
.\scripts\run-role.ps1 -Role rx
# Laptop 1
.\scripts\run-role.ps1 -Role tx
```

The processes tolerate a missing peer and reconnect. On one PC, the local profile uses `55051-55053`; the LAN profile uses the PDF's `50051-50053` ports.

## Interfaces

| Host | Interface | Purpose |
| --- | --- | --- |
| TX | `TransmitterService` | Apply versioned TX profiles, status, events |
| RX | `ReceiverService.ProcessSignal` | Bidirectional framed samples and feedback |
| RX | `POST :8082/api/v1/frames` | ESP32-compatible binary protobuf request/reply |
| Controller | `ControllerService.Adapt` | Metrics upstream, policy decisions downstream |
| Controller | `WatchExperiment` | Native gRPC UI/event stream |
| Controller | `GET :8080/api/v1/events` | Low-rate SSE feed for MAUI and Flutter |
| Controller | `GET :8080/api/v1/state` | Latest state snapshot |

See [architecture](docs/architecture.md) for lifecycle, state, and security boundaries and [ESP32 example](examples/esp32/README.md) for embedded generation instructions.

## What is implemented

- 512-sample frames at 48 kHz, deterministic bit/noise generation, explicit reference bits, sequence and timestamps.
- Stateful scalar Kalman filter, symbol integration, BPSK decisions, SNR/noise estimate, BER, queue depth, and latency.
- Controller-generated bounded `R` updates with cooldown, versioning, and future effective sequence.
- Responsive dark monitoring UIs for Windows/Android/web (Flutter) and Windows/Android/iOS/macOS targets (.NET MAUI).
- Portable PowerShell bootstrap/build/run/stop scripts and Go DSP tests.

The algorithm is an executable research baseline, not a claim of an optimal Kalman state model. Tune `Q`, `R`, symbol timing, and synchronization against controlled seeds before comparing fixed and adaptive runs.
