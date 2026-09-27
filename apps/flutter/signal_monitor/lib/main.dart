import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:livekalman_sdk/livekalman_sdk.dart' as lk;

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = SetupPreferenceStore();
  final commandLineRole = AppRole.fromArguments(args);
  final commandLineEndpoint = endpointFromArguments(args);
  final savedSetup = await preferences.read();
  runApp(
    SignalMonitorApp(
      initialRole:
          commandLineRole ??
          (savedSetup.endpoint == null ? null : savedSetup.role),
      initialEndpoint: commandLineEndpoint ?? savedSetup.endpoint,
      setupStore: preferences,
    ),
  );
}

const defaultLabEndpoint =
    'grpc://127.0.0.1:55053?txHost=127.0.0.1&rxHost=127.0.0.1&txPort=55051&rxPort=55052&txHttpPort=8081';

const ink = Color(0xff071116);
const surface = Color(0xff0d1a21);
const surfaceHigh = Color(0xff12252e);
const line = Color(0xff20343e);
const muted = Color(0xff8fa5af);
const mint = Color(0xff58f3c2);
const amber = Color(0xffffd166);
const blue = Color(0xff74a9ff);
const rose = Color(0xffff7b9c);

class AppSetup {
  const AppSetup({this.role, this.endpoint});

  final AppRole? role;
  final String? endpoint;
}

class SetupPreferenceStore {
  Future<Directory> setupDirectory() async {
    final base =
        Platform.environment['APPDATA'] ??
        Platform.environment['HOME'] ??
        Directory.systemTemp.path;
    final directory = Directory('$base${Platform.pathSeparator}LiveKalmanLab');
    await directory.create(recursive: true);
    return directory;
  }

  Future<AppSetup> read() async {
    try {
      final directory = await setupDirectory();
      final file = File('${directory.path}${Platform.pathSeparator}setup.json');
      if (await file.exists()) {
        final json =
            jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        return AppSetup(
          role: AppRole.fromName(json['role'] as String?),
          endpoint: json['endpoint'] as String?,
        );
      }
      final legacy = File(
        '${directory.path}${Platform.pathSeparator}device-role.txt',
      );
      return AppSetup(
        role: await legacy.exists()
            ? AppRole.fromName((await legacy.readAsString()).trim())
            : null,
      );
    } on Object {
      return const AppSetup();
    }
  }

  Future<void> write(AppRole role, String endpoint) async {
    try {
      final directory = await setupDirectory();
      final file = File('${directory.path}${Platform.pathSeparator}setup.json');
      await file.writeAsString(
        jsonEncode({'role': role.name, 'endpoint': endpoint}),
        flush: true,
      );
    } on Object {
      // Setup still works for this session on read-only systems.
    }
  }
}

String? endpointFromArguments(List<String> arguments) {
  for (var index = 0; index < arguments.length; index++) {
    final argument = arguments[index];
    if (argument.startsWith('--endpoint=')) {
      return argument.substring('--endpoint='.length);
    }
    if (argument.startsWith('--api=')) {
      return argument.substring('--api='.length);
    }
    if ((argument == '--endpoint' || argument == '--api') &&
        index + 1 < arguments.length) {
      return arguments[index + 1];
    }
  }
  return null;
}

enum AppRole {
  sender,
  receiver,
  controller;

  static AppRole? fromName(String? value) {
    for (final role in values) {
      if (role.name == value?.toLowerCase()) return role;
    }
    return null;
  }

  static AppRole? fromArguments(List<String> arguments) {
    for (var index = 0; index < arguments.length; index++) {
      final argument = arguments[index];
      if (argument.startsWith('--role=')) {
        return fromName(argument.substring('--role='.length));
      }
      if (argument == '--role' && index + 1 < arguments.length) {
        return fromName(arguments[index + 1]);
      }
    }
    return null;
  }

  String get label => switch (this) {
    AppRole.sender => 'Sender',
    AppRole.receiver => 'Receiver',
    AppRole.controller => 'Controller',
  };
}

Color roleColor(AppRole role) => switch (role) {
  AppRole.sender => blue,
  AppRole.receiver => mint,
  AppRole.controller => rose,
};

IconData roleIcon(AppRole role) => switch (role) {
  AppRole.sender => Icons.waves_rounded,
  AppRole.receiver => Icons.filter_alt_rounded,
  AppRole.controller => Icons.tune_rounded,
};

class SignalMonitorApp extends StatefulWidget {
  const SignalMonitorApp({
    super.key,
    this.initialRole,
    this.initialEndpoint,
    this.setupStore,
  });

  final AppRole? initialRole;
  final String? initialEndpoint;
  final SetupPreferenceStore? setupStore;

  @override
  State<SignalMonitorApp> createState() => _SignalMonitorAppState();
}

class _SignalMonitorAppState extends State<SignalMonitorApp> {
  AppRole? role;
  late String endpoint;

  @override
  void initState() {
    super.initState();
    role = widget.initialRole;
    endpoint = widget.initialEndpoint ?? defaultLabEndpoint;
  }

  Future<void> selectRole(AppRole selected) async {
    await widget.setupStore?.write(selected, endpoint);
    if (mounted) setState(() => role = selected);
  }

  Future<void> saveSetup(AppRole selected, String selectedEndpoint) async {
    endpoint = selectedEndpoint;
    await widget.setupStore?.write(selected, endpoint);
    if (mounted) setState(() => role = selected);
  }

  Future<void> saveEndpoint(String selectedEndpoint) async {
    endpoint = selectedEndpoint;
    if (role != null) await widget.setupStore?.write(role!, endpoint);
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Live Kalman Lab',
    theme: ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: ink,
      colorScheme: ColorScheme.fromSeed(
        seedColor: mint,
        brightness: Brightness.dark,
        surface: surface,
      ),
      textTheme: ThemeData.dark().textTheme.apply(
        bodyColor: const Color(0xffe7f1f4),
        displayColor: const Color(0xfff4fbfc),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ink.withValues(alpha: .55),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: line),
        ),
      ),
      useMaterial3: true,
    ),
    home: role == null
        ? RoleSelectionPage(initialEndpoint: endpoint, onCompleted: saveSetup)
        : MonitorPage(
            key: ValueKey(role),
            role: role!,
            onChangeRole: selectRole,
            initialEndpoint: endpoint,
            onEndpointChanged: saveEndpoint,
          ),
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

  factory Metrics.fromEvent(Map<String, dynamic> event) {
    final values =
        (event['metrics'] as Map?)?.cast<String, dynamic>() ?? const {};
    num number(String key) => (values[key] as num?) ?? 0;
    return Metrics(
      sequence: number('sequence').toInt(),
      snr: number('snr_db').toDouble(),
      ber: number('ber').toDouble(),
      noise: number('noise_variance').toDouble(),
      latency: number('latency_ms').toDouble(),
      version: number('active_config_version').toInt(),
    );
  }

  factory Metrics.fromProto(lk.ReceiverMetrics metrics) => Metrics(
    sequence: metrics.sequence.toInt(),
    snr: metrics.snrDb,
    ber: metrics.ber,
    noise: metrics.noiseVariance,
    latency: metrics.latencyMs,
    version: metrics.activeConfigVersion.toInt(),
  );
}

class MediaActivity {
  const MediaActivity({
    required this.id,
    required this.name,
    required this.kind,
    required this.contentType,
    required this.received,
    required this.total,
    required this.complete,
    required this.checksumValid,
    required this.preview,
  });

  final String id, name, kind, contentType, preview;
  final int received, total;
  final bool complete, checksumValid;

  factory MediaActivity.fromProto(lk.MediaEvent event) {
    final media = event.media;
    var preview = '';
    if (event.detectedType == lk.MediaType.MEDIA_TYPE_TEXT &&
        event.data.isNotEmpty) {
      preview = utf8.decode(event.data, allowMalformed: true).trim();
      if (preview.length > 72) preview = '${preview.substring(0, 72)}…';
    }
    return MediaActivity(
      id: media.transferId,
      name: media.fileName.isEmpty ? media.transferId : media.fileName,
      kind: mediaLabel(event.detectedType),
      contentType: event.detectedContentType,
      received: event.receivedSize.toInt(),
      total: media.totalSize.toInt(),
      complete: event.endOfStream,
      checksumValid: event.checksumValid,
      preview: preview,
    );
  }
}

