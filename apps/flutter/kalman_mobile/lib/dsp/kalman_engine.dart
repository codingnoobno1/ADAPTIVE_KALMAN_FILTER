import 'dart:math' as math;
import 'dart:typed_data';

import '../models/kalman_parameters.dart';

/// Number of BPSK symbols averaged per unbiased DC measurement block,
/// matching `DCBlockSymbols = 8` in `shared/dsp/kalman.go`.
const int dcBlockSymbols = 8;

/// Tuned fixed tracking ratio rho = Q / R from `docs/ml-policy.md`.
const double defaultRuleRho = 0.0268;

/// Built-in signal/sensor profiles for the on-device mobile Kalman workbench.
enum SimulationProfile {
  driftingBpsk(
    'Drifting BPSK Link',
    '512-sample BPSK frames with Ornstein-Uhlenbeck DC drift, fading & AWGN.',
  ),
  imuSensorBias(
    'IMU Tilt / Gyro Bias',
    'Continuous 1-axis sensor random-walk bias with Gaussian measurement jitter.',
  ),
  stepResponse(
    'Step-Response Benchmark',
    'Periodic ±0.75 V DC step transitions testing innovation gate & settling.',
  );

  const SimulationProfile(this.title, this.subtitle);
  final String title;
  final String subtitle;
}

/// Result of a single scalar Kalman filter update step exposing all internal
/// Riccati and innovation quantities.
final class KalmanStepResult {
  const KalmanStepResult({
    required this.x,
    required this.pPrior,
    required this.pPosterior,
    required this.gainK,
    required this.measurementZ,
    required this.innovationY,
    required this.innovationCovS,
    required this.nis,
    required this.stepCount,
  });

  final double x;
  final double pPrior;
  final double pPosterior;
  final double gainK;
  final double measurementZ;
  final double innovationY;
  final double innovationCovS;
  final double nis;
  final int stepCount;
}

/// Scalar random-walk Kalman filter retaining full Riccati & innovation state.
///
/// Equations match `shared/dsp/kalman.go` (`Kalman.Update`):
///   P_k^- = P_{k-1} + Q
///   K_k   = P_k^- / (P_k^- + R)
///   ỹ_k   = z_k - x_{k-1}
///   x_k   = x_{k-1} + K_k * ỹ_k
///   P_k   = (1 - K_k) * P_k^-
final class ScalarKalmanFilter {
  ScalarKalmanFilter({double q = 0.01, double r = 0.25})
    : _q = q,
      _r = r,
      _p = 1.0,
      _pPrior = 1.0 + q;

  double _x = 0.0;
  double _p;
  double _pPrior;
  double _q;
  double _r;
  double _gainK = 0.0;
  double _lastZ = 0.0;
  double _innovationY = 0.0;
  double _innovationCovS = 1.0;
  double _nis = 0.0;
  bool _ready = false;
  int _stepCount = 0;
  int _resetCount = 0;

  double get x => _x;
  double get p => _p;
  double get pPrior => _pPrior;
  double get q => _q;
  double get r => _r;
  double get gainK => _gainK;
  double get lastZ => _lastZ;
  double get innovationY => _innovationY;
  double get innovationCovS => _innovationCovS;
  double get nis => _nis;
  bool get ready => _ready;
  int get stepCount => _stepCount;
  int get resetCount => _resetCount;

  /// Initializes state to 0 (matching `ProcessBPSK` in `shared/dsp/kalman.go`
  /// where no DC offset is assumed prior to the first block measurement).
  void primeZeroState() {
    if (!_ready) {
      _x = 0.0;
      _ready = true;
    }
  }

  KalmanStepResult update(double z) {
    if (!_ready) {
      _x = z;
      _ready = true;
    }
    final priorX = _x;
    _pPrior = _p + _q;
    _innovationCovS = _pPrior + _r;
    _gainK = _innovationCovS > 0 ? _pPrior / _innovationCovS : 0.0;
    _innovationY = z - priorX;
    _x = priorX + _gainK * _innovationY;
    _p = (1.0 - _gainK) * _pPrior;
    _nis = _innovationCovS > 0
        ? (_innovationY * _innovationY) / _innovationCovS
        : 0.0;
    _lastZ = z;
    _stepCount++;
    return KalmanStepResult(
      x: _x,
      pPrior: _pPrior,
      pPosterior: _p,
      gainK: _gainK,
      measurementZ: z,
      innovationY: _innovationY,
      innovationCovS: _innovationCovS,
      nis: _nis,
      stepCount: _stepCount,
    );
  }

