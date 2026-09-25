# Architecture and design boundaries

```text
Laptop 1 / TX :50051        Laptop 2 / RX :50052         Laptop 3 / Control :50053
TransmitterService   --->   ReceiverService       --->   ControllerService
  BPSK generator              bounded frame queue           policy decisions
  frame sequence              scalar Kalman state           experiment state
  reference bits              hard decision + BER           WatchExperiment
  RX stream client            Control stream client         HTTP/SSE :8080
                               ESP32 HTTP :8082                  |
                                                                 +--> MAUI / Flutter
```

Every endpoint also implements `common.v1.NodeService`. This provides the same discovery, capability and status contract on all three machines without weakening the separation of the TX, RX and Controller APIs.

```text
                         common.v1.NodeService
                      /           |            \
             TX :50051       RX :50052       Control :50053
          TransmitterService ReceiverService ControllerService
```

The Wi-Fi network transports digitized samples; it is not the experimental BPSK physical channel. The receiver owns all sample-rate DSP. Dashboards receive reduced metrics rather than every sample.

## Reliability rules

- `run_id`, `stream_id`, and `sequence` detect restarts and gaps.
- A gap resets the Kalman state and increments `sequence_gaps`.
- Receiver and controller queues are bounded; slow observers lose old dashboard events rather than blocking DSP.
- Controller decisions carry command IDs, config versions, and future effective sequence numbers.
- TX and RX reject stale versions and apply accepted configuration only at a frame boundary.
- Each client reconnects with exponential backoff and jitter.
- The local profile uses ports `55051-55053` because Windows services commonly occupy `50051-50052`; the LAN template retains `50051-50053`.

## Reusable layers

- `pkg/labclient`: Go client facade for all three endpoints.
- `pkg/extension`: Go interfaces for signal sources, frame processors, policies and metric sinks.
- `sdk/dart/livekalman_sdk`: framework-independent Dart gRPC SDK generated from the same contracts.
- `shared/node`: shared `NodeService` implementation registered by all three binaries.
- `apps/*`: presentation layers only; they do not own the DSP or adaptation policy.

## Security boundary

The checked-in defaults use plaintext transport for an isolated lab. On shared networks, add TLS with peer identity verification, authenticate the ESP32 endpoint, restrict firewall rules to the three laptop addresses, and never expose ports `50051-50053`, `8080`, or `8082` to the public internet.