String mediaLabel(lk.MediaType type) => switch (type) {
  lk.MediaType.MEDIA_TYPE_TEXT => 'TEXT',
  lk.MediaType.MEDIA_TYPE_IMAGE => 'IMAGE',
  lk.MediaType.MEDIA_TYPE_AUDIO => 'AUDIO',
  lk.MediaType.MEDIA_TYPE_BINARY => 'BINARY',
  _ => 'DETECTING',
};

class TransferStatus {
  const TransferStatus({
    required this.id,
    required this.name,
    required this.mediaType,
    required this.encoding,
    required this.totalBytes,
    required this.sentBytes,
    required this.state,
    required this.estimatedSeconds,
  });

  final String id, name, mediaType, encoding, state;
  final int totalBytes, sentBytes;
  final double estimatedSeconds;

  double get progress =>
      totalBytes <= 0 ? 0 : (sentBytes / totalBytes).clamp(0, 1).toDouble();

  factory TransferStatus.fromJson(Map<String, dynamic> json) {
    num number(String key) => (json[key] as num?) ?? 0;
    return TransferStatus(
      id: json['transferId'] as String? ?? '',
      name: json['fileName'] as String? ?? 'unnamed transfer',
      mediaType: json['mediaType'] as String? ?? 'binary',
      encoding: json['encoding'] as String? ?? 'raw',
      totalBytes: number('totalBytes').toInt(),
      sentBytes: number('sentBytes').toInt(),
      state: json['state'] as String? ?? 'unknown',
      estimatedSeconds: number('estimatedSeconds').toDouble(),
    );
  }
}

Uri senderTransferUri(String labEndpoint) {
  final lab = Uri.parse(labEndpoint);
  final host = lab.queryParameters['txHost'] ?? lab.host;
  final port = int.tryParse(lab.queryParameters['txHttpPort'] ?? '') ?? 8081;
  return Uri(scheme: 'http', host: host, port: port, path: '/api/v1/transfers');
}

String localFileName(String path) {
  final parts = path.replaceAll('\\', '/').split('/');
  return parts.isEmpty ? path : parts.last;
}

String contentTypeForFile(String name) {
  final extension = name.toLowerCase().split('.').last;
  return switch (extension) {
    'txt' || 'csv' || 'md' => 'text/plain',
    'json' => 'application/json',
    'bmp' => 'image/bmp',
    'png' => 'image/png',
    'jpg' || 'jpeg' => 'image/jpeg',
    'wav' => 'audio/wav',
    _ => 'application/octet-stream',
  };
}

class RoleSelectionPage extends StatefulWidget {
  const RoleSelectionPage({
    super.key,
    required this.initialEndpoint,
    required this.onCompleted,
  });

  final String initialEndpoint;
  final void Function(AppRole role, String endpoint) onCompleted;

