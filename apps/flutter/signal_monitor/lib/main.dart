import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:livekalman_sdk/livekalman_sdk.dart' as lk;

void main() => runApp(const SignalMonitorApp());

class SignalMonitorApp extends StatelessWidget {
  const SignalMonitorApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Live Kalman Lab',
    theme: ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xff071016),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xff58f3c2),
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
    ),
    home: const MonitorPage(),
  );
}

class Metrics {
  const Metrics({
    this.sequence = 0,
    this.snr = 0,
    this.ber = 0,
    this.noise = 0,
    this.latency = 0,
    this.version = 0,
  });
  final int sequence, version;
  final double snr, ber, noise, latency;
  factory Metrics.fromEvent(Map<String, dynamic> e) {
    final m = (e['metrics'] as Map?)?.cast<String, dynamic>() ?? const {};
    num n(String key) => (m[key] as num?) ?? 0;
    return Metrics(
      sequence: n('sequence').toInt(),
      snr: n('snr_db').toDouble(),
      ber: n('ber').toDouble(),
      noise: n('noise_variance').toDouble(),
      latency: n('latency_ms').toDouble(),
      version: n('active_config_version').toInt(),
    );
  }

  factory Metrics.fromProto(lk.ReceiverMetrics m) => Metrics(
    sequence: m.sequence.toInt(),
    snr: m.snrDb,
    ber: m.ber,
    noise: m.noiseVariance,
    latency: m.latencyMs,
    version: m.activeConfigVersion.toInt(),
  );
}

class MonitorPage extends StatefulWidget {
  const MonitorPage({super.key});
  @override
  State<MonitorPage> createState() => _MonitorPageState();
}

class _MonitorPageState extends State<MonitorPage> {
  final endpoint = TextEditingController(
    text: 'http://127.0.0.1:8080/api/v1/events',
  );
  final history = <Metrics>[];
  http.Client? client;
  StreamSubscription<String>? subscription;
  StreamSubscription<lk.ExperimentEvent>? grpcSubscription;
  lk.LiveKalmanClient? grpcClient;
  Metrics latest = const Metrics();
  String status = 'OFFLINE';
  bool get isLive => status.startsWith('LIVE');

  Future<void> connect() async {
    await disconnect();
    setState(() => status = 'CONNECTING');
    client = http.Client();
    try {
      final uri = Uri.parse(endpoint.text);
      if (uri.scheme == 'grpc') {
        client?.close();
        client = null;
        await _connectGrpc(uri);
        return;
      }
      final response = await client!.send(
        http.Request('GET', Uri.parse(endpoint.text))
          ..headers['Accept'] = 'text/event-stream',
      );
      if (response.statusCode != 200) {
        throw StateError('HTTP ${response.statusCode}');
      }
      setState(() => status = 'LIVE');
      subscription = response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .where((line) => line.startsWith('data: '))
          .listen(
            (line) {
              final event =
                  jsonDecode(line.substring(6)) as Map<String, dynamic>;
              if (event['kind'] != 'metrics') return;
              final value = Metrics.fromEvent(event);
              setState(() {
                latest = value;
                history.add(value);
                if (history.length > 80) history.removeAt(0);
              });
            },
            onError: (Object _) =>
                mounted ? setState(() => status = 'RETRY') : null,
            onDone: () => mounted ? setState(() => status = 'OFFLINE') : null,
          );
    } catch (_) {
      if (mounted) setState(() => status = 'OFFLINE');
    }
  }

  Future<void> _connectGrpc(Uri uri) async {
    int port(String name, int fallback) =>
        int.tryParse(uri.queryParameters[name] ?? '') ?? fallback;
    final controllerHost = uri.host;
    grpcClient = lk.LiveKalmanClient.insecure(
      lk.LabEndpoints(
        transmitterHost: uri.queryParameters['txHost'] ?? controllerHost,
        receiverHost: uri.queryParameters['rxHost'] ?? controllerHost,
        controllerHost: controllerHost,
        transmitterPort: port('txPort', 55051),
        receiverPort: port('rxPort', 55052),
        controllerPort: port('controllerPort', uri.hasPort ? uri.port : 55053),
      ),
    );
    await grpcClient!.discoverNodes();
    setState(() => status = 'LIVE / GRPC');
    grpcSubscription = grpcClient!.watchExperiment().listen(
      (event) {
        if (!event.hasMetrics()) return;
        final value = Metrics.fromProto(event.metrics);
        setState(() {
          latest = value;
          history.add(value);
          if (history.length > 80) history.removeAt(0);
        });
      },
      onError: (Object _) => mounted ? setState(() => status = 'RETRY') : null,
      onDone: () => mounted ? setState(() => status = 'OFFLINE') : null,
    );
  }

