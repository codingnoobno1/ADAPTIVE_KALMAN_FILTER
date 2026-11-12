// Live data layer for the dashboard: health probes, auto-reconnecting gRPC
// streams, real frame traces, image-quality comparison and ML assessments.
//
// Everything held here comes from the running Sender, Receiver and Controller.
// Nothing is generated locally; when a value is not available it stays null
// and the UI says why.
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:livekalman_sdk/livekalman_sdk.dart' as lk;

const frameBufferSize = 48;
const assessmentBufferSize = 60;

/// A trace with the local time it was received (dashboard clock).
final class Timed<T> {
  Timed(this.value, this.receivedAt);
  final T value;
  final DateTime receivedAt;
}

/// State of one auto-reconnecting server stream.
final class StreamState {
  String status = 'not started';
  int attempt = 0;
  int messages = 0;
  DateTime? lastMessageAt;
  String? lastError;
}

/// An image transfer seen on both sides, for PSNR/SSIM.
final class ImageTransfer {
  ImageTransfer(this.key, this.fileName);
  final String key, fileName;
  Uint8List? original; // assembled from Sender traces (original_bytes)
  int originalTotal = 0;
  final Map<int, Uint8List> _chunks = {};
  Uint8List? reconstructed; // assembled from Receiver media event chunks
  bool reconstructedComplete = false;
  final Map<int, Uint8List> _rxChunks = {};

  /// Media events carry one chunk each at an offset; the file is complete at
  /// end_of_stream. Missing chunks stay zero and lower PSNR/SSIM accordingly.
  void addReconstructedChunk(int offset, List<int> bytes, int total, bool end) {
    if (bytes.isNotEmpty) _rxChunks[offset] = Uint8List.fromList(bytes);
    if (!end) return;
    final size = total > 0
        ? total
        : _rxChunks.entries.fold<int>(
            0,
            (n, e) => e.key + e.value.length > n ? e.key + e.value.length : n,
          );
    final out = Uint8List(size);
    for (final e in _rxChunks.entries) {
      final end = (e.key + e.value.length).clamp(0, size);
      if (e.key < size) out.setRange(e.key, end, e.value);
    }
    reconstructed = out;
    reconstructedComplete = true;
  }

  bool? checksumValid;
  lk.ImageMetrics? metrics;
  String? error;

  bool get originalComplete => original != null;

  /// Bytes of the original seen so far in Sender traces.
  int get originalBytesSeen =>
      _chunks.values.fold<int>(0, (n, c) => n + c.length);

  void addOriginalChunk(int offset, List<int> bytes, int total) {
    if (bytes.isEmpty) return;
    originalTotal = total;
    _chunks[offset] = Uint8List.fromList(bytes);
    final have = _chunks.values.fold<int>(0, (n, c) => n + c.length);
    if (total > 0 && have >= total) {
      final out = Uint8List(total);
      for (final e in _chunks.entries) {
        final end = e.key + e.value.length;
        if (end <= total) out.setRange(e.key, end, e.value);
      }
      original = out;
    }
  }
}

/// One controller decision paired with what the receiver actually applied.
final class DecisionRecord {
  DecisionRecord(this.decision, this.at);
  final lk.PolicyDecision decision;
  final DateTime at;
}

/// One assessment plus, once the next window is measured, whether the
/// prediction came true. This is the live (not simulated) accuracy check.
final class AssessmentRecord {
  AssessmentRecord(this.assessment, this.at);
  final lk.ChannelAssessment assessment;
  final DateTime at;
  String? actualNext;
  bool? get correct => actualNext == null || assessment.predictedClass.isEmpty
      ? null
      : actualNext == assessment.predictedClass;
}

class LiveLab extends ChangeNotifier {
  LiveLab(
    this.client, {
    this.controllerHttp,
    this.staleAfter = const Duration(seconds: 3),
    this.onExperimentEvent,
    this.onMedia,
  });

  final lk.LiveKalmanClient client;

  /// Controller HTTP base (for /api/v1/ml/model), or null when unknown.
  final Uri? controllerHttp;
  final Duration staleAfter;

  /// Called for every controller event and media chunk (unthrottled), so the
  /// page's existing metrics charts and media list see every message.
  final void Function(lk.ExperimentEvent)? onExperimentEvent;
  final void Function(lk.MediaEvent)? onMedia;