  @override
  State<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends State<RoleSelectionPage> {
  AppRole? selectedRole;
  late final TextEditingController endpoint;
  String? error;

  @override
  void initState() {
    super.initState();
    endpoint = TextEditingController(text: widget.initialEndpoint);
  }

  @override
  void dispose() {
    endpoint.dispose();
    super.dispose();
  }

  void continueToWorkspace() {
    final value = endpoint.text.trim();
    final uri = Uri.tryParse(value);
    if (selectedRole == null) {
      setState(() => error = 'Select which role this device will run.');
      return;
    }
    if (uri == null ||
        !{'grpc', 'http', 'https'}.contains(uri.scheme) ||
        uri.host.isEmpty) {
      setState(() => error = 'Enter a valid grpc:// or http(s):// server API.');
      return;
    }
    widget.onCompleted(selectedRole!, value);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -1),
          radius: 1.2,
          colors: [Color(0xff153a36), ink],
          stops: [0, .58],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                children: [
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [mint, blue]),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(color: Color(0x5558f3c2), blurRadius: 32),
                      ],
                    ),
                    child: const Icon(Icons.graphic_eq, color: ink, size: 34),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'CHOOSE THIS DEVICE ROLE',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .7,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'The same Flutter application runs on all three laptops. Select the workspace this device should open.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: muted, fontSize: 15),
                  ),
                  const SizedBox(height: 30),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final cards = [
                        RoleChoiceCard(
                          role: AppRole.sender,
                          selected: selectedRole == AppRole.sender,
                          laptop: 'LAPTOP 01',
                          description:
                              'Configure BPSK generation, inspect the signal preview and monitor transmission.',
                          icon: Icons.waves_rounded,
                          color: blue,
                          onTap: (role) => setState(() {
                            selectedRole = role;
                            error = null;
                          }),
                        ),
                        RoleChoiceCard(
                          role: AppRole.receiver,
                          selected: selectedRole == AppRole.receiver,
                          laptop: 'LAPTOP 02',
                          description:
                              'Inspect Kalman filtering, BER/SNR, latency and reconstructed media.',
                          icon: Icons.filter_alt_rounded,
                          color: mint,
                          onTap: (role) => setState(() {
                            selectedRole = role;
                            error = null;
                          }),
                        ),
                        RoleChoiceCard(
                          role: AppRole.controller,
                          selected: selectedRole == AppRole.controller,
                          laptop: 'LAPTOP 03',
                          description:
                              'Observe the complete topology, adaptation policy and experiment events.',
                          icon: Icons.tune_rounded,
                          color: rose,
                          onTap: (role) => setState(() {
                            selectedRole = role;
                            error = null;
                          }),
                        ),
                      ];
                      if (constraints.maxWidth >= 820) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: cards
                              .map(
                                (card) => Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                    ),
                                    child: card,
                                  ),
                                ),
                              )
                              .toList(),
                        );
                      }
                      return Column(
                        children: cards
                            .map(
                              (card) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: card,
                              ),
                            )
                            .toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  AppPanel(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const PanelTitle(
                          icon: Icons.hub_rounded,
                          title: 'SERVER API / LAB ENDPOINT',
                          color: mint,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Enter the controller address. Sender and receiver service addresses can be included as query parameters.',
                          style: TextStyle(color: muted, fontSize: 12),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          key: const Key('setup-endpoint'),
                          controller: endpoint,
                          autocorrect: false,
                          onSubmitted: (_) => continueToWorkspace(),
                          decoration: const InputDecoration(
                            labelText: 'Server API',
                            prefixIcon: Icon(Icons.dns_rounded),
                            hintText: 'grpc://192.168.1.30:55053',
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Example: grpc://192.168.1.30:55053?txHost=192.168.1.10&rxHost=192.168.1.20&txHttpPort=8081',
                          style: TextStyle(color: muted, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 12),
                    Text(error!, style: const TextStyle(color: rose)),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      key: const Key('complete-setup'),
                      onPressed: continueToWorkspace,
                      icon: const Icon(Icons.rocket_launch_rounded),
                      label: Text(
                        selectedRole == null
                            ? 'SELECT A DEVICE ROLE'
                            : 'SAVE SETUP & OPEN ${selectedRole!.label.toUpperCase()}',
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Role and endpoint are remembered on this device. Both can be changed later.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: muted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class RoleChoiceCard extends StatelessWidget {
  const RoleChoiceCard({
    super.key,
    required this.role,
    required this.selected,
    required this.laptop,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final AppRole role;
  final bool selected;
  final String laptop, description;
  final IconData icon;
  final Color color;
  final ValueChanged<AppRole> onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => onTap(role),
    borderRadius: BorderRadius.circular(24),
    child: Ink(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: surface.withValues(alpha: .96),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: color.withValues(alpha: selected ? .95 : .34),
          width: selected ? 2 : 1,
        ),
        boxShadow: selected
            ? [BoxShadow(color: color.withValues(alpha: .16), blurRadius: 28)]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Icon(icon, color: color, size: 29),
          ),
          const SizedBox(height: 17),
          Text(
            laptop,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            role.label,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(color: muted, height: 1.45),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                selected ? 'SELECTED' : 'RUN AS ${role.label.toUpperCase()}',
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                selected ? Icons.check_circle_rounded : Icons.touch_app_rounded,
                color: color,
                size: 17,
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class MonitorPage extends StatefulWidget {
  const MonitorPage({
    super.key,
    required this.role,
    required this.onChangeRole,
    required this.initialEndpoint,
    required this.onEndpointChanged,
  });

  final AppRole role;
  final ValueChanged<AppRole> onChangeRole;
  final String initialEndpoint;
  final ValueChanged<String> onEndpointChanged;

  @override
  State<MonitorPage> createState() => _MonitorPageState();
}

class _MonitorPageState extends State<MonitorPage> {
  late final TextEditingController endpoint;
  final transferPath = TextEditingController();
  final history = <Metrics>[];
  final media = <MediaActivity>[];
  http.Client? httpClient;
  StreamSubscription<String>? sseSubscription;
  StreamSubscription<lk.ExperimentEvent>? experimentSubscription;
  StreamSubscription<lk.MediaEvent>? mediaSubscription;
  lk.LiveKalmanClient? grpcClient;
  Timer? statusTimer;
  Timer? transferTimer;
  List<lk.NodeInfo> nodeInfo = const [];
  List<lk.NodeStatus> nodeStatus = const [];
  Metrics latest = const Metrics();
  String connectionState = 'OFFLINE';
  String connectionDetail = 'Connect to begin a live experiment';
  bool polling = false;
  double senderAmplitude = 1;
  double senderNoise = .7;
  double senderSymbolRate = 6000;
  bool applyingSenderConfig = false;
  bool uploadingFile = false;
  bool pollingTransfers = false;
  String transferEncoding = 'raw';
  double transferShiftKey = 7;
  TransferStatus? activeTransfer;
  List<TransferStatus> queuedTransfers = const [];
  List<TransferStatus> recentTransfers = const [];
  double transferBytesPerSecond = 0;
  int maxTransferBytes = 1024 * 1024;
  String transferMessage = 'Connect to load the sender transfer queue.';
  final experimentLog = <String>[];
  final qHistory = <double>[];
  final rHistory = <double>[];

  bool get isLive => connectionState.startsWith('LIVE');

  @override
  void initState() {
    super.initState();
    endpoint = TextEditingController(text: widget.initialEndpoint);
  }

  Future<void> connect() async {
    await disconnect(notify: false);
    if (!mounted) return;
    setState(() {
      connectionState = 'CONNECTING';
      connectionDetail = 'Discovering lab services…';
    });
    try {
      final endpointValue = endpoint.text.trim();
      final uri = Uri.parse(endpointValue);
      widget.onEndpointChanged(endpointValue);
      if (uri.scheme == 'grpc') {
        await connectGrpc(uri);
      } else {
        await connectSse(uri);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        connectionState = 'OFFLINE';
        connectionDetail = friendlyError(error);
      });
    }
  }

  Future<void> connectSse(Uri uri) async {
    httpClient = http.Client();
    final response = await httpClient!.send(
      http.Request('GET', uri)..headers['Accept'] = 'text/event-stream',
    );
    if (response.statusCode != 200) {
      throw StateError('Controller returned HTTP ${response.statusCode}');
    }
    if (!mounted) return;
    setState(() {
      connectionState = 'LIVE / SSE';
      connectionDetail = 'Controller metrics stream connected';
    });
    sseSubscription = response.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .where((entry) => entry.startsWith('data: '))
        .listen(
          (entry) {
            final event =
                jsonDecode(entry.substring(6)) as Map<String, dynamic>;
            if (event['kind'] == 'metrics') {
              recordMetrics(Metrics.fromEvent(event));
            }
          },
          onError: (Object error) => streamEnded(error),
          onDone: () => streamEnded(null),
        );
  }

  Future<void> connectGrpc(Uri uri) async {
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
    final discovered = await grpcClient!.discoverNodes();
    final statuses = await grpcClient!.nodeStatuses();
    if (!mounted) return;
    setState(() {
      nodeInfo = discovered;
      nodeStatus = statuses;
      connectionState = 'LIVE / GRPC';
      connectionDetail = 'All three services discovered';
    });
    experimentSubscription = grpcClient!.watchExperiment().listen(
      (event) {
        recordExperimentEvent(event);
        if (event.hasMetrics()) {
          recordMetrics(Metrics.fromProto(event.metrics));
        }
      },
      onError: (Object error) => streamEnded(error),
      onDone: () => streamEnded(null),
    );
    mediaSubscription = grpcClient!.watchMedia().listen(
      recordMedia,
      onError: (Object error) {
        if (mounted) {
          setState(() {
            connectionDetail = 'Media stream: ${friendlyError(error)}';
          });
        }
      },
    );
    statusTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => refreshNodeStatus(),
    );
    if (widget.role == AppRole.sender) {
      await refreshTransfers(uri);
      transferTimer = Timer.periodic(
        const Duration(seconds: 1),
        (_) => refreshTransfers(uri),
      );
    }
  }

  Future<void> refreshNodeStatus() async {
    if (grpcClient == null || polling) return;
    polling = true;
    try {
      final statuses = await grpcClient!.nodeStatuses();
      if (mounted) setState(() => nodeStatus = statuses);
    } catch (_) {
      // Experiment and media streams own the primary connection state.
    } finally {
      polling = false;
    }
  }

  Future<void> refreshTransfers([Uri? labUri]) async {
    if (pollingTransfers || widget.role != AppRole.sender) return;
    pollingTransfers = true;
    try {
      final api = senderTransferUri(labUri?.toString() ?? endpoint.text.trim());
      final response = await http.get(api).timeout(const Duration(seconds: 3));
      if (response.statusCode != 200) {
        throw StateError('Sender API returned HTTP ${response.statusCode}');
      }
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      TransferStatus? transfer(dynamic value) => value is Map
          ? TransferStatus.fromJson(value.cast<String, dynamic>())
          : null;
      List<TransferStatus> transfers(dynamic value) => value is List
          ? value.map(transfer).whereType<TransferStatus>().toList()
          : const [];
      if (!mounted) return;
      setState(() {
        activeTransfer = transfer(payload['active']);
        queuedTransfers = transfers(payload['queued']);
        recentTransfers = transfers(payload['recent']);
        transferBytesPerSecond =
            (payload['bytesPerSecond'] as num?)?.toDouble() ?? 0;
        maxTransferBytes =
            (payload['maxTransferBytes'] as num?)?.toInt() ?? 1024 * 1024;
        transferMessage = activeTransfer == null && queuedTransfers.isEmpty
            ? 'Sender is ready for text, image, audio or binary files.'
            : 'Transfer queue is live.';
      });
    } catch (error) {
      if (mounted) {
        setState(() => transferMessage = friendlyError(error));
      }
    } finally {
      pollingTransfers = false;
    }
  }

  Future<void> uploadTransfer() async {
    if (uploadingFile) return;
    setState(() => uploadingFile = true);
    try {
      final path = transferPath.text.trim().replaceAll('"', '');
      if (path.isEmpty) throw StateError('Enter the full path of a file.');
      final file = File(path);
      if (!await file.exists()) throw StateError('File does not exist: $path');
      final size = await file.length();
      if (size == 0) throw StateError('The selected file is empty.');
      if (size > maxTransferBytes) {
        throw StateError(
          'File is ${formatBytes(size)}; maximum is ${formatBytes(maxTransferBytes)}.',
        );
      }
      final name = localFileName(path);
      final query = <String, String>{
        'name': name,
        'encoding': transferEncoding,
        if (transferEncoding == 'byte_shift')
          'key': transferShiftKey.round().toString(),
      };
      final api = senderTransferUri(
        endpoint.text.trim(),
      ).replace(queryParameters: query);
      final response = await http
          .post(
            api,
            headers: {'Content-Type': contentTypeForFile(name)},
            body: await file.readAsBytes(),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 202) {
        throw StateError(
          'Upload failed: HTTP ${response.statusCode} ${response.body}',
        );
      }
      if (!mounted) return;
      setState(() => transferMessage = '$name was added to the BPSK queue.');
      await refreshTransfers();
    } catch (error) {
      if (mounted) setState(() => transferMessage = friendlyError(error));
    } finally {
      if (mounted) setState(() => uploadingFile = false);
    }
  }

  void recordMetrics(Metrics value) {
    if (!mounted) return;
    setState(() {
      latest = value;
      history.add(value);
      if (history.length > 96) history.removeAt(0);
    });
  }

  void recordExperimentEvent(lk.ExperimentEvent event) {
    if (!mounted) return;
    setState(() {
      final description = event.description.isEmpty
          ? event.kind
          : event.description;
      if (description.isNotEmpty) {
        experimentLog.insert(0, description);
        if (experimentLog.length > 12) experimentLog.removeLast();
      }
      if (event.hasDecision()) {
        qHistory.add(event.decision.proposedKalmanQ);
        rHistory.add(event.decision.proposedKalmanR);
        if (qHistory.length > 64) qHistory.removeAt(0);
        if (rHistory.length > 64) rHistory.removeAt(0);
      }
    });
  }

  Future<void> applySenderConfiguration() async {
    if (grpcClient == null || applyingSenderConfig) return;
    setState(() => applyingSenderConfig = true);
    try {
      final sender = at(nodeStatus, 0);
      final version = (sender?.activeConfigVersion.toInt() ?? 0) + 1;
      final sequence = (sender?.lastSequence.toInt() ?? 0) + 2;
      final reply = await grpcClient!.transmitter.applyTransmitterConfig(
        lk.TxConfig(
          commandId: Int64(DateTime.now().millisecondsSinceEpoch),
          version: Int64(version),
          effectiveSequence: Int64(sequence),
          symbolRate: senderSymbolRate.round(),
          amplitude: senderAmplitude,
          noiseStddev: senderNoise,
        ),
      );
      if (!mounted) return;
      setState(() {
        connectionDetail = reply.accepted
            ? 'Sender configuration queued for frame $sequence'
            : 'Sender rejected configuration: ${reply.reason}';
      });
    } catch (error) {
      if (mounted) {
        setState(() => connectionDetail = friendlyError(error));
      }
    } finally {
      if (mounted) setState(() => applyingSenderConfig = false);
    }
  }

  void recordMedia(lk.MediaEvent event) {
    if (!mounted) return;
    final item = MediaActivity.fromProto(event);
    setState(() {
      media.removeWhere((entry) => entry.id == item.id);
      media.insert(0, item);
      if (media.length > 8) media.removeLast();
    });
  }

  void streamEnded(Object? error) {
    if (!mounted) return;
    setState(() {
      connectionState = error == null ? 'OFFLINE' : 'RETRY';
      connectionDetail = error == null
          ? 'The remote stream closed'
          : friendlyError(error);
    });
  }

  Future<void> disconnect({bool notify = true}) async {
    statusTimer?.cancel();
    statusTimer = null;
    transferTimer?.cancel();
    transferTimer = null;
    await sseSubscription?.cancel();
    await experimentSubscription?.cancel();
    await mediaSubscription?.cancel();
    await grpcClient?.close();
    httpClient?.close();
    sseSubscription = null;
    experimentSubscription = null;
    mediaSubscription = null;
    grpcClient = null;
    httpClient = null;
    polling = false;
    if (notify && mounted) {
      setState(() {
        connectionState = 'OFFLINE';
        connectionDetail = 'Disconnected by operator';
        nodeInfo = const [];
        nodeStatus = const [];
      });
    }
  }

  @override
  void dispose() {
    unawaited(disconnect(notify: false));
    endpoint.dispose();
    transferPath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(-.85, -.95),
          radius: 1.35,
          colors: [Color(0xff12322e), ink],
          stops: [0, .52],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1420),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
              children: [
                header(),
                const SizedBox(height: 22),
                ...roleSections(),
                const SizedBox(height: 18),
                connectionPanel(),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  List<Widget> roleSections() => switch (widget.role) {
    AppRole.sender => [
      RoleHero(
        eyebrow: 'LAPTOP 01 / TRANSMITTER',
        title: 'BPSK Signal Generator',
        description:
            'Configure the source and monitor sample delivery to the receiver.',
        icon: Icons.waves_rounded,
        color: blue,
        status: at(nodeStatus, 0),
      ),
      const SizedBox(height: 16),
      SenderWorkspace(
        amplitude: senderAmplitude,
        noise: senderNoise,
        symbolRate: senderSymbolRate,
        connected: grpcClient != null,
        applying: applyingSenderConfig,
        status: at(nodeStatus, 0),
        onAmplitudeChanged: (value) => setState(() => senderAmplitude = value),
        onNoiseChanged: (value) => setState(() => senderNoise = value),
        onSymbolRateChanged: (value) =>
            setState(() => senderSymbolRate = value),
        onApply: applySenderConfiguration,
      ),
      const SizedBox(height: 16),
      FileTransferPanel(
        pathController: transferPath,
        connected: grpcClient != null,
        uploading: uploadingFile,
        encoding: transferEncoding,
        shiftKey: transferShiftKey,
        active: activeTransfer,
        queued: queuedTransfers,
        recent: recentTransfers,
        bytesPerSecond: transferBytesPerSecond,
        maxBytes: maxTransferBytes,
        message: transferMessage,
        onEncodingChanged: (value) => setState(() => transferEncoding = value),
        onShiftKeyChanged: (value) => setState(() => transferShiftKey = value),
        onUpload: uploadTransfer,
        onRefresh: () => refreshTransfers(),
      ),
    ],
    AppRole.receiver => [
      RoleHero(
        eyebrow: 'LAPTOP 02 / RECEIVER',
        title: 'Adaptive Kalman Receiver',
        description:
            'Demodulate BPSK, measure signal quality and reconstruct media.',
        icon: Icons.filter_alt_rounded,
        color: mint,
        status: at(nodeStatus, 1),
      ),
      const SizedBox(height: 22),
      const SectionHeading(
        eyebrow: 'LIVE TELEMETRY',
        title: 'Receiver signal quality',
        description: 'Measurements from the active DSP pipeline.',
      ),
      const SizedBox(height: 12),
      metricsGrid(),
      const SizedBox(height: 14),
      charts(),
      const SizedBox(height: 20),
      lowerPanels(),
    ],
    AppRole.controller => [
      RoleHero(
        eyebrow: 'LAPTOP 03 / CONTROLLER',
        title: 'Adaptive Experiment Control',
        description:
            'Observe all nodes, policy decisions and configuration changes.',
        icon: Icons.tune_rounded,
        color: rose,
        status: at(nodeStatus, 2),
      ),
      const SizedBox(height: 22),
      const SectionHeading(
        eyebrow: 'SYSTEM TOPOLOGY',
        title: 'Three-device signal path',
        description: 'Independent services with one control plane.',
      ),
      const SizedBox(height: 12),
      deviceTopology(),
      const SizedBox(height: 22),
      ControllerWorkspace(
        latest: latest,
        snrHistory: history.map((item) => item.snr).toList(),
        berHistory: history.map((item) => item.ber).toList(),
        qHistory: qHistory,
        rHistory: rHistory,
        events: experimentLog,
      ),
    ],
  };

  Widget header() => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 680;
      final identity = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [mint, blue]),
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [
                BoxShadow(color: Color(0x4458f3c2), blurRadius: 24),
              ],
            ),
            child: const Icon(Icons.graphic_eq, color: ink, size: 27),
          ),
          const SizedBox(width: 14),
          const Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'STREAMING / LIVE KALMAN',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .7,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Adaptive signal operations console',
                  style: TextStyle(color: muted, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      );
      final actions = Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          PopupMenuButton<AppRole>(
            tooltip: 'Switch device role',
            onSelected: widget.onChangeRole,
            itemBuilder: (context) => AppRole.values
                .map(
                  (role) => PopupMenuItem(
                    value: role,
                    child: Row(
                      children: [
                        Icon(roleIcon(role), size: 18),
                        const SizedBox(width: 9),
                        Text('Run as ${role.label}'),
                      ],
                    ),
                  ),
                )
                .toList(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
              decoration: BoxDecoration(
                color: roleColor(widget.role).withValues(alpha: .09),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(
                  color: roleColor(widget.role).withValues(alpha: .25),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    roleIcon(widget.role),
                    size: 15,
                    color: roleColor(widget.role),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    widget.role.label.toUpperCase(),
                    style: TextStyle(
                      color: roleColor(widget.role),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          StatusPill(label: connectionState, live: isLive),
          FilledButton.icon(
            onPressed: isLive ? () => disconnect() : connect,
            style: FilledButton.styleFrom(
              backgroundColor: isLive ? surfaceHigh : mint,
              foregroundColor: isLive ? rose : ink,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            ),
            icon: Icon(isLive ? Icons.stop_rounded : Icons.bolt_rounded),
            label: Text(isLive ? 'DISCONNECT' : 'CONNECT LAB'),
          ),
        ],
      );
      return compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [identity, const SizedBox(height: 16), actions],
            )
          : Row(
              children: [
                Expanded(child: identity),
                actions,
              ],
            );
    },
  );

  Widget deviceTopology() => LayoutBuilder(
    builder: (context, constraints) {
      final cards = [
        DeviceCard(
          laptop: 'LAPTOP 01',
          title: 'Sender',
          subtitle: 'Signal source',
          icon: Icons.waves_rounded,
          accent: blue,
          info: at(nodeInfo, 0),
          status: at(nodeStatus, 0),
          fallbackCapabilities: const ['BPSK', 'AWGN', 'FRAME STREAM'],
        ),
        DeviceCard(
          laptop: 'LAPTOP 02',
          title: 'Receiver',
          subtitle: 'Kalman + media DSP',
          icon: Icons.filter_alt_rounded,
          accent: mint,
          info: at(nodeInfo, 1),
          status: at(nodeStatus, 1),
          fallbackCapabilities: const ['DEMODULATE', 'AUTO DETECT', 'MEDIA'],
        ),
        DeviceCard(
          laptop: 'LAPTOP 03',
          title: 'Controller',
          subtitle: 'Adaptive policy',
          icon: Icons.tune_rounded,
          accent: rose,
          info: at(nodeInfo, 2),
          status: at(nodeStatus, 2),
          fallbackCapabilities: const ['Q/R POLICY', 'EVENTS', 'STATUS'],
        ),
      ];
      if (constraints.maxWidth >= 960) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: cards[0]),
            const FlowArrow(label: 'SAMPLES'),
            Expanded(child: cards[1]),
            const FlowArrow(label: 'METRICS'),
            Expanded(child: cards[2]),
          ],
        );
      }
      return Column(
        children: [
          cards[0],
          const FlowArrow(label: 'SAMPLES', vertical: true),
          cards[1],
          const FlowArrow(label: 'METRICS', vertical: true),
          cards[2],
        ],
      );
    },
  );

  T? at<T>(List<T> values, int index) =>
      index < values.length ? values[index] : null;

  Widget metricsGrid() => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;
      final columns = width >= 1050 ? 5 : (width >= 620 ? 3 : 2);
      final tileWidth = (width - (columns - 1) * 12) / columns;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          MetricCard(
            width: tileWidth,
            label: 'SIGNAL / NOISE',
            value: '${latest.snr.toStringAsFixed(2)} dB',
            icon: Icons.network_check_rounded,
            accent: mint,
          ),
          MetricCard(
            width: tileWidth,
            label: 'BIT ERROR RATE',
            value: latest.ber.toStringAsExponential(2),
            icon: Icons.rule_rounded,
            accent: amber,
          ),
          MetricCard(
            width: tileWidth,
            label: 'NOISE VARIANCE',
            value: latest.noise.toStringAsFixed(4),
            icon: Icons.blur_on_rounded,
            accent: blue,
          ),
          MetricCard(
            width: tileWidth,
            label: 'PIPELINE LATENCY',
            value: '${latest.latency.toStringAsFixed(2)} ms',
            icon: Icons.speed_rounded,
            accent: rose,
          ),
          MetricCard(
            width: tileWidth,
            label: 'KALMAN PROFILE',
            value: 'v${latest.version}',
            icon: Icons.auto_graph_rounded,
            accent: const Color(0xffb68cff),
          ),
        ],
      );
    },
  );

  Widget charts() => LayoutBuilder(
    builder: (context, constraints) {
      final chartWidgets = [
        SignalChart(
          title: 'SNR WINDOW',
          valueLabel: '${latest.snr.toStringAsFixed(1)} dB',
          values: history.map((item) => item.snr).toList(),
          color: mint,
        ),
        SignalChart(
          title: 'BER WINDOW',
          valueLabel: latest.ber.toStringAsExponential(1),
          values: history.map((item) => item.ber).toList(),
          color: amber,
        ),
      ];
      return constraints.maxWidth >= 760
          ? Row(
              children: [
                Expanded(child: chartWidgets[0]),
                const SizedBox(width: 14),
                Expanded(child: chartWidgets[1]),
              ],
            )
          : Column(
              children: [
                chartWidgets[0],
                const SizedBox(height: 14),
                chartWidgets[1],
              ],
            );
    },
  );

  Widget lowerPanels() => LayoutBuilder(
    builder: (context, constraints) {
      final mediaPanel = MediaPanel(items: media);
      final runPanel = RunPanel(
        sequence: latest.sequence,
        version: latest.version,
        connectionDetail: connectionDetail,
        receiverStatus: at(nodeStatus, 1),
      );
      return constraints.maxWidth >= 860
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: mediaPanel),
                const SizedBox(width: 14),
                Expanded(flex: 2, child: runPanel),
              ],
            )
          : Column(
              children: [mediaPanel, const SizedBox(height: 14), runPanel],
            );
    },
  );

  Widget connectionPanel() => AppPanel(
    padding: const EdgeInsets.all(16),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final field = TextField(
          controller: endpoint,
          decoration: const InputDecoration(
            labelText: 'Lab endpoint',
            hintText: 'grpc://controller:55053?txHost=…&rxHost=…',
            prefixIcon: Icon(Icons.lan_rounded),
            isDense: true,
          ),
          onSubmitted: (_) => connect(),
        );
        final frame = Text(
          'FRAME ${latest.sequence.toString().padLeft(8, '0')}',
          style: const TextStyle(
            fontFamily: 'monospace',
            color: muted,
            fontWeight: FontWeight.w700,
          ),
        );
        if (constraints.maxWidth < 720) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [field, const SizedBox(height: 12), frame],
          );
        }
        return Row(
          children: [
            Expanded(child: field),
            const SizedBox(width: 18),
            frame,
          ],
        );
      },
    ),
  );
}