  void configure({required double q, required double r, bool reset = false}) {
    if (!q.isFinite || q <= 0) {
      throw ArgumentError.value(q, 'q', 'Kalman Q must be finite and > 0');
    }
    if (!r.isFinite || r <= 0) {
      throw ArgumentError.value(r, 'r', 'Kalman R must be finite and > 0');
    }
    _q = q;
    _r = r;
    if (reset) {
      this.reset();
    }
  }

  void reset() {
    _x = 0.0;
    _p = 1.0;
    _pPrior = 1.0 + _q;
    _gainK = 0.0;
    _innovationY = 0.0;
    _innovationCovS = _pPrior + _r;
    _nis = 0.0;
    _ready = false;
    _stepCount = 0;
    _resetCount++;
  }
}

/// Metrics returned by `processBpskFrame`, mirroring `dsp.FrameMetrics` in Go.
final class BpskFrameMetrics {
  const BpskFrameMetrics({
    required this.receivedPower,
    required this.snrDb,
    required this.noiseVariance,
    required this.frameMean,
    required this.dcEstimate,
    required this.ber,
    required this.comparedBits,
    required this.bitErrors,
    required this.decodedBytes,
  });

  final double receivedPower;
  final double snrDb;
  final double noiseVariance;
  final double frameMean;
  final double dcEstimate;
  final double ber;
  final int comparedBits;
  final int bitErrors;
  final Uint8List decodedBytes;
}

/// Demodulates one real-valued BPSK frame with decision-free Kalman DC
/// tracking, matching `dsp.ProcessBPSK` in `shared/dsp/kalman.go`.
BpskFrameMetrics processBpskFrame({
  required ScalarKalmanFilter filter,
  required List<double> samples,
  required int samplesPerSymbol,
  Uint8List? referenceBits,
}) {
  if (samplesPerSymbol <= 0 || samples.isEmpty) {
    return BpskFrameMetrics(
      receivedPower: 0,
      snrDb: 0,
      noiseVariance: 0,
      frameMean: 0,
      dcEstimate: filter.x,
      ber: 0,
      comparedBits: 0,
      bitErrors: 0,
      decodedBytes: Uint8List(0),
    );
  }

  var amplitudeSum = 0.0;
  var receivedPower = 0.0;
  var sampleSum = 0.0;
  for (final z in samples) {
    amplitudeSum += z.abs();
    receivedPower += z * z;
    sampleSum += z;
  }
  final amplitude = amplitudeSum / samples.length;
  filter.primeZeroState();

  var blockSum = 0.0;
  var blockSamples = 0;
  var noisePower = 0.0;
  var compared = 0;
  var errors = 0;
  final totalSymbols = samples.length ~/ samplesPerSymbol;
  if (totalSymbols == 0) {
    return BpskFrameMetrics(
      receivedPower: 0,
      snrDb: 0,
      noiseVariance: 0,
      frameMean: 0,
      dcEstimate: filter.x,
      ber: 0,
      comparedBits: 0,
      bitErrors: 0,
      decodedBytes: Uint8List(0),
    );
  }

  final decoded = Uint8List((totalSymbols + 7) ~/ 8);
  for (
    var symbol = 0, start = 0;
    start + samplesPerSymbol <= samples.length;
    symbol++, start += samplesPerSymbol
  ) {
    var sum = 0.0;
    final dc = filter.x;
    for (var i = start; i < start + samplesPerSymbol; i++) {
      final z = samples[i];
      sum += z - dc;
      final decision = z >= 0 ? amplitude : -amplitude;
      final d = z - decision;
      noisePower += d * d;
      blockSum += z;
    }
    final got = sum >= 0;
    blockSamples += samplesPerSymbol;
    if ((symbol + 1) % dcBlockSymbols == 0) {
      filter.update(blockSum / blockSamples);
      blockSum = 0.0;
      blockSamples = 0;
    }
    if (got) {
      decoded[symbol ~/ 8] |= 1 << (symbol % 8);
    }
    if (referenceBits != null && (symbol ~/ 8) < referenceBits.length) {
      compared++;
      final refBit =
          (referenceBits[symbol ~/ 8] & (1 << (symbol % 8))) != 0;
      if (got != refBit) {
        errors++;
      }
    }
  }

  final n = (totalSymbols * samplesPerSymbol).toDouble();
  noisePower /= n;
  final snr = noisePower > 0
      ? 10.0 * math.log((amplitude * amplitude) / noisePower) / math.ln10
      : 100.0;
  final ber = compared > 0 ? errors / compared : 0.0;

  return BpskFrameMetrics(
    receivedPower: receivedPower / samples.length,
    snrDb: snr,
    noiseVariance: noisePower,
    frameMean: sampleSum / samples.length,
    dcEstimate: filter.x,
    ber: ber,
    comparedBits: compared,
    bitErrors: errors,
    decodedBytes: decoded,
  );
}

