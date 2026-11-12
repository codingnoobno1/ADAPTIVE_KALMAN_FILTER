import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:livekalman_sdk/livekalman_sdk.dart' as lk;

import '../dsp/kalman_engine.dart';
import '../models/kalman_parameters.dart';

/// Default LAN / local-emulator endpoint URI for the 3-node Live Kalman lab.
const String defaultMobileEndpoint =
    'grpc://10.0.2.2:55053?txHost=10.0.2.2&rxHost=10.0.2.2&txPort=55051&rxPort=55052&controllerHttpPort=8080';

/// Active telemetry mode in the mobile app.
enum TelemetrySourceMode {
  onDeviceLab('On-Device Lab'),
  liveThreeNodeGrpc('3-Node Live gRPC');

  const TelemetrySourceMode(this.label);
  final String label;
}

/// Parsed connection configuration for the three lab servers.
final class ParsedLabConnection {
  const ParsedLabConnection({
    required this.endpoints,
    required this.secure,
    this.controllerHttpUri,
  });

  final lk.LabEndpoints endpoints;
  final bool secure;
  final Uri? controllerHttpUri;

  static ParsedLabConnection parse(String rawUri) {
    final trimmed = rawUri.trim();
    final uri = Uri.parse(
      trimmed.contains('://') ? trimmed : 'grpc://$trimmed',
    );
    final secure = uri.scheme == 'grpcs' || uri.scheme == 'https';
    final controllerHost = uri.host.isEmpty ? '127.0.0.1' : uri.host;
    final defaultControllerPort = secure ? 443 : 55053;
    final controllerPort = uri.hasPort ? uri.port : defaultControllerPort;

    final txHost = uri.queryParameters['txHost'] ?? controllerHost;
    final rxHost = uri.queryParameters['rxHost'] ?? controllerHost;
    final txPort =
        int.tryParse(uri.queryParameters['txPort'] ?? '') ??
        (secure ? 443 : 55051);
    final rxPort =
        int.tryParse(uri.queryParameters['rxPort'] ?? '') ??
        (secure ? 443 : 55052);
    final httpPort =
        int.tryParse(uri.queryParameters['controllerHttpPort'] ?? '') ?? 8080;

    final httpScheme = secure ? 'https' : 'http';
    final controllerHttp = Uri(
      scheme: httpScheme,
      host: controllerHost,
      port: httpPort,
    );

    return ParsedLabConnection(
      endpoints: lk.LabEndpoints(
        transmitterHost: txHost,
        receiverHost: rxHost,
        controllerHost: controllerHost,
        transmitterPort: txPort,
        receiverPort: rxPort,
        controllerPort: controllerPort,
      ),
      secure: secure,
      controllerHttpUri: controllerHttp,
    );
  }
}

/// Assembles transmitted and reconstructed BMP chunks for PSNR/SSIM scoring.
final class _MediaReconstructionBuffer {
  _MediaReconstructionBuffer(this.fileName);
  final String fileName;
  final Map<int, Uint8List> _txChunks = <int, Uint8List>{};
  final Map<int, Uint8List> _rxChunks = <int, Uint8List>{};
  int _txTotal = 0;
  Uint8List? originalBytes;
  Uint8List? reconstructedBytes;
  lk.ImageMetrics? metrics;

  void addTxChunk(int offset, List<int> data, int total) {
    if (data.isEmpty) return;
    _txTotal = total;
    _txChunks[offset] = Uint8List.fromList(data);
    final count = _txChunks.values.fold<int>(0, (s, b) => s + b.length);
    if (total > 0 && count >= total) {
      final out = Uint8List(total);
      for (final e in _txChunks.entries) {
        final end = math.min(total, e.key + e.value.length);
        if (e.key < total) out.setRange(e.key, end, e.value);
      }
      originalBytes = out;
      _tryEvaluate();
    }
  }