class RoleHero extends StatelessWidget {
  const RoleHero({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.status,
  });

  final String eyebrow, title, description;
  final IconData icon;
  final Color color;
  final lk.NodeStatus? status;

  @override
  Widget build(BuildContext context) => AppPanel(
    padding: const EdgeInsets.all(20),
    child: Row(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: color.withValues(alpha: .28)),
          ),
          child: Icon(icon, color: color, size: 29),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(description, style: const TextStyle(color: muted)),
            ],
          ),
        ),
        if (status != null)
          TinyChip(
            label: status!.active ? 'RUNNING' : 'READY',
            color: status!.health == lk.HealthState.HEALTH_STATE_READY
                ? mint
                : rose,
          ),
      ],
    ),
  );
}

class SenderWorkspace extends StatelessWidget {
  const SenderWorkspace({
    super.key,
    required this.amplitude,
    required this.noise,
    required this.symbolRate,
    required this.connected,
    required this.applying,
    required this.status,
    required this.onAmplitudeChanged,
    required this.onNoiseChanged,
    required this.onSymbolRateChanged,
    required this.onApply,
  });

  final double amplitude, noise, symbolRate;
  final bool connected, applying;
  final lk.NodeStatus? status;
  final ValueChanged<double> onAmplitudeChanged;
  final ValueChanged<double> onNoiseChanged;
  final ValueChanged<double> onSymbolRateChanged;
  final VoidCallback onApply;

