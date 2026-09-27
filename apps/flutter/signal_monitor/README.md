# Live Kalman Flutter console

Responsive Windows/mobile operations UI for the three-device lab:

- Laptop 1 Sender discovery, health, capabilities and sequence.
- Laptop 2 Receiver health, signal metrics and detected media transfers.
- Laptop 3 Controller health, adaptive configuration and experiment events.
- SNR/BER history, latency, noise and active Kalman profile.

On the first launch, the application asks whether the device is the Sender,
Receiver or Controller and remembers that choice. Use the role menu in the
header to switch later. All three laptops use the same executable.

The role can also be selected at launch:

```powershell
signal_monitor.exe --role sender
signal_monitor.exe --role receiver
signal_monitor.exe --role controller
```

- Sender mode provides versioned BPSK amplitude, symbol-rate and noise controls
  plus constellation/waveform previews and transmission status.
- Receiver mode provides DSP metrics, history charts and decoded media status.
- Controller mode provides the three-device topology, adaptation history and
  event log.

## Connection

The full dashboard uses the three gRPC endpoints. The controller address is the
main URI and Sender/Receiver addresses are query parameters:

```text
grpc://192.168.1.30:50053?txHost=192.168.1.10&rxHost=192.168.1.20&txPort=50051&rxPort=50052
```

For a single-machine local run:

```text
grpc://127.0.0.1:55053?txHost=127.0.0.1&rxHost=127.0.0.1&txPort=55051&rxPort=55052
```

The Controller SSE URL remains supported as a metrics-only fallback, but it
cannot provide three-node discovery or the Receiver media stream.

## Run and verify

```powershell
flutter run -d windows
flutter analyze
flutter test
flutter build windows
```