  void addRxChunk(int offset, List<int> data, int total, bool endOfStream) {
    if (data.isNotEmpty) {
      _rxChunks[offset] = Uint8List.fromList(data);
    }
    if (!endOfStream) return;
    final size = total > 0
        ? total
        : (_txTotal > 0
              ? _txTotal
              : _rxChunks.entries.fold<int>(
                  0,
                  (m, e) => math.max(m, e.key + e.value.length),
                ));
    if (size <= 0) return;
    final out = Uint8List(size);
    for (final e in _rxChunks.entries) {
      final end = math.min(size, e.key + e.value.length);
      if (e.key < size) out.setRange(e.key, end, e.value);
    }
    reconstructedBytes = out;
    _tryEvaluate();
  }

  void _tryEvaluate() {
    if (originalBytes == null || reconstructedBytes == null) return;
    try {
      metrics = lk.compareBmp(originalBytes!, reconstructedBytes!);
    } on FormatException {
      // Non-BMP payload (e.g. text or WAV); PSNR/SSIM apply to BMP images only.
    }
  }
}

/// Central mobile state controller unifying the On-Device Kalman Workbench and
/// live 3-node gRPC/HTTP telemetry.
class TelemetryController extends ChangeNotifier {
  TelemetryController({
    bool autoPlay = true,
    int initialWarmupFrames = 28,
    String initialEndpoint = defaultMobileEndpoint,
  }) : _endpointUri = initialEndpoint,
       workbench = OnDeviceKalmanWorkbench() {
    for (var i = 0; i < initialWarmupFrames; i++) {
      _appendSnapshot(workbench.nextFrame(), notify: false);
    }
    if (autoPlay) {
      startOnDevicePlayback();
    }
  }

  static const int maxHistoryLength = 120;

  final OnDeviceKalmanWorkbench workbench;
  TelemetrySourceMode _mode = TelemetrySourceMode.onDeviceLab;
  String _endpointUri;
  bool _isPlaying = false;
  int _tickIntervalMs = 100; // 10 Hz default mobile frame cadence
  Timer? _simTimer;

  // Rolling history for charts & parameter cards
  final List<KalmanParameterSnapshot> _history = <KalmanParameterSnapshot>[];

  // Live 3-Node gRPC state
  lk.LiveKalmanClient? _client;
  ParsedLabConnection? _parsedConnection;
  Timer? _probeTimer;
  final List<StreamSubscription<Object>> _liveSubs =
      <StreamSubscription<Object>>[];
  final List<Timer> _retryTimers = <Timer>[];
  bool _probing = false;
  bool _disposed = false;

  final List<lk.NodeHealth> nodeHealth = <lk.NodeHealth>[
    const lk.NodeHealth(role: lk.NodeRole.NODE_ROLE_TRANSMITTER),
    const lk.NodeHealth(role: lk.NodeRole.NODE_ROLE_RECEIVER),
    const lk.NodeHealth(role: lk.NodeRole.NODE_ROLE_CONTROLLER),
  ];

  final Map<String, String> streamStatuses = <String, String>{
    'WatchExperiment': 'idle',
    'WatchFrameTraces': 'idle',
    'WatchTxEvents': 'idle',
    'WatchMedia': 'idle',
  };

  // Shadow Riccati observer synchronized to live ReceiverMetrics Q, R, and gaps
  final ScalarKalmanFilter _liveRiccatiObserver = ScalarKalmanFilter(
    q: 0.0067,
    r: 0.25,
  );
  final List<double> _liveInnovations = <double>[];
  int _lastLiveGaps = 0;
  int _commandCounter = 1;
  lk.PolicyDecision? _latestDecision;
  lk.ChannelAssessment? _latestAssessment;
  lk.MonitorSnapshot? latestMonitorSnapshot;
  final Map<String, _MediaReconstructionBuffer> _transfers =
      <String, _MediaReconstructionBuffer>{};
  lk.ImageMetrics? _latestImageMetrics;
  String? lastControlStatus;

  TelemetrySourceMode get mode => _mode;
  String get endpointUri => _endpointUri;
  bool get isPlaying => _isPlaying;
  int get tickIntervalMs => _tickIntervalMs;
  List<KalmanParameterSnapshot> get history => List.unmodifiable(_history);
  KalmanParameterSnapshot get latest => _history.last;
  lk.ImageMetrics? get latestImageMetrics => _latestImageMetrics;

