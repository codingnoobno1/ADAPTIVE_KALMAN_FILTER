// Command-line health watcher: probes all three nodes with real gRPC calls
// and prints one JSON line per node per probe. Useful to verify a LAN setup
// or a tunnel before a demo.
//
//   dart run example/health_watch.dart grpc://127.0.0.1:55053 [seconds]
//   dart run example/health_watch.dart "grpcs://lab.example.com?txHost=tx.example.com&rxHost=rx.example.com" 60
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:livekalman_sdk/livekalman_sdk.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln(
      'usage: health_watch.dart <grpc://controller:port?txHost=..&rxHost=..> [seconds]',
    );
    exit(2);
  }
  final uri = Uri.parse(args[0]);
  final seconds = args.length > 1 ? int.parse(args[1]) : 30;
  final secure = uri.scheme == 'grpcs';
  int port(String name, int fallback) =>
      int.tryParse(uri.queryParameters[name] ?? '') ??
      (secure ? 443 : fallback);
  final client = LiveKalmanClient.connect(
    LabEndpoints(
      transmitterHost: uri.queryParameters['txHost'] ?? uri.host,
      receiverHost: uri.queryParameters['rxHost'] ?? uri.host,
      controllerHost: uri.host,
      transmitterPort: port('txPort', 55051),
      receiverPort: port('rxPort', 55052),
      controllerPort: port('controllerPort', uri.hasPort ? uri.port : 55053),
    ),
    secure: secure,
  );
  var health = [
    const NodeHealth(role: NodeRole.NODE_ROLE_TRANSMITTER),
    const NodeHealth(role: NodeRole.NODE_ROLE_RECEIVER),
    const NodeHealth(role: NodeRole.NODE_ROLE_CONTROLLER),
  ];
  final end = DateTime.now().add(Duration(seconds: seconds));
  while (DateTime.now().isBefore(end)) {
    final probes = await client.probeNodes();
    final now = DateTime.now();
    health = [
      for (var i = 0; i < 3; i++) evaluateProbe(health[i], probes[i], now),
    ];
    for (final h in health) {
      stdout.writeln(jsonEncode(h.toJson()));
    }
    stdout.writeln(
      jsonEncode({
        'tx_to_rx': transmitterToReceiver(health[0], health[1]),
        'at': now.toUtc().toIso8601String(),
      }),
    );
    await Future<void>.delayed(const Duration(seconds: 1));
  }
  await client.close();
}