/// Stateful on-device signal & sensor workbench producing full
/// [KalmanParameterSnapshot] telemetry without requiring external servers.
final class OnDeviceKalmanWorkbench {
  OnDeviceKalmanWorkbench({
    int seed = 42,
    double initialQ = 0.0067,
    double initialR = 0.25,
  }) : _rng = math.Random(seed),
       filter = ScalarKalmanFilter(q: initialQ, r: initialR);

  final math.Random _rng;
  final ScalarKalmanFilter filter;

  SimulationProfile profile = SimulationProfile.driftingBpsk;
  bool autoRuleAdaptation = true;
  double amplitude = 1.0;
  double noiseStddev = 0.50;
  double driftStddev = 0.014;
  double fadingDepth = 0.20;

  int _sequence = 0;
  int _configVersion = 1;
  double _trueDc = 0.0;
  double _fadingPhase = 0.0;
  double _pendingDisturbance = 0.0;
  final List<double> _recentInnovations = <double>[];

  double get trueDc => _trueDc;
  int get sequence => _sequence;

  /// Injects an immediate step offset into the simulated channel/sensor state
  /// so operators can observe transient innovation ỹ_k, NIS, and settling time.
  void injectStepDisturbance(double deltaVolts) {
    _pendingDisturbance += deltaVolts;
  }

  void updateFilterTuning({
    required double q,
    required double r,
    bool reset = false,
  }) {
    filter.configure(q: q, r: r, reset: reset);
    _configVersion++;
  }

  void resetAll() {
    filter.reset();
    _sequence = 0;
    _trueDc = 0.0;
    _fadingPhase = 0.0;
    _pendingDisturbance = 0.0;
    _recentInnovations.clear();
  }

  double _nextGaussian() {
    final u1 = math.max(1e-12, _rng.nextDouble());
    final u2 = _rng.nextDouble();
    return math.sqrt(-2.0 * math.log(u1)) * math.cos(2.0 * math.pi * u2);
  }

  /// Advances the workbench by one frame/measurement and returns a complete
  /// [KalmanParameterSnapshot] covering all parameters.
  KalmanParameterSnapshot nextFrame() {
    _sequence++;
    final started = DateTime.now();

    if (_pendingDisturbance != 0.0) {
      _trueDc += _pendingDisturbance;
      _pendingDisturbance = 0.0;
    }

    switch (profile) {
      case SimulationProfile.driftingBpsk:
        return _stepBpsk(started);
      case SimulationProfile.imuSensorBias:
        return _stepSensor(started, stepMode: false);
      case SimulationProfile.stepResponse:
        return _stepSensor(started, stepMode: true);
    }
  }

  KalmanParameterSnapshot _stepBpsk(DateTime started) {
    const symbols = 64;
    const samplesPerSymbol = 8;
    final refBits = Uint8List((symbols + 7) ~/ 8);
    final samples = List<double>.filled(symbols * samplesPerSymbol, 0.0);
    final phaseStep = 2.0 * math.pi / 4096.0;

    for (var s = 0; s < symbols; s++) {
      final one = _rng.nextBool();
      if (one) {
        refBits[s ~/ 8] |= 1 << (s % 8);
      }
      final ideal = one ? amplitude : -amplitude;
      for (var j = 0; j < samplesPerSymbol; j++) {
        final fadeGain =
            1.0 - fadingDepth * (1.0 + math.sin(_fadingPhase)) / 2.0;
        _fadingPhase += phaseStep;
        _trueDc = _trueDc * 0.9992 + _nextGaussian() * driftStddev;
        final clean = ideal * fadeGain + _trueDc;
        samples[s * samplesPerSymbol + j] =
            clean + _nextGaussian() * noiseStddev;
      }
    }

    final metrics = processBpskFrame(
      filter: filter,
      samples: samples,
      samplesPerSymbol: samplesPerSymbol,
      referenceBits: refBits,
    );

    double? recQ;
    double? recR;
    double? recRho;
    if (autoRuleAdaptation) {
      recR = metrics.noiseVariance.clamp(0.01, 5.0);
      recRho = defaultRuleRho;
      recQ = recRho * recR;
      if ((recR - filter.r).abs() > 0.015) {
        filter.configure(q: recQ, r: recR);
        _configVersion++;
      }
    }

    final rms = _pushInnovation(filter.innovationY);
    final measuredClass = _classifyChannel(metrics.snrDb, metrics.ber);
    final elapsedMs =
        DateTime.now().difference(started).inMicroseconds / 1000.0;

    return KalmanParameterSnapshot(
      timestamp: DateTime.now(),
      sequence: _sequence,
      stepCount: filter.stepCount,
      ready: filter.ready,
      isLiveSource: false,
      stateEstimateX: filter.x,
      priorCovariancePMinus: filter.pPrior,
      posteriorCovarianceP: filter.p,
      kalmanGainK: filter.gainK,
      trueStateOffset: _trueDc,
      processNoiseQ: filter.q,
      measurementNoiseR: filter.r,
      rawMeasurementZ: metrics.frameMean,
      innovationY: filter.innovationY,
      innovationCovarianceS: filter.innovationCovS,
      normalizedInnovationSquared: filter.nis,
      residualRms: rms,
      snrDb: metrics.snrDb,
      noiseVariance: metrics.noiseVariance,
      receivedPower: metrics.receivedPower,
      ber: metrics.ber,
      comparedBits: metrics.comparedBits,
      bitErrors: metrics.bitErrors,
      latencyMs: elapsedMs,
      queueDepth: 0,
      resetCount: filter.resetCount,
      activeConfigVersion: _configVersion,
      policyName: autoRuleAdaptation ? 'rule' : 'manual',
      recommendedQ: recQ,
      recommendedR: recR,
      predictedRho: recRho,
      measuredClass: measuredClass,
      predictedClass: measuredClass,
      mlConfidence: 0.88,
    );
  }