  String get txToRxSummary =>
      lk.transmitterToReceiver(nodeHealth[0], nodeHealth[1]);

  void _appendSnapshot(KalmanParameterSnapshot snap, {bool notify = true}) {
    _history.add(snap);
    if (_history.length > maxHistoryLength) {
      _history.removeAt(0);
    }
    if (notify && !_disposed) {
      notifyListeners();
    }
  }

  // ------------------------- Mode & On-Device Controls ----------------------

  void setSourceMode(TelemetrySourceMode nextMode) {
    if (_mode == nextMode) return;
    _mode = nextMode;
    if (nextMode == TelemetrySourceMode.onDeviceLab) {
      unawaited(disconnectLiveGrpc());
    } else {
      pauseOnDevicePlayback();
      unawaited(connectLiveGrpc(_endpointUri));
    }
    notifyListeners();
  }

  void startOnDevicePlayback() {
    if (_isPlaying || _mode != TelemetrySourceMode.onDeviceLab) return;
    _isPlaying = true;
    _simTimer?.cancel();
    _simTimer = Timer.periodic(Duration(milliseconds: _tickIntervalMs), (_) {
      _appendSnapshot(workbench.nextFrame());
    });
    notifyListeners();
  }

  void pauseOnDevicePlayback() {
    _simTimer?.cancel();
    _simTimer = null;
    if (_isPlaying) {
      _isPlaying = false;
      notifyListeners();
    }
  }

  void toggleOnDevicePlayback() {
    if (_isPlaying) {
      pauseOnDevicePlayback();
    } else {
      startOnDevicePlayback();
    }
  }

  void stepSingleFrame() {
    if (_mode != TelemetrySourceMode.onDeviceLab) return;
    _appendSnapshot(workbench.nextFrame());
  }

  void setTickIntervalMs(int ms) {
    _tickIntervalMs = ms.clamp(30, 1000);
    if (_isPlaying) {
      pauseOnDevicePlayback();
      startOnDevicePlayback();
    } else {
      notifyListeners();
    }
  }

  void setSimulationProfile(SimulationProfile nextProfile) {
    workbench.profile = nextProfile;
    _appendSnapshot(workbench.nextFrame());
  }

  void setAutoRuleAdaptation(bool enabled) {
    workbench.autoRuleAdaptation = enabled;
    _appendSnapshot(workbench.nextFrame());
  }

  void setManualKalmanQR({
    required double q,
    required double r,
    bool reset = false,
  }) {
    workbench.autoRuleAdaptation = false;
    workbench.updateFilterTuning(q: q, r: r, reset: reset);
    _appendSnapshot(workbench.nextFrame());
  }

  void setChannelImpairments({
    double? noiseStddev,
    double? driftStddev,
    double? fadingDepth,
  }) {
    if (noiseStddev != null) workbench.noiseStddev = noiseStddev;
    if (driftStddev != null) workbench.driftStddev = driftStddev;
    if (fadingDepth != null) workbench.fadingDepth = fadingDepth;
    notifyListeners();
  }

  void injectDisturbance(double deltaVolts) {
    workbench.injectStepDisturbance(deltaVolts);
    _appendSnapshot(workbench.nextFrame());
  }

  void resetOnDeviceFilter() {
    workbench.resetAll();
    _history.clear();
    for (var i = 0; i < 12; i++) {
      _appendSnapshot(workbench.nextFrame(), notify: false);
    }
    notifyListeners();
  }

  // ------------------------- Live 3-Node gRPC & HTTP ------------------------