  List<double> get preview => List.generate(96, (index) {
    final bit = ((index ~/ 8) % 5 == 1 || (index ~/ 8) % 5 == 2) ? 1.0 : -1.0;
    return bit * amplitude + math.sin(index * 2.17) * noise * .22;
  });

  @override
  Widget build(BuildContext context) {
    final controls = AppPanel(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PanelTitle(
            icon: Icons.settings_input_antenna_rounded,
            title: 'SIGNAL CONFIGURATION',
            color: blue,
          ),
          const SizedBox(height: 18),
          const ConfigValue(label: 'MODULATION', value: 'BPSK'),
          ConfigSlider(
            label: 'SYMBOL RATE',
            value: symbolRate,
            min: 1000,
            max: 12000,
            divisions: 11,
            valueText: '${symbolRate.round()} baud',
            color: blue,
            onChanged: onSymbolRateChanged,
          ),
          ConfigSlider(
            label: 'AMPLITUDE',
            value: amplitude,
            min: .2,
            max: 2,
            divisions: 18,
            valueText: amplitude.toStringAsFixed(1),
            color: mint,
            onChanged: onAmplitudeChanged,
          ),
          ConfigSlider(
            label: 'AWGN / NOISE',
            value: noise,
            min: 0,
            max: 2,
            divisions: 20,
            valueText: noise.toStringAsFixed(2),
            color: amber,
            onChanged: onNoiseChanged,
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: connected && !applying ? onApply : null,
              icon: applying
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(applying ? 'APPLYING…' : 'APPLY AT FRAME BOUNDARY'),
            ),
          ),
          const SizedBox(height: 9),
          Text(
            connected
                ? 'Configuration is versioned and queued safely.'
                : 'Connect to enable transmitter commands.',
            style: const TextStyle(color: muted, fontSize: 11),
          ),
        ],
      ),
    );
    final visualizer = Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ConstellationPanel(amplitude: amplitude, noise: noise),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: SignalChart(
                title: 'TIME-DOMAIN PREVIEW',
                valueLabel: 'CONFIG PREVIEW',
                values: preview,
                color: blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        TransmissionPanel(status: status, symbolRate: symbolRate),
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 920) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 330, child: controls),
              const SizedBox(width: 14),
              Expanded(child: visualizer),
            ],
          );
        }
        if (constraints.maxWidth < 600) {
          return Column(
            children: [
              controls,
              const SizedBox(height: 14),
              ConstellationPanel(amplitude: amplitude, noise: noise),
              const SizedBox(height: 14),
              SignalChart(
                title: 'TIME-DOMAIN PREVIEW',
                valueLabel: 'CONFIG PREVIEW',
                values: preview,
                color: blue,
              ),
              const SizedBox(height: 14),
              TransmissionPanel(status: status, symbolRate: symbolRate),
            ],
          );
        }
        return Column(
          children: [controls, const SizedBox(height: 14), visualizer],
        );
      },
    );
  }
}