  final health = <lk.NodeHealth>[
    const lk.NodeHealth(role: lk.NodeRole.NODE_ROLE_TRANSMITTER),
    const lk.NodeHealth(role: lk.NodeRole.NODE_ROLE_RECEIVER),
    const lk.NodeHealth(role: lk.NodeRole.NODE_ROLE_CONTROLLER),
  ];
  final streams = <String, StreamState>{
    'sender traces': StreamState(),
    'receiver traces': StreamState(),
    'controller events': StreamState(),
    'receiver media': StreamState(),
  };
  final txFrames = <Timed<lk.TxFrameTrace>>[];
  final rxFrames = <Timed<lk.RxFrameTrace>>[];
  final assessments = <AssessmentRecord>[];
  final decisions = <DecisionRecord>[];
  final transfers = <String, ImageTransfer>{};
  lk.ReceiverMetrics? latestMetrics;
  DateTime? latestMetricsAt;
  int rxSequenceJumps = 0;
  Map<String, Object?>? modelReport;
  String modelReportStatus = 'not requested';

  final _subs = <StreamSubscription<Object>>[];
  final _timers = <Timer>[];
  bool _disposed = false;
  bool _probing = false;
  DateTime _lastNotify = DateTime.fromMillisecondsSinceEpoch(0);
  Timer? _pendingNotify;

  void start() {
    _timers.add(Timer.periodic(const Duration(seconds: 1), (_) => probe()));
    unawaited(probe());
    _keep('sender traces', client.watchTxEvents, (e) => _onTx(e as lk.TxEvent));
    _keep(
      'receiver traces',
      client.watchFrameTraces,
      (e) => _onRx(e as lk.RxFrameTrace),
    );
    _keep(
      'controller events',
      client.watchExperiment,
      (e) => _onEvent(e as lk.ExperimentEvent),
    );
    _keep(
      'receiver media',
      client.watchMedia,
      (e) => _onMedia(e as lk.MediaEvent),
    );
    unawaited(fetchModelReport());
  }

  /// Application-level probe of all three nodes (deadline 2 s each).
  Future<void> probe() async {
    if (_probing || _disposed) return;
    _probing = true;
    try {
      final probes = await client.probeNodes();
      final now = DateTime.now();
      for (var i = 0; i < probes.length; i++) {
        health[i] = lk.evaluateProbe(
          health[i],
          probes[i],
          now,
          staleAfter: staleAfter,
        );
      }
      _notify(force: true);
    } finally {
      _probing = false;
    }
  }

  String get transmitterToReceiver =>
      lk.transmitterToReceiver(health[0], health[1]);

  /// Subscribes to a server stream and resubscribes with backoff after any
  /// error or close, so a restarted node is picked up without user action.
  void _keep(
    String name,
    Stream<Object> Function() open,
    void Function(Object) onData,
  ) {
    final state = streams[name]!;
    void subscribe() {
      if (_disposed) return;
      state.status = state.attempt == 0 ? 'connecting' : 'reconnecting';
      late final StreamSubscription<Object> sub;
      sub = open().listen(
        (event) {
          state
            ..status = 'streaming'
            ..attempt = 0
            ..messages += 1
            ..lastMessageAt = DateTime.now()
            ..lastError = null;
          onData(event);
        },
        onError: (Object error) {
          state.lastError = lk.describeError(error);
          unawaited(sub.cancel());
          _retry(state, subscribe);
        },
        onDone: () => _retry(state, subscribe),
        cancelOnError: true,
      );
      _subs.add(sub);
    }

    subscribe();
  }

  void _retry(StreamState state, void Function() subscribe) {
    if (_disposed) return;
    final delay = lk.reconnectDelay(state.attempt);
    state
      ..attempt += 1
      ..status =
          'reconnecting in ${(delay.inMilliseconds / 1000).toStringAsFixed(1)} s';
    _timers.add(Timer(delay, subscribe));
    _notify(force: true);
  }

  void _onTx(lk.TxEvent event) {
    if (!event.hasTrace()) return;
    final t = event.trace;
    _push(txFrames, Timed(t, DateTime.now()));
    if (t.transferId.isNotEmpty && t.originalBytes.isNotEmpty) {
      final x = transfers.putIfAbsent(
        t.transferId,
        () => ImageTransfer(t.transferId, t.fileName),
      );
      x.addOriginalChunk(
        t.mediaOffset.toInt(),
        t.originalBytes,
        t.totalBytes.toInt(),
      );
      _compare(x);
    }
    _notify();
  }

  void _onRx(lk.RxFrameTrace t) {
    if (rxFrames.isNotEmpty) {
      final prev = rxFrames.last.value.sequence.toInt();
      final seq = t.sequence.toInt();
      if (seq != prev + 1) rxSequenceJumps++; // includes subscriber drops
    }
    _push(rxFrames, Timed(t, DateTime.now()));
    _notify();
  }