  Future<void> disconnect() async {
    await subscription?.cancel();
    await grpcSubscription?.cancel();
    await grpcClient?.close();
    client?.close();
    subscription = null;
    grpcSubscription = null;
    grpcClient = null;
    client = null;
  }

  @override
  void dispose() {
    disconnect();
    endpoint.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1220),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _header(),
              const SizedBox(height: 24),
              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  MetricCard(
                    label: 'SIGNAL / NOISE',
                    value: '${latest.snr.toStringAsFixed(2)} dB',
                    accent: const Color(0xff58f3c2),
                  ),
                  MetricCard(
                    label: 'BIT ERROR RATE',
                    value: latest.ber.toStringAsExponential(2),
                    accent: const Color(0xffffd166),
                  ),
                  MetricCard(
                    label: 'PIPELINE LATENCY',
                    value: '${latest.latency.toStringAsFixed(2)} ms',
                    accent: const Color(0xff7fb3ff),
                  ),
                  MetricCard(
                    label: 'KALMAN PROFILE',
                    value: 'v${latest.version}',
                    accent: const Color(0xffff7b9c),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, c) {
                  final charts = [
                    SignalChart(
                      title: 'SNR WINDOW',
                      values: history.map((m) => m.snr).toList(),
                      color: const Color(0xff58f3c2),
                    ),
                    SignalChart(
                      title: 'BER WINDOW',
                      values: history.map((m) => m.ber).toList(),
                      color: const Color(0xffffd166),
                    ),
                  ];
                  return c.maxWidth > 760
                      ? Row(
                          children: [
                            Expanded(child: charts[0]),
                            const SizedBox(width: 14),
                            Expanded(child: charts[1]),
                          ],
                        )
                      : Column(
                          children: [
                            charts[0],
                            const SizedBox(height: 14),
                            charts[1],
                          ],
                        );
                },
              ),
              const SizedBox(height: 14),
              _footer(),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _header() => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: const Color(0xff58f3c2),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.graphic_eq, color: Color(0xff071016)),
      ),
      const SizedBox(width: 14),
      const Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'STREAMING / LIVE KALMAN',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: .8,
              ),
            ),
            SizedBox(height: 3),
            Text(
              'Adaptive BPSK experiment console',
              style: TextStyle(color: Color(0xff8ba0ad)),
            ),
          ],
        ),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isLive ? const Color(0x2258f3c2) : const Color(0x22ff7b9c),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          '● $status',
          style: TextStyle(
            color: isLive ? const Color(0xff58f3c2) : const Color(0xffff7b9c),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ],
  );

  Widget _footer() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xff0d1a22),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xff1a2d38)),
    ),
    child: Row(
      children: [
        Expanded(
          child: TextField(
            controller: endpoint,
            decoration: const InputDecoration(
              labelText: 'Controller event stream',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(width: 12),
        FilledButton.icon(
          onPressed: isLive ? disconnect : connect,
          icon: Icon(isLive ? Icons.stop : Icons.play_arrow),
          label: Text(isLive ? 'STOP' : 'CONNECT'),
        ),
        const SizedBox(width: 16),
        Text(
          'FRAME ${latest.sequence.toString().padLeft(6, '0')}',
          style: const TextStyle(
            fontFamily: 'monospace',
            color: Color(0xff8ba0ad),
          ),
        ),
      ],
    ),
  );
}

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.accent,
  });
  final String label, value;
  final Color accent;
  @override
  Widget build(BuildContext context) => Container(
    width: 280,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: const Color(0xff0d1a22),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xff1a2d38)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            letterSpacing: 1.4,
            color: Color(0xff8ba0ad),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          value,
          style: TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.w700,
            color: accent,
          ),
        ),
      ],
    ),
  );
}

class SignalChart extends StatelessWidget {
  const SignalChart({
    super.key,
    required this.title,
    required this.values,
    required this.color,
  });
  final String title;
  final List<double> values;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    height: 250,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: const Color(0xff0d1a22),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xff1a2d38)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            letterSpacing: 1.4,
            color: Color(0xff8ba0ad),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: CustomPaint(
            painter: ChartPainter(values, color),
            size: Size.infinite,
          ),
        ),
      ],
    ),
  );
}

class ChartPainter extends CustomPainter {
  ChartPainter(this.values, this.color);
  final List<double> values;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = const Color(0xff1a2d38)
      ..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    if (values.length < 2) return;
    var min = values.reduce((a, b) => a < b ? a : b),
        max = values.reduce((a, b) => a > b ? a : b);
    if ((max - min).abs() < .000001) max = min + 1;
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final p = Offset(
        size.width * i / (values.length - 1),
        size.height * (1 - (values[i] - min) / (max - min)),
      );
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant ChartPainter oldDelegate) =>
      oldDelegate.values != values;
}
