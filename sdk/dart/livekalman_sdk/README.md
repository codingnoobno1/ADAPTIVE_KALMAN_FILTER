# livekalman_sdk

Reusable Dart gRPC client for the TX, RX and Controller nodes. It exposes the generated role-specific clients plus common node discovery and status APIs.

```dart
final lab = LiveKalmanClient.insecure(const LabEndpoints(
  transmitterHost: '192.168.1.11',
  receiverHost: '192.168.1.12',
  controllerHost: '192.168.1.13',
));

final nodes = await lab.discoverNodes();
await for (final event in lab.watchExperiment(runId: 'lan-demo')) {
  if (event.hasMetrics()) print(event.metrics.snrDb);
}
await lab.close();
```

Use TLS channel credentials outside an isolated trusted lab.

