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

The Wi-Fi network transports digitized samples; it is not the experimental BPSK physical channel. The receiver owns all sample-rate DSP. Dashboards receive reduced metrics rather than every sample.

## Reliability rules

- `run_id`, `stream_id`, and `sequence` detect restarts and gaps.
- A gap resets the Kalman state and increments `sequence_gaps`.
- Receiver and controller queues are bounded; slow observers lose old dashboard events rather than blocking DSP.
- Controller decisions carry command IDs, config versions, and future effective sequence numbers.
- TX and RX reject stale versions and apply accepted configuration only at a frame boundary.
- Each client reconnects with exponential backoff and jitter.
- The local profile uses ports `55051-55053` because Windows services commonly occupy `50051-50052`; the LAN template retains `50051-50053`.

## Security boundary

The checked-in defaults use plaintext transport for an isolated lab. On shared networks, add TLS with peer identity verification, authenticate the ESP32 endpoint, restrict firewall rules to the three laptop addresses, and never expose ports `50051-50053`, `8080`, or `8082` to the public internet.

