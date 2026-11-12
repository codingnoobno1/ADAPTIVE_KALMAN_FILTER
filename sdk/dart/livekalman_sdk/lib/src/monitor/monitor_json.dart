/// Typed, validated view of the Controller's `GET /api/v1/monitor` response
/// (server/controller/core/monitor.go, schema_version "1").
///
/// Missing optional values stay `null`; they are never replaced by zeros.
/// Structural problems throw [FormatException] naming the offending field.
library;

const supportedMonitorSchema = '1';

final class MonitorSnapshot {
  const MonitorSnapshot({
    required this.generatedAt,
    required this.policy,
    required this.recommendOnly,
    required this.modelVersion,
    required this.runs,
  });

  final DateTime generatedAt;
  final String policy;
  final bool recommendOnly;
  final String? modelVersion;
  final List<MonitorRun> runs;

  factory MonitorSnapshot.fromJson(Object? json) {
    final m = _map(json, r'$');
    final schema = _string(m, 'schema_version', r'$');
    if (schema != supportedMonitorSchema) {
      throw FormatException(
        'Unsupported monitor schema "$schema" (expected $supportedMonitorSchema)',
      );
    }
    final runs = m['runs'];
    if (runs is! List) throw const FormatException(r'$.runs must be a list');
    return MonitorSnapshot(
      generatedAt: _time(m, 'generated_at', r'$'),
      policy: _string(m, 'policy', r'$'),
      recommendOnly: _bool(m, 'recommend_only', r'$'),
      modelVersion: _optString(m, 'quality_model_version', r'$'),
      runs: [
        for (var i = 0; i < runs.length; i++)
          MonitorRun.fromJson(runs[i], '\$.runs[$i]'),
      ],
    );
  }
}

final class MonitorRun {
  const MonitorRun({
    required this.runId,
    required this.connectionStatus,
    required this.streamStatus,
    required this.sequenceNumber,
    required this.timestamp,
    required this.ageMs,
    required this.framesLost,
    this.snr,
    this.ber,
    this.noiseVariance,
    this.phaseError,
    this.latencyMs,
    this.psnr,
    this.ssim,
    this.appliedRho,
    this.recommendedRho,
    this.recommendationSent,
    this.measuredClass,
    this.predictedClass,
    this.confidence,
    this.notes = const {},
  });

  final String runId;
  final String connectionStatus;
  final String streamStatus;
  final int sequenceNumber;
  final DateTime timestamp;
  final int ageMs;
  final int framesLost;
  final double? snr, ber, noiseVariance, phaseError, latencyMs, psnr, ssim;
  final double? appliedRho, recommendedRho;
  final bool? recommendationSent;
  final String? measuredClass, predictedClass;
  final double? confidence;
  final Map<String, String> notes;

  factory MonitorRun.fromJson(Object? json, String path) {
    final m = _map(json, path);
    const statuses = {'connected', 'connection_lost'};
    const streams = {'data_flow_active', 'data_flow_inactive'};
    final connection = _string(m, 'connection_status', path);
    final stream = _string(m, 'stream_status', path);
    if (!statuses.contains(connection)) {
      throw FormatException(
        '$path.connection_status "$connection" is not one of $statuses',
      );
    }
    if (!streams.contains(stream)) {
      throw FormatException(
        '$path.stream_status "$stream" is not one of $streams',
      );
    }
    final applied = m['applied'] is Map
        ? _map(m['applied'], '$path.applied')
        : const <String, Object?>{};
    final rec = m['recommended'] == null
        ? null
        : _map(m['recommended'], '$path.recommended');
    final ml = m['ml'] == null ? null : _map(m['ml'], '$path.ml');
    final ber = _optNum(m, 'ber', path);
    if (ber != null && (ber < 0 || ber > 1)) {
      throw FormatException('$path.ber $ber is outside [0, 1]');
    }
    return MonitorRun(
      runId: _string(m, 'run_id', path),
      connectionStatus: connection,
      streamStatus: stream,
      sequenceNumber: _int(m, 'sequence_number', path),
      timestamp: _time(m, 'timestamp', path),
      ageMs: _int(m, 'age_ms', path),
      framesLost: _int(m, 'frames_lost', path),
      snr: _optNum(m, 'snr', path),
      ber: ber,
      noiseVariance: _optNum(m, 'noise_variance', path),
      phaseError: _optNum(m, 'phase_error', path),
      latencyMs: _optNum(m, 'latency_ms', path),
      psnr: _optNum(m, 'psnr', path),
      ssim: _optNum(m, 'ssim', path),
      appliedRho: _optNum(applied, 'rho', '$path.applied'),
      recommendedRho: rec == null
          ? null
          : _optNum(rec, 'rho', '$path.recommended'),
      recommendationSent: rec == null ? null : rec['sent_to_receiver'] == true,
      measuredClass: ml == null
          ? null
          : _optString(ml, 'measured_class', '$path.ml'),
      predictedClass: ml == null
          ? null
          : _optString(ml, 'predicted_class', '$path.ml'),
      confidence: ml == null ? null : _optNum(ml, 'confidence', '$path.ml'),
      notes: {
        for (final k in ['ber_note', 'phase_error_note', 'image_metrics_note'])
          if (m[k] is String && (m[k] as String).isNotEmpty) k: m[k] as String,
      },
    );
  }
}

Map<String, Object?> _map(Object? v, String path) {
  if (v is Map) return v.cast<String, Object?>();
  throw FormatException('$path must be an object');
}

String _string(Map<String, Object?> m, String key, String path) {
  final v = m[key];
  if (v is String) return v;
  throw FormatException('$path.$key must be a string');
}

String? _optString(Map<String, Object?> m, String key, String path) {
  final v = m[key];
  if (v == null) return null;
  if (v is String) return v.isEmpty ? null : v;
  throw FormatException('$path.$key must be a string or null');
}

bool _bool(Map<String, Object?> m, String key, String path) {
  final v = m[key];
  if (v is bool) return v;
  throw FormatException('$path.$key must be a boolean');
}

int _int(Map<String, Object?> m, String key, String path) {
  final v = m[key];
  if (v is int) return v;
  if (v is num && v == v.roundToDouble()) return v.toInt();
  throw FormatException('$path.$key must be an integer');
}

double? _optNum(Map<String, Object?> m, String key, String path) {
  final v = m[key];
  if (v == null) return null;
  if (v is num && v.isFinite) return v.toDouble();
  throw FormatException('$path.$key must be a finite number or null');
}

DateTime _time(Map<String, Object?> m, String key, String path) {
  final v = _string(m, key, path);
  final t = DateTime.tryParse(v);
  if (t == null) {
    throw FormatException('$path.$key "$v" is not an ISO-8601 time');
  }
  return t;
}