class FileTransferPanel extends StatelessWidget {
  const FileTransferPanel({
    super.key,
    required this.pathController,
    required this.connected,
    required this.uploading,
    required this.encoding,
    required this.shiftKey,
    required this.active,
    required this.queued,
    required this.recent,
    required this.bytesPerSecond,
    required this.maxBytes,
    required this.message,
    required this.onEncodingChanged,
    required this.onShiftKeyChanged,
    required this.onUpload,
    required this.onRefresh,
  });

  final TextEditingController pathController;
  final bool connected, uploading;
  final String encoding, message;
  final double shiftKey, bytesPerSecond;
  final int maxBytes;
  final TransferStatus? active;
  final List<TransferStatus> queued, recent;
  final ValueChanged<String> onEncodingChanged;
  final ValueChanged<double> onShiftKeyChanged;
  final VoidCallback onUpload, onRefresh;

  @override
  Widget build(BuildContext context) => AppPanel(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: PanelTitle(
                icon: Icons.upload_file_rounded,
                title: 'FILE TRANSMISSION / BPSK QUEUE',
                color: blue,
              ),
            ),
            IconButton(
              tooltip: 'Refresh queue',
              onPressed: connected ? onRefresh : null,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Text(
          'Stream text, BMP/WAV media or any binary file through the same modulation pipeline. Maximum ${formatBytes(maxBytes)}.',
          style: const TextStyle(color: muted, fontSize: 12),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 760;
            final path = TextField(
              key: const Key('transfer-file-path'),
              controller: pathController,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'File path',
                hintText: r'E:\media\message.txt',
                prefixIcon: Icon(Icons.description_outlined),
              ),
            );
            final mode = SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'raw',
                  label: Text('RAW'),
                  icon: Icon(Icons.lock_open_rounded, size: 17),
                ),
                ButtonSegment(
                  value: 'byte_shift',
                  label: Text('BYTE SHIFT'),
                  icon: Icon(Icons.key_rounded, size: 17),
                ),
              ],
              selected: {encoding},
              onSelectionChanged: (values) => onEncodingChanged(values.first),
            );
            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [path, const SizedBox(height: 12), mode],
              );
            }
            return Row(
              children: [
                Expanded(child: path),
                const SizedBox(width: 14),
                mode,
              ],
            );
          },
        ),
        if (encoding == 'byte_shift') ...[
          const SizedBox(height: 10),
          Row(
            children: [
              const SizedBox(
                width: 80,
                child: Text(
                  'SHIFT KEY',
                  style: TextStyle(color: muted, fontSize: 10),
                ),
              ),
              Expanded(
                child: Slider(
                  value: shiftKey,
                  min: 0,
                  max: 255,
                  divisions: 255,
                  onChanged: onShiftKeyChanged,
                ),
              ),
              SizedBox(
                width: 38,
                child: Text(
                  shiftKey.round().toString(),
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    color: amber,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            key: const Key('send-file'),
            onPressed: connected && !uploading ? onUpload : null,
            icon: uploading
                ? const SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.cell_tower_rounded),
            label: Text(uploading ? 'ADDING TO QUEUE…' : 'SEND FILE'),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Icon(
              connected ? Icons.circle : Icons.info_outline_rounded,
              size: connected ? 9 : 15,
              color: connected ? mint : muted,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                connected ? message : 'Connect to enable the sender API.',
                style: const TextStyle(color: muted, fontSize: 11),
              ),
            ),
            Text(
              '${bytesPerSecond.toStringAsFixed(0)} B/s',
              style: const TextStyle(color: mint, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 18),
        if (active != null) ...[
          TransferRow(transfer: active!, active: true),
          const SizedBox(height: 10),
        ],
        if (queued.isNotEmpty) ...[
          const Text(
            'QUEUED',
            style: TextStyle(color: muted, fontSize: 10, letterSpacing: 1.2),
          ),
          const SizedBox(height: 8),
          ...queued.take(3).map((item) => TransferRow(transfer: item)),
        ],
        if (active == null && queued.isEmpty && recent.isEmpty)
          const EmptyPanelMessage(
            icon: Icons.inbox_outlined,
            text: 'No transfers yet. Enter a local path and send a demo file.',
          ),
        if (recent.isNotEmpty) ...[
          const SizedBox(height: 10),
          const Text(
            'RECENT',
            style: TextStyle(color: muted, fontSize: 10, letterSpacing: 1.2),
          ),
          const SizedBox(height: 8),
          ...recent.take(3).map((item) => TransferRow(transfer: item)),
        ],
      ],
    ),
  );
}

class TransferRow extends StatelessWidget {
  const TransferRow({super.key, required this.transfer, this.active = false});

  final TransferStatus transfer;
  final bool active;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: ink.withValues(alpha: .54),
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: active ? blue.withValues(alpha: .42) : line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              active
                  ? Icons.podcasts_rounded
                  : Icons.insert_drive_file_outlined,
              size: 18,
              color: active ? blue : muted,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                transfer.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            TinyChip(
              label: transfer.state.toUpperCase(),
              color: active ? blue : mint,
            ),
          ],
        ),
        const SizedBox(height: 9),
        LinearProgressIndicator(
          value: transfer.progress,
          minHeight: 5,
          borderRadius: BorderRadius.circular(99),
          color: active ? blue : mint,
          backgroundColor: line,
        ),
        const SizedBox(height: 7),
        Text(
          '${formatBytes(transfer.sentBytes)} / ${formatBytes(transfer.totalBytes)}  •  ${transfer.mediaType.toUpperCase()}  •  ${transfer.encoding.toUpperCase()}',
          style: const TextStyle(color: muted, fontSize: 10),
        ),
      ],
    ),
  );
}

class PanelTitle extends StatelessWidget {
  const PanelTitle({
    super.key,
    required this.icon,
    required this.title,
    required this.color,
  });
  final IconData icon;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: color, size: 19),
      const SizedBox(width: 9),
      Expanded(
        child: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: .8,
          ),
        ),
      ),
    ],
  );
}

class ConfigValue extends StatelessWidget {
  const ConfigValue({super.key, required this.label, required this.value});
  final String label, value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: muted, fontSize: 10),
          ),
        ),
        TinyChip(label: value, color: blue),
      ],
    ),
  );
}

class ConfigSlider extends StatelessWidget {
  const ConfigSlider({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.valueText,
    required this.color,
    required this.onChanged,
  });
  final String label, valueText;
  final double value, min, max;
  final int divisions;
  final Color color;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: muted, fontSize: 10),
              ),
            ),
            Text(
              valueText,
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(activeTrackColor: color),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    ),
  );
}

class ConstellationPanel extends StatelessWidget {
  const ConstellationPanel({
    super.key,
    required this.amplitude,
    required this.noise,
  });
  final double amplitude, noise;

  @override
  Widget build(BuildContext context) => AppPanel(
    padding: const EdgeInsets.all(18),
    child: SizedBox(
      height: 215,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'BPSK CONSTELLATION / PREVIEW',
            style: TextStyle(
              color: muted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: CustomPaint(
              painter: ConstellationPainter(amplitude, noise),
              size: Size.infinite,
            ),
          ),
        ],
      ),
    ),
  );
}

class TransmissionPanel extends StatelessWidget {
  const TransmissionPanel({
    super.key,
    required this.status,
    required this.symbolRate,
  });
  final lk.NodeStatus? status;
  final double symbolRate;