  Future<void> connectLiveGrpc(String rawEndpoint) async {
    await disconnectLiveGrpc();
    _endpointUri = rawEndpoint.trim();
    _mode = TelemetrySourceMode.liveThreeNodeGrpc;
    try {
      final parsed = ParsedLabConnection.parse(_endpointUri);
      _parsedConnection = parsed;
      final client = lk.LiveKalmanClient.connect(
        parsed.endpoints,
        secure: parsed.secure,
      );
      _client = client;
      lastControlStatus =
          'Connecting to ${parsed.endpoints.controllerHost}:${parsed.endpoints.controllerPort} '
          '(${parsed.secure ? 'TLS grpcs' : 'LAN grpc'})';

      _probeTimer = Timer.periodic(
        const Duration(seconds: 1),
        (_) => unawaited(_runLiveProbe()),
      );
      unawaited(_runLiveProbe());

      _subscribeWithBackoff<lk.ExperimentEvent>(
        'WatchExperiment',
        client.watchExperiment,
        _handleExperimentEvent,
      );
      _subscribeWithBackoff<lk.RxFrameTrace>(
        'WatchFrameTraces',
        client.watchFrameTraces,
        _handleRxTrace,
      );
      _subscribeWithBackoff<lk.TxEvent>(
        'WatchTxEvents',
        client.watchTxEvents,
        _handleTxEvent,
      );
      _subscribeWithBackoff<lk.MediaEvent>(
        'WatchMedia',
        client.watchMedia,
        _handleMediaEvent,
      );
    } on Object catch (error) {
      lastControlStatus = 'Endpoint error: $error';
    }
    if (!_disposed) notifyListeners();
  }

  Future<void> disconnectLiveGrpc() async {
    _probeTimer?.cancel();
    _probeTimer = null;
    for (final timer in _retryTimers) {
      timer.cancel();
    }
    _retryTimers.clear();
    for (final sub in _liveSubs) {
      await sub.cancel();
    }
    _liveSubs.clear();
    final existing = _client;
    _client = null;
    if (existing != null) {
      await existing.close();
    }
    for (final key in streamStatuses.keys.toList()) {
      streamStatuses[key] = 'disconnected';
    }
  }

  Future<void> _runLiveProbe() async {
    final client = _client;
    if (client == null || _probing || _disposed) return;
    _probing = true;
    try {
      final probes = await client.probeNodes();
      final now = DateTime.now();
      for (var i = 0; i < probes.length; i++) {
        nodeHealth[i] = lk.evaluateProbe(nodeHealth[i], probes[i], now);
      }
      final httpBase = _parsedConnection?.controllerHttpUri;
      if (httpBase != null) {
        await _pollMonitorHttp(httpBase);
      }
      if (!_disposed) notifyListeners();
    } finally {
      _probing = false;
    }
  }