  void _onEvent(lk.ExperimentEvent e) {
    onExperimentEvent?.call(e);
    final now = DateTime.now();
    if (e.hasMetrics()) {
      latestMetrics = e.metrics;
      latestMetricsAt = now;
    }
    if (e.hasDecision()) {
      decisions.add(DecisionRecord(e.decision, now));
      if (decisions.length > 30) decisions.removeAt(0);
    }
    if (e.hasAssessment()) {
      final a = e.assessment;
      // The new window's measured class is the outcome of the previous
      // window's prediction (consecutive, non-overlapping windows).
      if (assessments.isNotEmpty) {
        final prev = assessments.last;
        if (a.windowFirstSequence > prev.assessment.windowLastSequence) {
          prev.actualNext ??= a.measuredClass;
        }
      }
      assessments.add(AssessmentRecord(a, now));
      if (assessments.length > assessmentBufferSize) assessments.removeAt(0);
    }
    _notify();
  }

  void _onMedia(lk.MediaEvent e) {
    onMedia?.call(e);
    final id = e.media.transferId;
    if (id.isEmpty) return;
    final x = transfers.putIfAbsent(
      id,
      () => ImageTransfer(id, e.media.fileName),
    );
    x.addReconstructedChunk(
      e.offset.toInt(),
      e.data,
      e.media.totalSize.toInt(),
      e.endOfStream,
    );
    if (e.endOfStream) x.checksumValid = e.checksumValid;
    _compare(x);
    _notify(force: true);
  }

  /// PSNR/SSIM only when both the original (from Sender traces) and the
  /// receiver's reconstruction are complete and the file is a BMP.
  void _compare(ImageTransfer x) {
    if (x.metrics != null || !x.originalComplete || !x.reconstructedComplete) {
      return;
    }
    final orig = x.original!;
    final isBmp = orig.length > 2 && orig[0] == 0x42 && orig[1] == 0x4D;
    if (!isBmp) {
      x.error =
          'Not a BMP image: PSNR/SSIM are only computed for image transfers';
      return;
    }
    try {
      x.metrics = lk.compareBmp(orig, x.reconstructed!);
    } on FormatException catch (e) {
      x.error = e.message;
    }
  }

  /// The training/evaluation report of the loaded quality model.
  Future<void> fetchModelReport() async {
    final base = controllerHttp;
    if (base == null) {
      modelReportStatus =
          'controller HTTP address unknown (add ?controllerHttpPort=8080)';
      return;
    }
    try {
      final r = await http
          .get(base.replace(path: '/api/v1/ml/model'))
          .timeout(const Duration(seconds: 3));
      if (r.statusCode == 404) {
        modelReportStatus = 'no quality model loaded on the controller';
      } else if (r.statusCode != 200) {
        modelReportStatus = 'controller returned HTTP ${r.statusCode}';
      } else {
        final decoded = jsonDecode(r.body);
        if (decoded is! Map) {
          throw const FormatException('model report is not a JSON object');
        }
        modelReport = decoded.cast<String, Object?>();
        modelReportStatus = 'loaded';
      }
    } catch (error) {
      modelReportStatus = 'unavailable: $error';
    }
    _notify(force: true);
  }

  /// Latest sequence present in both the Sender and Receiver buffers, so the
  /// transmitted and received waveforms shown together are the same frame.
  (lk.TxFrameTrace, lk.RxFrameTrace)? latestPair() {
    for (final rx in rxFrames.reversed) {
      for (final tx in txFrames.reversed) {
        if (tx.value.sequence == rx.value.sequence) return (tx.value, rx.value);
      }
    }
    return null;
  }

  /// Live accuracy of predictions whose outcome has already been measured.
  ({int checked, int correct})? liveAccuracy() {
    final done = assessments.where((a) => a.correct != null).toList();
    if (done.isEmpty) return null;
    return (
      checked: done.length,
      correct: done.where((a) => a.correct!).length,
    );
  }

  void _push<T>(List<T> list, T value) {
    list.add(value);
    if (list.length > frameBufferSize) list.removeAt(0);
  }

  /// Frames arrive ~94/s; repaint at most ~8/s so the UI stays responsive.
  void _notify({bool force = false}) {
    if (_disposed) return;
    final now = DateTime.now();
    if (force ||
        now.difference(_lastNotify) > const Duration(milliseconds: 120)) {
      _lastNotify = now;
      _pendingNotify?.cancel();
      _pendingNotify = null;
      notifyListeners();
    } else {
      _pendingNotify ??= Timer(const Duration(milliseconds: 130), () {
        _pendingNotify = null;
        _notify(force: true);
      });
    }
  }

  @override
  void dispose() {
    _disposed = true;
    for (final t in _timers) {
      t.cancel();
    }
    _pendingNotify?.cancel();
    for (final s in _subs) {
      unawaited(s.cancel());
    }
    super.dispose();
  }
}