  @override
  Widget build(BuildContext context) => AppPanel(
    padding: const EdgeInsets.all(18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PanelTitle(
          icon: Icons.cell_tower_rounded,
          title: 'TRANSMISSION STATUS',
          color: mint,
        ),
        const SizedBox(height: 15),
        Wrap(
          spacing: 28,
          runSpacing: 14,
          children: [
            SmallStat(
              label: 'STATE',
              value: status?.active == true ? 'STREAMING' : 'IDLE',
            ),
            SmallStat(
              label: 'FRAME',
              value: status?.lastSequence.toString() ?? '—',
            ),
            SmallStat(label: 'BIT RATE', value: '${symbolRate.round()} bit/s'),
            SmallStat(
              label: 'PEER',
              value: status?.peerConnected == true ? 'CONNECTED' : 'WAITING',
            ),
            SmallStat(
              label: 'CONFIG',
              value: 'v${status?.activeConfigVersion ?? 0}',
            ),
          ],
        ),
      ],
    ),
  );
}

class ControllerWorkspace extends StatelessWidget {
  const ControllerWorkspace({
    super.key,
    required this.latest,
    required this.snrHistory,
    required this.berHistory,
    required this.qHistory,
    required this.rHistory,
    required this.events,
  });
  final Metrics latest;
  final List<double> snrHistory, berHistory, qHistory, rHistory;
  final List<String> events;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final columns = width >= 900 ? 4 : 2;
          final tileWidth = (width - (columns - 1) * 12) / columns;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              MetricCard(
                width: tileWidth,
                label: 'SNR',
                value: '${latest.snr.toStringAsFixed(2)} dB',
                icon: Icons.network_check,
                accent: mint,
              ),
              MetricCard(
                width: tileWidth,
                label: 'BER',
                value: latest.ber.toStringAsExponential(2),
                icon: Icons.rule,
                accent: amber,
              ),
              MetricCard(
                width: tileWidth,
                label: 'LATENCY',
                value: '${latest.latency.toStringAsFixed(2)} ms',
                icon: Icons.speed,
                accent: blue,
              ),
              MetricCard(
                width: tileWidth,
                label: 'CONFIG VERSION',
                value: 'v${latest.version}',
                icon: Icons.tune,
                accent: rose,
              ),
            ],
          );
        },
      ),
      const SizedBox(height: 14),
      LayoutBuilder(
        builder: (context, constraints) {
          final signalCharts = Row(
            children: [
              Expanded(
                child: SignalChart(
                  title: 'SNR HISTORY',
                  valueLabel: '${latest.snr.toStringAsFixed(1)} dB',
                  values: snrHistory,
                  color: mint,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: SignalChart(
                  title: 'BER HISTORY',
                  valueLabel: latest.ber.toStringAsExponential(1),
                  values: berHistory,
                  color: amber,
                ),
              ),
            ],
          );
          final policyCharts = Row(
            children: [
              Expanded(
                child: SignalChart(
                  title: 'PROCESS NOISE / Q',
                  valueLabel: qHistory.isEmpty
                      ? 'WAITING'
                      : qHistory.last.toStringAsExponential(2),
                  values: qHistory,
                  color: blue,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: SignalChart(
                  title: 'MEASUREMENT NOISE / R',
                  valueLabel: rHistory.isEmpty
                      ? 'WAITING'
                      : rHistory.last.toStringAsExponential(2),
                  values: rHistory,
                  color: rose,
                ),
              ),
            ],
          );
          if (constraints.maxWidth >= 780) {
            return Column(
              children: [
                signalCharts,
                const SizedBox(height: 14),
                policyCharts,
              ],
            );
          }
          return Column(
            children: [
              SignalChart(
                title: 'SNR HISTORY',
                valueLabel: '${latest.snr.toStringAsFixed(1)} dB',
                values: snrHistory,
                color: mint,
              ),
              const SizedBox(height: 14),
              SignalChart(
                title: 'BER HISTORY',
                valueLabel: latest.ber.toStringAsExponential(1),
                values: berHistory,
                color: amber,
              ),
              const SizedBox(height: 14),
              SignalChart(
                title: 'PROCESS NOISE / Q',
                valueLabel: qHistory.isEmpty
                    ? 'WAITING'
                    : qHistory.last.toStringAsExponential(2),
                values: qHistory,
                color: blue,
              ),
              const SizedBox(height: 14),
              SignalChart(
                title: 'MEASUREMENT NOISE / R',
                valueLabel: rHistory.isEmpty
                    ? 'WAITING'
                    : rHistory.last.toStringAsExponential(2),
                values: rHistory,
                color: rose,
              ),
            ],
          );
        },
      ),
      const SizedBox(height: 14),
      EventLogPanel(events: events),
    ],
  );
}

class EventLogPanel extends StatelessWidget {
  const EventLogPanel({super.key, required this.events});
  final List<String> events;

  @override
  Widget build(BuildContext context) => AppPanel(
    padding: const EdgeInsets.all(18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PanelTitle(
          icon: Icons.receipt_long_rounded,
          title: 'ADAPTATION EVENT LOG',
          color: rose,
        ),
        const SizedBox(height: 14),
        if (events.isEmpty)
          const Text(
            'Waiting for controller decisions…',
            style: TextStyle(color: muted),
          )
        else
          ...events
              .take(8)
              .map(
                (event) => Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: mint,
                        size: 15,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          event,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ],
    ),
  );
}

class ConstellationPainter extends CustomPainter {
  ConstellationPainter(this.amplitude, this.noise);
  final double amplitude, noise;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = line
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      grid,
    );
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      grid,
    );
    final scale = size.width / 5;
    for (var index = 0; index < 34; index++) {
      final side = index.isEven ? -1.0 : 1.0;
      final jitterX = math.sin(index * 4.17) * noise * 4;
      final jitterY = math.cos(index * 2.31) * noise * 5;
      final point = Offset(
        size.width / 2 + side * amplitude * scale + jitterX,
        size.height / 2 + jitterY,
      );
      canvas.drawCircle(
        point,
        2.5,
        Paint()..color = blue.withValues(alpha: .65),
      );
    }
    for (final side in [-1.0, 1.0]) {
      canvas.drawCircle(
        Offset(size.width / 2 + side * amplitude * scale, size.height / 2),
        6,
        Paint()..color = mint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant ConstellationPainter oldDelegate) =>
      oldDelegate.amplitude != amplitude || oldDelegate.noise != noise;
}

class SectionHeading extends StatelessWidget {
  const SectionHeading({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.description,
  });

  final String eyebrow, title, description;

  @override
  Widget build(BuildContext context) => Wrap(
    crossAxisAlignment: WrapCrossAlignment.end,
    spacing: 12,
    runSpacing: 3,
    children: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow,
            style: const TextStyle(
              color: mint,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.8,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
        ],
      ),
      Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Text(description, style: const TextStyle(color: muted)),
      ),
    ],
  );
}

class AppPanel extends StatelessWidget {
  const AppPanel({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: surface.withValues(alpha: .94),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: line),
      boxShadow: const [
        BoxShadow(
          color: Color(0x22000000),
          blurRadius: 22,
          offset: Offset(0, 9),
        ),
      ],
    ),
    child: child,
  );
}

class DeviceCard extends StatelessWidget {
  const DeviceCard({
    super.key,
    required this.laptop,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.info,
    required this.status,
    required this.fallbackCapabilities,
  });

  final String laptop, title, subtitle;
  final IconData icon;
  final Color accent;
  final lk.NodeInfo? info;
  final lk.NodeStatus? status;
  final List<String> fallbackCapabilities;