  Future<void> _pollMonitorHttp(Uri baseUri) async {
    try {
      final uri = baseUri.replace(path: '/api/v1/monitor');
      final response = await http
          .get(uri)
          .timeout(const Duration(milliseconds: 1500));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        latestMonitorSnapshot = lk.MonitorSnapshot.fromJson(decoded);
      }
    } on Object {
      // HTTP monitor endpoint is optional alongside gRPC streams.
    }
  }

  void _subscribeWithBackoff<T extends Object>(
    String streamName,
    Stream<T> Function() openStream,
    void Function(T event) onEvent, {
    int attempt = 0,
  }) {
    if (_disposed || _client == null) return;
    streamStatuses[streamName] = attempt == 0
        ? 'connecting'
        : 'reconnecting (#$attempt)';

    late final StreamSubscription<T> sub;
    sub = openStream().listen(
      (event) {
        streamStatuses[streamName] = 'streaming';
        onEvent(event);
      },
      onError: (Object error) {
        streamStatuses[streamName] = lk.describeError(error);
        _scheduleReconnect(streamName, openStream, onEvent, attempt + 1);
      },
      onDone: () {
        streamStatuses[streamName] = 'closed, retrying';
        _scheduleReconnect(streamName, openStream, onEvent, attempt + 1);
      },
      cancelOnError: true,
    );
    _liveSubs.add(sub);
  }

  void _scheduleReconnect<T extends Object>(
    String streamName,
    Stream<T> Function() openStream,
    void Function(T event) onEvent,
    int nextAttempt,
  ) {
    if (_disposed || _client == null) return;
    final delay = lk.reconnectDelay(nextAttempt);
    final timer = Timer(delay, () {
      _subscribeWithBackoff(
        streamName,
        openStream,
        onEvent,
        attempt: nextAttempt,
      );
    });
    _retryTimers.add(timer);
    if (!_disposed) notifyListeners();
  }

  void _handleExperimentEvent(lk.ExperimentEvent event) {
    if (event.hasDecision()) {
      _latestDecision = event.decision;
    }
    if (event.hasAssessment()) {
      _latestAssessment = event.assessment;
    }
    if (!event.hasMetrics()) {
      if (!_disposed) notifyListeners();
      return;
    }

    final m = event.metrics;
    final q = m.activeKalmanQ > 0 ? m.activeKalmanQ : 0.0067;
    final r = m.activeKalmanR > 0 ? m.activeKalmanR : 0.25;
    final gaps = m.sequenceGaps.toInt();
    final gapOccurred = gaps > _lastLiveGaps;
    _lastLiveGaps = gaps;

    _liveRiccatiObserver.configure(q: q, r: r, reset: gapOccurred);
    // Each 64-symbol frame performs 8 block updates (DCBlockSymbols = 8).
    var step = _liveRiccatiObserver.update(m.frameMean);
    for (var b = 1; b < 8; b++) {
      step = _liveRiccatiObserver.update(m.frameMean);
    }

    final innovation = m.frameMean - m.dcEstimate;
    _liveInnovations.add(innovation);
    if (_liveInnovations.length > 32) {
      _liveInnovations.removeAt(0);
    }
    var sumSq = 0.0;
    for (final v in _liveInnovations) {
      sumSq += v * v;
    }
    final rms = math.sqrt(sumSq / _liveInnovations.length);
    final nis = step.innovationCovS > 0
        ? (innovation * innovation) / step.innovationCovS
        : 0.0;

    final decision = _latestDecision;
    final assessment = _latestAssessment;
    final compared = m.comparedBits.toInt();

    final snapshot = KalmanParameterSnapshot(
      timestamp: m.observedAtUnixMs > 0
          ? DateTime.fromMillisecondsSinceEpoch(m.observedAtUnixMs.toInt())
          : DateTime.now(),
      sequence: m.sequence.toInt(),
      stepCount: _liveRiccatiObserver.stepCount,
      ready: true,
      isLiveSource: true,
      stateEstimateX: m.dcEstimate,
      priorCovariancePMinus: step.pPrior,
      posteriorCovarianceP: step.pPosterior,
      kalmanGainK: step.gainK,
      processNoiseQ: q,
      measurementNoiseR: r,
      rawMeasurementZ: m.frameMean,
      innovationY: innovation,
      innovationCovarianceS: step.innovationCovS,
      normalizedInnovationSquared: nis,
      residualRms: rms,
      snrDb: m.snrDb,
      noiseVariance: m.noiseVariance,
      ber: compared > 0 ? m.ber : null,
      comparedBits: compared,
      bitErrors: m.bitErrors.toInt(),
      psnrDb: _latestImageMetrics?.psnr,
      ssim: _latestImageMetrics?.ssim,
      latencyMs: m.latencyMs,
      queueDepth: m.queueDepth,
      sequenceGaps: gaps,
      resetCount: _liveRiccatiObserver.resetCount,
      activeConfigVersion: m.activeConfigVersion.toInt(),
      proposedConfigVersion: decision?.proposedVersion.toInt(),
      effectiveSequence: decision?.effectiveSequence.toInt(),
      policyName: decision != null && decision.policy.isNotEmpty
          ? decision.policy
          : (latestMonitorSnapshot?.policy ?? 'rule'),
      recommendOnly: decision != null
          ? !decision.sentToReceiver
          : (latestMonitorSnapshot?.recommendOnly ?? false),
      recommendedQ: decision?.proposedKalmanQ,
      recommendedR: decision?.proposedKalmanR,
      predictedRho: decision?.predictedRho,
      measuredClass: assessment != null && assessment.measuredClass.isNotEmpty
          ? assessment.measuredClass
          : null,
      predictedClass:
          assessment != null && assessment.predictedClass.isNotEmpty
          ? assessment.predictedClass
          : null,
      mlConfidence: assessment?.confidence,
      classProbabilities: assessment == null
          ? const []
          : List<double>.from(assessment.classProbabilities),
      featureNames: assessment == null
          ? const []
          : List<String>.from(assessment.featureNames),
      featureValues: assessment == null
          ? const []
          : List<double>.from(assessment.features),
    );

    _appendSnapshot(snapshot);
  }

  void _handleRxTrace(lk.RxFrameTrace trace) {
    // Traces keep live link status fresh even before Controller metrics arrive.
    if (!_disposed) notifyListeners();
  }

  void _handleTxEvent(lk.TxEvent event) {
    if (!event.hasTrace()) return;
    final t = event.trace;
    if (t.transferId.isNotEmpty && t.originalBytes.isNotEmpty) {
      final buf = _transfers.putIfAbsent(
        t.transferId,
        () => _MediaReconstructionBuffer(t.fileName),
      );
      buf.addTxChunk(
        t.mediaOffset.toInt(),
        t.originalBytes,
        t.totalBytes.toInt(),
      );
      if (buf.metrics != null) {
        _latestImageMetrics = buf.metrics;
      }
    }
  }

  void _handleMediaEvent(lk.MediaEvent mediaEvent) {
    if (!mediaEvent.hasMedia()) return;
    final id = mediaEvent.media.transferId;
    if (id.isEmpty) return;
    final buf = _transfers.putIfAbsent(
      id,
      () => _MediaReconstructionBuffer(mediaEvent.media.fileName),
    );
    buf.addRxChunk(
      mediaEvent.offset.toInt(),
      mediaEvent.data,
      mediaEvent.media.totalSize.toInt(),
      mediaEvent.endOfStream,
    );
    if (buf.metrics != null) {
      _latestImageMetrics = buf.metrics;
      if (!_disposed) notifyListeners();
    }
  }

  /// Applies a manual Q/R configuration directly to the live Receiver node.
  Future<void> applyRemoteReceiverConfig({
    required double kalmanQ,
    required double kalmanR,
    bool resetState = false,
  }) async {
    final client = _client;
    if (client == null) {
      lastControlStatus = 'Not connected to a live Receiver endpoint.';
      notifyListeners();
      return;
    }
    try {
      final nextVersion = latest.activeConfigVersion + 1;
      final nextSeq = latest.sequence + 4;
      final reply = await client.receiver.applyReceiverConfig(
        lk.RxConfig(
          commandId: Int64(_commandCounter++),
          version: Int64(nextVersion),
          effectiveSequence: Int64(nextSeq),
          kalmanQ: kalmanQ,
          kalmanR: kalmanR,
          resetState: resetState,
        ),
      );
      lastControlStatus = reply.accepted
          ? 'Receiver accepted v${reply.appliedVersion} (Q=$kalmanQ, R=$kalmanR)'
          : 'Receiver rejected config: ${reply.reason}';
    } on Object catch (error) {
      lastControlStatus = 'ApplyReceiverConfig failed: ${lk.describeError(error)}';
    }
    if (!_disposed) notifyListeners();
  }

  /// Applies BPSK channel parameters to the live Transmitter node.
  Future<void> applyRemoteTransmitterConfig({
    required double amplitude,
    required double noiseStddev,
    int symbolRate = 6000,
  }) async {
    final client = _client;
    if (client == null) {
      lastControlStatus = 'Not connected to a live Transmitter endpoint.';
      notifyListeners();
      return;
    }
    try {
      final cmdId = _commandCounter++;
      final reply = await client.transmitter.applyTransmitterConfig(
        lk.TxConfig(
          commandId: Int64(cmdId),
          version: Int64(DateTime.now().millisecondsSinceEpoch ~/ 1000),
          effectiveSequence: Int64(latest.sequence + 4),
          symbolRate: symbolRate,
          amplitude: amplitude,
          noiseStddev: noiseStddev,
        ),
      );
      lastControlStatus = reply.accepted
          ? 'Transmitter accepted v${reply.appliedVersion} (σ=$noiseStddev)'
          : 'Transmitter rejected config: ${reply.reason}';
    } on Object catch (error) {
      lastControlStatus =
          'ApplyTransmitterConfig failed: ${lk.describeError(error)}';
    }
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _simTimer?.cancel();
    unawaited(disconnectLiveGrpc());
    super.dispose();
  }
}