  KalmanParameterSnapshot _stepSensor(
    DateTime started, {
    required bool stepMode,
  }) {
    if (stepMode) {
      if (_sequence % 40 == 1) {
        _trueDc = (_sequence ~/ 40).isEven ? 0.75 : -0.75;
      }
    } else {
      _trueDc =
          _trueDc * 0.995 +
          0.35 * math.sin(_sequence * 0.07) * 0.04 +
          _nextGaussian() * (driftStddev * 2.5);
    }

    final z = _trueDc + _nextGaussian() * noiseStddev;
    final noiseVar = noiseStddev * noiseStddev;

    double? recQ;
    double? recR;
    double? recRho;
    if (autoRuleAdaptation) {
      recR = noiseVar.clamp(0.005, 5.0);
      recRho = stepMode ? 0.08 : defaultRuleRho;
      recQ = recRho * recR;
      if ((recR - filter.r).abs() > 0.01 || (recQ - filter.q).abs() > 0.002) {
        filter.configure(q: recQ, r: recR);
        _configVersion++;
      }
    }

    filter.update(z);
    final rms = _pushInnovation(filter.innovationY);
    final signalPower = _trueDc * _trueDc + 1e-6;
    final snrDb = noiseVar > 0
        ? 10.0 * math.log(signalPower / noiseVar) / math.ln10
        : 40.0;
    final elapsedMs =
        DateTime.now().difference(started).inMicroseconds / 1000.0;

    return KalmanParameterSnapshot(
      timestamp: DateTime.now(),
      sequence: _sequence,
      stepCount: filter.stepCount,
      ready: filter.ready,
      isLiveSource: false,
      stateEstimateX: filter.x,
      priorCovariancePMinus: filter.pPrior,
      posteriorCovarianceP: filter.p,
      kalmanGainK: filter.gainK,
      trueStateOffset: _trueDc,
      processNoiseQ: filter.q,
      measurementNoiseR: filter.r,
      rawMeasurementZ: z,
      innovationY: filter.innovationY,
      innovationCovarianceS: filter.innovationCovS,
      normalizedInnovationSquared: filter.nis,
      residualRms: rms,
      snrDb: snrDb,
      noiseVariance: noiseVar,
      receivedPower: z * z,
      latencyMs: elapsedMs,
      queueDepth: 0,
      resetCount: filter.resetCount,
      activeConfigVersion: _configVersion,
      policyName: autoRuleAdaptation ? 'rule' : 'manual',
      recommendedQ: recQ,
      recommendedR: recR,
      predictedRho: recRho,
      measuredClass: _classifyChannel(snrDb, null),
      predictedClass: _classifyChannel(snrDb, null),
      mlConfidence: 0.85,
    );
  }

  double _pushInnovation(double y) {
    _recentInnovations.add(y);
    if (_recentInnovations.length > 32) {
      _recentInnovations.removeAt(0);
    }
    var sumSq = 0.0;
    for (final v in _recentInnovations) {
      sumSq += v * v;
    }
    return math.sqrt(sumSq / _recentInnovations.length);
  }

  String _classifyChannel(double snrDb, double? ber) {
    if (ber != null) {
      if (ber <= 1e-3) return 'good';
      if (ber <= 2e-2) return 'moderate';
      return 'poor';
    }
    if (snrDb >= 10.0) return 'good';
    if (snrDb >= 5.0) return 'moderate';
    return 'poor';
  }
}