  @override
  Widget build(BuildContext context) {
    final ready = status?.health == lk.HealthState.HEALTH_STATE_READY;
    final capabilities = info == null
        ? fallbackCapabilities
        : info!.capabilities
              .map((item) => item.name.toUpperCase())
              .take(3)
              .toList();
    return AppPanel(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: .13),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: accent.withValues(alpha: .32)),
                ),
                child: Icon(icon, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      laptop,
                      style: const TextStyle(
                        color: muted,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              HealthDot(ready: ready, known: status != null),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            subtitle,
            style: TextStyle(color: accent, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 5),
          Text(
            info?.listenAddress ?? 'Waiting for service discovery',
            style: const TextStyle(
              color: muted,
              fontSize: 12,
              fontFamily: 'monospace',
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: capabilities
                .map((item) => TinyChip(label: item, color: accent))
                .toList(),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: SmallStat(
                  label: 'STATE',
                  value: status == null
                      ? 'WAITING'
                      : (ready ? 'READY' : 'DEGRADED'),
                ),
              ),
              Expanded(
                child: SmallStat(
                  label: 'SEQUENCE',
                  value: status?.lastSequence.toString() ?? '—',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SmallStat extends StatelessWidget {
  const SmallStat({super.key, required this.label, required this.value});
  final String label, value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(color: muted, fontSize: 9, letterSpacing: 1.2),
      ),
      const SizedBox(height: 3),
      Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
      ),
    ],
  );
}

class HealthDot extends StatelessWidget {
  const HealthDot({super.key, required this.ready, required this.known});
  final bool ready, known;

  @override
  Widget build(BuildContext context) {
    final color = !known ? muted : (ready ? mint : rose);
    return Container(
      width: 11,
      height: 11,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: .5), blurRadius: 10),
        ],
      ),
    );
  }
}

class FlowArrow extends StatelessWidget {
  const FlowArrow({super.key, required this.label, this.vertical = false});
  final String label;
  final bool vertical;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: vertical ? 90 : 82,
    height: vertical ? 62 : 90,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(color: muted, fontSize: 8, letterSpacing: 1.1),
        ),
        const SizedBox(height: 3),
        Icon(
          vertical ? Icons.south_rounded : Icons.east_rounded,
          color: mint,
          size: 22,
        ),
      ],
    ),
  );
}

class TinyChip extends StatelessWidget {
  const TinyChip({super.key, required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(7),
      border: Border.all(color: color.withValues(alpha: .2)),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: color,
        fontSize: 8,
        fontWeight: FontWeight.w800,
        letterSpacing: .6,
      ),
    ),
  );
}

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, required this.live});
  final String label;
  final bool live;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
    decoration: BoxDecoration(
      color: (live ? mint : rose).withValues(alpha: .09),
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: (live ? mint : rose).withValues(alpha: .24)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        HealthDot(ready: live, known: true),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: live ? mint : rose,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.width,
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  final double width;
  final String label, value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: AppPanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 17, color: accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: muted,
                    fontSize: 9,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Text(
            value,
            maxLines: 1,
            style: TextStyle(
              color: accent,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );
}

class SignalChart extends StatelessWidget {
  const SignalChart({
    super.key,
    required this.title,
    required this.valueLabel,
    required this.values,
    required this.color,
  });

  final String title, valueLabel;
  final List<double> values;
  final Color color;

  @override
  Widget build(BuildContext context) => AppPanel(
    padding: const EdgeInsets.all(18),
    child: SizedBox(
      height: 215,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: muted,
                    fontSize: 10,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                valueLabel,
                style: TextStyle(color: color, fontWeight: FontWeight.w700),
              ),
            ],
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
    ),
  );
}

class MediaPanel extends StatelessWidget {
  const MediaPanel({super.key, required this.items});
  final List<MediaActivity> items;

  @override
  Widget build(BuildContext context) => AppPanel(
    padding: const EdgeInsets.all(18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.perm_media_rounded, color: mint, size: 19),
            SizedBox(width: 9),
            Expanded(
              child: Text(
                'RECEIVER MEDIA',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  letterSpacing: .8,
                ),
              ),
            ),
            TinyChip(label: 'AUTO DETECT', color: mint),
          ],
        ),
        const SizedBox(height: 14),
        if (items.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: ink.withValues(alpha: .35),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Column(
              children: [
                Icon(Icons.radar_rounded, color: muted, size: 30),
                SizedBox(height: 8),
                Text(
                  'Waiting for text, image or audio payloads',
                  style: TextStyle(color: muted),
                ),
              ],
            ),
          )
        else
          ...items.take(4).map((item) => MediaRow(item: item)),
      ],
    ),
  );
}

class MediaRow extends StatelessWidget {
  const MediaRow({super.key, required this.item});
  final MediaActivity item;

  @override
  Widget build(BuildContext context) {
    final accent = switch (item.kind) {
      'TEXT' => mint,
      'IMAGE' => blue,
      'AUDIO' => rose,
      _ => amber,
    };
    final progress = item.total <= 0
        ? null
        : (item.received / item.total).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: ink.withValues(alpha: .42),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(mediaIcon(item.kind), color: accent, size: 20),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.preview.isEmpty
                        ? '${item.contentType} • ${item.received} bytes'
                        : item.preview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: muted, fontSize: 11),
                  ),
                  if (progress != null) ...[
                    const SizedBox(height: 7),
                    LinearProgressIndicator(
                      value: progress,
                      minHeight: 3,
                      color: accent,
                      backgroundColor: line,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            TinyChip(
              label: item.complete
                  ? (item.checksumValid ? 'VERIFIED' : 'FAILED')
                  : item.kind,
              color: item.complete && !item.checksumValid ? rose : accent,
            ),
          ],
        ),
      ),
    );
  }

  IconData mediaIcon(String kind) => switch (kind) {
    'TEXT' => Icons.description_rounded,
    'IMAGE' => Icons.image_rounded,
    'AUDIO' => Icons.audio_file_rounded,
    _ => Icons.data_object_rounded,
  };
}

class RunPanel extends StatelessWidget {
  const RunPanel({
    super.key,
    required this.sequence,
    required this.version,
    required this.connectionDetail,
    required this.receiverStatus,
  });

  final int sequence, version;
  final String connectionDetail;
  final lk.NodeStatus? receiverStatus;

  @override
  Widget build(BuildContext context) => AppPanel(
    padding: const EdgeInsets.all(18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.monitor_heart_rounded, color: rose, size: 19),
            SizedBox(width: 9),
            Text(
              'EXPERIMENT STATE',
              style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: .8),
            ),
          ],
        ),
        const SizedBox(height: 17),
        RunStat(
          label: 'CURRENT FRAME',
          value: sequence.toString().padLeft(8, '0'),
        ),
        RunStat(label: 'ACTIVE CONFIG', value: 'v$version'),
        RunStat(
          label: 'RECEIVER LINK',
          value: receiverStatus == null
              ? 'WAITING'
              : (receiverStatus!.peerConnected ? 'CONNECTED' : 'IDLE'),
        ),
        const SizedBox(height: 8),
        Text(
          connectionDetail,
          style: const TextStyle(color: muted, fontSize: 12),
        ),
      ],
    ),
  );
}

class RunStat extends StatelessWidget {
  const RunStat({super.key, required this.label, required this.value});
  final String label, value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: muted,
              fontSize: 10,
              letterSpacing: 1.1,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.w800,
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
      ..color = line.withValues(alpha: .75)
      ..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    if (values.length < 2) return;
    var minValue = values.reduce((a, b) => a < b ? a : b);
    var maxValue = values.reduce((a, b) => a > b ? a : b);
    if ((maxValue - minValue).abs() < .000001) maxValue = minValue + 1;
    final chartLine = Path();
    final fill = Path();
    for (var i = 0; i < values.length; i++) {
      final point = Offset(
        size.width * i / (values.length - 1),
        size.height * (1 - (values[i] - minValue) / (maxValue - minValue)),
      );
      if (i == 0) {
        chartLine.moveTo(point.dx, point.dy);
        fill.moveTo(point.dx, size.height);
        fill.lineTo(point.dx, point.dy);
      } else {
        chartLine.lineTo(point.dx, point.dy);
        fill.lineTo(point.dx, point.dy);
      }
    }
    fill.lineTo(size.width, size.height);
    fill.close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: .2), color.withValues(alpha: 0)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      chartLine,
      Paint()
        ..color = color
        ..strokeWidth = 2.4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant ChartPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.color != color;
}

String friendlyError(Object error) {
  final value = error.toString().replaceFirst('Exception: ', '');
  return value.length > 120 ? '${value.substring(0, 120)}…' : value;
}

String formatBytes(int bytes) {
  if (bytes >= 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MiB';
  }
  if (bytes >= 1024) return '${(bytes / 1024).toStringAsFixed(1)} KiB';
  return '$bytes B';
}

class EmptyPanelMessage extends StatelessWidget {
  const EmptyPanelMessage({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: ink.withValues(alpha: .35),
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: line),
    ),
    child: Row(
      children: [
        Icon(icon, color: muted),
        const SizedBox(width: 11),
        Expanded(
          child: Text(text, style: const TextStyle(color: muted, fontSize: 12)),
        ),
      ],
    ),
  );
}
