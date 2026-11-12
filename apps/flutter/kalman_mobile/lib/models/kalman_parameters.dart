import 'dart:convert';
import 'dart:math' as math;

/// Categories grouping all measured, derived, and ML-assessed parameters.
enum ParameterCategory {
  stateAndCovariance('State & Covariance'),
  noiseAndInnovation('Noise & Innovation'),
  channelAndSignal('Channel & Signal'),
  adaptiveAndMl('Adaptive & ML');

  const ParameterCategory(this.label);
  final String label;
}

/// Provenance of a parameter value so operators always see what came directly
/// over the wire vs deterministic Riccati equations vs unavailable fields.
enum ValueProvenance {
  directMeasurement('Direct'),
  riccatiDerived('Riccati Derived'),
  mlPredicted('ML Policy'),
  unavailable('Not Measured');

  const ValueProvenance(this.badge);
  final String badge;
}

/// Descriptor for one parameter rendered in the mobile Parameter Matrix and
/// formula inspector sheet.
final class ParameterDescriptor {
  const ParameterDescriptor({
    required this.id,
    required this.symbol,
    required this.name,
    required this.category,
    required this.provenance,
    required this.formula,
    required this.description,
    this.unit = '',
    this.formattedValue = '—',
    this.rawValue,
    this.healthy,
    this.note,
  });

  final String id;
  final String symbol;
  final String name;
  final ParameterCategory category;
  final ValueProvenance provenance;
  final String formula;
  final String description;
  final String unit;
  final String formattedValue;
  final double? rawValue;
  final bool? healthy;
  final String? note;
}

/// Exact algebraic Riccati steady-state gain K_inf for scalar random-walk
/// model x_k = x_{k-1} + w_k, z_k = x_k + v_k with tracking ratio rho = Q / R.
double steadyStateKalmanGain(double rho) {
  if (!rho.isFinite || rho <= 0) return 0;
  return (-rho + math.sqrt(rho * rho + 4.0 * rho)) / 2.0;
}

/// Exact algebraic Riccati steady-state posterior covariance P_inf = K_inf * R.
double steadyStatePosteriorCovariance(double q, double r) {
  if (!q.isFinite || !r.isFinite || q <= 0 || r <= 0) return 0;
  return steadyStateKalmanGain(q / r) * r;
}

/// Complete immutable snapshot of all Kalman filter, innovation, BPSK channel,
/// media quality, and ML policy parameters at one frame/step.
final class KalmanParameterSnapshot {
  const KalmanParameterSnapshot({
    required this.timestamp,
    required this.sequence,
    required this.stepCount,
    required this.ready,
    required this.isLiveSource,
    required this.stateEstimateX,
    required this.priorCovariancePMinus,
    required this.posteriorCovarianceP,
    required this.kalmanGainK,
    required this.processNoiseQ,
    required this.measurementNoiseR,
    required this.rawMeasurementZ,
    required this.innovationY,
    required this.innovationCovarianceS,
    required this.normalizedInnovationSquared,
    required this.residualRms,
    this.trueStateOffset,
    this.snrDb,
    this.noiseVariance,
    this.receivedPower,
    this.ber,
    this.comparedBits,
    this.bitErrors,
    this.psnrDb,
    this.ssim,
    this.latencyMs,
    this.queueDepth,
    this.sequenceGaps = 0,
    this.resetCount = 0,
    this.activeConfigVersion = 1,
    this.proposedConfigVersion,
    this.effectiveSequence,
    this.policyName = 'manual',
    this.recommendOnly = false,
    this.recommendedQ,
    this.recommendedR,
    this.predictedRho,
    this.measuredClass,
    this.predictedClass,
    this.mlConfidence,
    this.classProbabilities = const [],
    this.featureNames = const [],
    this.featureValues = const [],
  });

  final DateTime timestamp;
  final int sequence;
  final int stepCount;
  final bool ready;
  final bool isLiveSource;

  // 1. State & Covariance
  final double stateEstimateX;
  final double priorCovariancePMinus;
  final double posteriorCovarianceP;
  final double kalmanGainK;
  final double? trueStateOffset;

  // 2. Noise & Innovation
  final double processNoiseQ;
  final double measurementNoiseR;
  final double rawMeasurementZ;
  final double innovationY;
  final double innovationCovarianceS;
  final double normalizedInnovationSquared;
  final double residualRms;

  // 3. BPSK Channel & Media Quality
  final double? snrDb;
  final double? noiseVariance;
  final double? receivedPower;
  final double? ber;
  final int? comparedBits;
  final int? bitErrors;
  final double? psnrDb;
  final double? ssim;
  final double? latencyMs;
  final int? queueDepth;
  final int sequenceGaps;
  final int resetCount;

  // 4. Adaptive Policy & ML Assessment
  final int activeConfigVersion;
  final int? proposedConfigVersion;
  final int? effectiveSequence;
  final String policyName;
  final bool recommendOnly;
  final double? recommendedQ;
  final double? recommendedR;
  final double? predictedRho;
  final String? measuredClass;
  final String? predictedClass;
  final double? mlConfidence;
  final List<double> classProbabilities;
  final List<String> featureNames;
  final List<double> featureValues;

  /// Tracking ratio rho = Q / R.
  double get trackingRatioRho =>
      measurementNoiseR > 0 ? processNoiseQ / measurementNoiseR : 0.0;

  /// Log10 tracking ratio log10(Q / R).
  double get log10Rho => trackingRatioRho > 0
      ? math.log(trackingRatioRho) / math.ln10
      : double.nan;

  /// Steady-state Kalman gain K_inf from algebraic Riccati solution.
  double get steadyStateGain => steadyStateKalmanGain(trackingRatioRho);

  /// Steady-state posterior error covariance P_inf = K_inf * R.
  double get steadyStateCovariance =>
      steadyStatePosteriorCovariance(processNoiseQ, measurementNoiseR);

  /// Absolute Riccati covariance gap |P_k - P_inf|.
  double get covarianceGap =>
      (posteriorCovarianceP - steadyStateCovariance).abs();

  /// 95% 2-sigma innovation confidence half-width 2 * sqrt(S_k).
  double get innovationBound95 =>
      innovationCovarianceS > 0 ? 2.0 * math.sqrt(innovationCovarianceS) : 0.0;

  /// Chi-squared(1) 95% consistency check: NIS <= 3.841459.
  bool get nisConsistent95 =>
      normalizedInnovationSquared.isFinite &&
      normalizedInnovationSquared <= 3.841459;

  /// Ground-truth estimation error |x_k - x_true| when available in simulator.
  double? get trueTrackingError => trueStateOffset == null
      ? null
      : (stateEstimateX - trueStateOffset!).abs();

  static String _fmt(double? value, {int digits = 4}) {
    if (value == null || !value.isFinite) return '—';
    final abs = value.abs();
    if (abs > 0 && abs < 1e-3) return value.toStringAsExponential(2);
    return value.toStringAsFixed(digits);
  }

  /// Expands all parameters into structured descriptors for the mobile UI.
  List<ParameterDescriptor> toDescriptors() {
    final riccatiProv = isLiveSource
        ? ValueProvenance.riccatiDerived
        : ValueProvenance.directMeasurement;
    return [
      // --- Category 1: State & Covariance ---
      ParameterDescriptor(
        id: 'state_x',
        symbol: 'x_k',
        name: 'Kalman State (DC Estimate)',
        category: ParameterCategory.stateAndCovariance,
        provenance: ValueProvenance.directMeasurement,
        formula: 'x_k = x_{k-1} + K_k (z_k - x_{k-1})',
        description:
            'Posterior scalar Kalman estimate of the slowly drifting channel DC offset.',
        unit: 'V',
        formattedValue: _fmt(stateEstimateX, digits: 4),
        rawValue: stateEstimateX,
        healthy: stateEstimateX.isFinite,
      ),
      ParameterDescriptor(
        id: 'cov_p_minus',
        symbol: 'P_k^-',
        name: 'Prior Error Covariance',
        category: ParameterCategory.stateAndCovariance,
        provenance: riccatiProv,
        formula: 'P_k^- = P_{k-1} + Q',
        description:
            'Predicted estimation error variance prior to assimilating measurement z_k.',
        unit: 'V²',
        formattedValue: _fmt(priorCovariancePMinus, digits: 5),
        rawValue: priorCovariancePMinus,
        healthy: priorCovariancePMinus > 0,
      ),
      ParameterDescriptor(
        id: 'cov_p',
        symbol: 'P_k',
        name: 'Posterior Error Covariance',
        category: ParameterCategory.stateAndCovariance,
        provenance: riccatiProv,
        formula: 'P_k = (1 - K_k) P_k^-',
        description:
            'Updated state estimation error variance after Kalman measurement update.',
        unit: 'V²',
        formattedValue: _fmt(posteriorCovarianceP, digits: 5),
        rawValue: posteriorCovarianceP,
        healthy: posteriorCovarianceP >= 0,
      ),
      ParameterDescriptor(
        id: 'gain_k',
        symbol: 'K_k',
        name: 'Kalman Gain',
        category: ParameterCategory.stateAndCovariance,
        provenance: riccatiProv,
        formula: 'K_k = P_k^- / (P_k^- + R)',
        description:
            'Optimal blending weight in (0, 1) balancing prior state prediction against measurement z_k.',
        formattedValue: _fmt(kalmanGainK, digits: 4),
        rawValue: kalmanGainK,
        healthy: kalmanGainK > 0 && kalmanGainK < 1,
      ),
      ParameterDescriptor(
        id: 'gain_k_inf',
        symbol: 'K_∞',
        name: 'Steady-State Riccati Gain',
        category: ParameterCategory.stateAndCovariance,
        provenance: ValueProvenance.riccatiDerived,
        formula: 'K_∞ = (-ρ + √(ρ² + 4ρ)) / 2',
        description:
            'Asymptotic Kalman gain determined solely by tracking ratio ρ = Q / R.',
        formattedValue: _fmt(steadyStateGain, digits: 4),
        rawValue: steadyStateGain,
      ),
      ParameterDescriptor(
        id: 'cov_gap',
        symbol: '|P_k - P_∞|',
        name: 'Riccati Convergence Gap',
        category: ParameterCategory.stateAndCovariance,
        provenance: ValueProvenance.riccatiDerived,
        formula: '|P_k - K_∞ R|',
        description:
            'Distance from asymptotic Riccati covariance; approaches 0 once transient startup settles.',
        unit: 'V²',
        formattedValue: _fmt(covarianceGap, digits: 5),
        rawValue: covarianceGap,
        healthy: covarianceGap < 0.05,
        note: 'Step k = $stepCount · Resets = $resetCount',
      ),
      ParameterDescriptor(
        id: 'true_err',
        symbol: '|e_k|',
        name: 'True State Tracking Error',
        category: ParameterCategory.stateAndCovariance,
        provenance: trueTrackingError == null
            ? ValueProvenance.unavailable
            : ValueProvenance.directMeasurement,
        formula: '|x_k - x_true|',
        description:
            'Absolute DC estimation error against synthetic ground-truth channel offset.',
        unit: 'V',
        formattedValue: _fmt(trueTrackingError, digits: 4),
        rawValue: trueTrackingError,
        note: trueTrackingError == null
            ? 'Unobservable on live physical/remote links'
            : null,
      ),

      // --- Category 2: Noise & Innovation ---
      ParameterDescriptor(
        id: 'noise_q',
        symbol: 'Q',
        name: 'Process Noise Covariance',
        category: ParameterCategory.noiseAndInnovation,
        provenance: ValueProvenance.directMeasurement,
        formula: 'E[w_k²] = Q = ρ · R',
        description:
            'Assumed random-walk variance per DC update block; larger Q tracks rapid drift faster.',
        unit: 'V²',
        formattedValue: _fmt(processNoiseQ, digits: 5),
        rawValue: processNoiseQ,
        healthy: processNoiseQ > 0,
      ),
      ParameterDescriptor(
        id: 'noise_r',
        symbol: 'R',
        name: 'Measurement Noise Covariance',
        category: ParameterCategory.noiseAndInnovation,
        provenance: ValueProvenance.directMeasurement,
        formula: 'E[v_k²] = R',
        description:
            'Assumed variance of block-mean measurements; larger R smooths symbol and AWGN jitter.',
        unit: 'V²',
        formattedValue: _fmt(measurementNoiseR, digits: 4),
        rawValue: measurementNoiseR,
        healthy: measurementNoiseR > 0,
      ),
      ParameterDescriptor(
        id: 'ratio_rho',
        symbol: 'ρ = Q/R',
        name: 'Kalman Tracking Ratio',
        category: ParameterCategory.noiseAndInnovation,
        provenance: ValueProvenance.riccatiDerived,
        formula: 'ρ = Q / R',
        description:
            'Scale-invariant tuning ratio governing filter bandwidth (rule baseline ρ = 0.0268).',
        formattedValue: _fmt(trackingRatioRho, digits: 5),
        rawValue: trackingRatioRho,
        note: log10Rho.isFinite
            ? 'log10(ρ) = ${log10Rho.toStringAsFixed(2)}'
            : null,
      ),
      ParameterDescriptor(
        id: 'meas_z',
        symbol: 'z_k',
        name: 'Raw Block/Frame Mean',
        category: ParameterCategory.noiseAndInnovation,
        provenance: ValueProvenance.directMeasurement,
        formula: 'z_k = (1/N) Σ sample[i]',
        description:
            'Decision-free unbiased DC offset reading from balanced BPSK symbols.',
        unit: 'V',
        formattedValue: _fmt(rawMeasurementZ, digits: 4),
        rawValue: rawMeasurementZ,
      ),
      ParameterDescriptor(
        id: 'innov_y',
        symbol: 'ỹ_k',
        name: 'Innovation (Residual)',
        category: ParameterCategory.noiseAndInnovation,
        provenance: riccatiProv,
        formula: 'ỹ_k = z_k - x_{k-1}',
        description:
            'New information brought by z_k; white zero-mean sequence when Q and R match the channel.',
        unit: 'V',
        formattedValue: _fmt(innovationY, digits: 4),
        rawValue: innovationY,
        note: '±2√S_k = ±${_fmt(innovationBound95, digits: 3)} V',
      ),
      ParameterDescriptor(
        id: 'innov_s',
        symbol: 'S_k',
        name: 'Innovation Covariance',
        category: ParameterCategory.noiseAndInnovation,
        provenance: riccatiProv,
        formula: 'S_k = P_k^- + R',
        description:
            'Predicted variance of innovation ỹ_k used to normalize filter consistency.',
        unit: 'V²',
        formattedValue: _fmt(innovationCovarianceS, digits: 4),
        rawValue: innovationCovarianceS,
      ),
      ParameterDescriptor(
        id: 'nis',
        symbol: 'NIS_k',
        name: 'Normalized Innovation Squared',
        category: ParameterCategory.noiseAndInnovation,
        provenance: riccatiProv,
        formula: 'NIS_k = ỹ_k² / S_k ~ χ²(1)',
        description:
            'Chi-squared(1) filter consistency statistic; values > 3.84 indicate unmodeled drift or underestimated Q/R.',
        formattedValue: _fmt(normalizedInnovationSquared, digits: 3),
        rawValue: normalizedInnovationSquared,
        healthy: nisConsistent95,
        note: nisConsistent95 ? 'Within 95% χ²(1) gate' : 'Exceeds 3.841 gate',
      ),
      ParameterDescriptor(
        id: 'res_rms',
        symbol: 'RMS(ỹ)',
        name: 'Rolling Innovation RMS',
        category: ParameterCategory.noiseAndInnovation,
        provenance: ValueProvenance.riccatiDerived,
        formula: '√((1/W) Σ ỹ_i²)',
        description:
            'Root-mean-square innovation magnitude over recent rolling telemetry window.',
        unit: 'V',
        formattedValue: _fmt(residualRms, digits: 4),
        rawValue: residualRms,
      ),

      // --- Category 3: BPSK Channel & Signal Quality ---
      ParameterDescriptor(
        id: 'snr_db',
        symbol: 'SNR',
        name: 'Signal-to-Noise Ratio',
        category: ParameterCategory.channelAndSignal,
        provenance: snrDb == null
            ? ValueProvenance.unavailable
            : ValueProvenance.directMeasurement,
        formula: '10 log10(Â² / σ̂²)',
        description:
            'Decision-directed frame SNR estimated directly from raw received samples.',
        unit: ' dB',
        formattedValue: _fmt(snrDb, digits: 2),
        rawValue: snrDb,
        healthy: snrDb == null ? null : snrDb! >= 5.0,
      ),
      ParameterDescriptor(
        id: 'noise_var',
        symbol: 'σ̂²',
        name: 'Channel Noise Variance',
        category: ParameterCategory.channelAndSignal,
        provenance: noiseVariance == null
            ? ValueProvenance.unavailable
            : ValueProvenance.directMeasurement,
        formula: '(1/N) Σ (z_i - d_i)²',
        description:
            'Estimated AWGN sample variance driving adaptive measurement covariance R.',
        unit: 'V²',
        formattedValue: _fmt(noiseVariance, digits: 4),
        rawValue: noiseVariance,
      ),
      ParameterDescriptor(
        id: 'rx_power',
        symbol: 'P_rx',
        name: 'Received Frame Power',
        category: ParameterCategory.channelAndSignal,
        provenance: receivedPower == null
            ? ValueProvenance.unavailable
            : ValueProvenance.directMeasurement,
        formula: '(1/N) Σ z_i²',
        description: 'Mean squared sample power across the 512-sample frame.',
        unit: 'W',
        formattedValue: _fmt(receivedPower, digits: 4),
        rawValue: receivedPower,
        note: receivedPower == null && isLiveSource
            ? 'Computed locally in Receiver DSP'
            : null,
      ),
      ParameterDescriptor(
        id: 'ber',
        symbol: 'BER',
        name: 'Bit Error Rate',
        category: ParameterCategory.channelAndSignal,
        provenance: ber == null
            ? ValueProvenance.unavailable
            : ValueProvenance.directMeasurement,
        formula: 'bit_errors / compared_bits',
        description:
            'Hard-decision BPSK bit error fraction after subtracting Kalman DC estimate.',
        formattedValue: _fmt(ber, digits: 4),
        rawValue: ber,
        healthy: ber == null ? null : ber! <= 0.02,
        note: comparedBits != null && comparedBits! > 0
            ? '${bitErrors ?? 0} / $comparedBits bits'
            : 'Requires simulation reference bits',
      ),
      ParameterDescriptor(
        id: 'psnr',
        symbol: 'PSNR',
        name: 'Image Reconstruction PSNR',
        category: ParameterCategory.channelAndSignal,
        provenance: psnrDb == null
            ? ValueProvenance.unavailable
            : ValueProvenance.directMeasurement,
        formula: '10 log10(255² / MSE)',
        description:
            'Peak signal-to-noise ratio across RGB pixels on completed BMP media transfers.',
        unit: ' dB',
        formattedValue: psnrDb == double.infinity
            ? '∞'
            : _fmt(psnrDb, digits: 2),
        rawValue: psnrDb,
        note: psnrDb == null ? 'Populated after BMP file transfer' : null,
      ),
      ParameterDescriptor(
        id: 'ssim',
        symbol: 'SSIM',
        name: 'Image Structural Similarity',
        category: ParameterCategory.channelAndSignal,
        provenance: ssim == null
            ? ValueProvenance.unavailable
            : ValueProvenance.directMeasurement,
        formula: 'Wang et al. (2004) 11×11 BT.601 luma',
        description:
            'Perceptual structural similarity in [0, 1] between transmitted and reconstructed BMPs.',
        formattedValue: _fmt(ssim, digits: 4),
        rawValue: ssim,
      ),
      ParameterDescriptor(
        id: 'latency',
        symbol: 'Δt_dsp',
        name: 'Frame DSP Latency & Queue',
        category: ParameterCategory.channelAndSignal,
        provenance: latencyMs == null
            ? ValueProvenance.unavailable
            : ValueProvenance.directMeasurement,
        formula: 't_done - t_capture',
        description:
            'Receiver frame processing latency, queue depth, and cumulative sequence gaps.',
        unit: ' ms',
        formattedValue: _fmt(latencyMs, digits: 2),
        rawValue: latencyMs,
        healthy: sequenceGaps == 0,
        note: 'Seq #$sequence · Queue ${queueDepth ?? 0} · Gaps $sequenceGaps',
      ),

      // --- Category 4: Adaptive Policy & ML ---
      ParameterDescriptor(
        id: 'policy_mode',
        symbol: 'π(θ)',
        name: 'Active Adaptation Policy',
        category: ParameterCategory.adaptiveAndMl,
        provenance: ValueProvenance.mlPredicted,
        formula: 'rule (ρ=0.0268) | onnx (6→16→16→1 MLP)',
        description:
            'Controller adaptation strategy issuing versioned Q/R updates at future frame boundaries.',
        formattedValue:
            '$policyName (v$activeConfigVersion${recommendOnly ? ' · rec-only' : ''})',
        note: proposedConfigVersion != null
            ? 'Proposed v$proposedConfigVersion @ seq ${effectiveSequence ?? '—'}'
            : null,
      ),
      ParameterDescriptor(
        id: 'pred_rho',
        symbol: 'ρ̂_ML',
        name: 'Policy Recommended ρ',
        category: ParameterCategory.adaptiveAndMl,
        provenance: predictedRho == null
            ? ValueProvenance.unavailable
            : ValueProvenance.mlPredicted,
        formula: '10^(MLP(features_6)) ∈ [1e-7, 10]',
        description:
            'Controller recommended tracking ratio ρ̂ paired with proposed Q and R.',
        formattedValue: _fmt(predictedRho, digits: 5),
        rawValue: predictedRho,
        note: recommendedQ != null && recommendedR != null
            ? 'Q̂=${_fmt(recommendedQ, digits: 4)}, R̂=${_fmt(recommendedR, digits: 4)}'
            : null,
      ),
      ParameterDescriptor(
        id: 'ml_class',
        symbol: 'C_t → Ĉ_{t+1}',
        name: 'Channel Quality Class (12-Frame)',
        category: ParameterCategory.adaptiveAndMl,
        provenance: measuredClass == null
            ? ValueProvenance.unavailable
            : ValueProvenance.mlPredicted,
        formula: 'MLP_32x32(features_10) → {good, moderate, poor, unstable}',
        description:
            'Rule-measured current 12-frame channel regime vs ONNX next-window prediction.',
        formattedValue: measuredClass == null
            ? '—'
            : '$measuredClass → ${predictedClass ?? '—'}',
        healthy: measuredClass == null
            ? null
            : (measuredClass == 'good' || measuredClass == 'moderate'),
        note: mlConfidence != null
            ? 'Confidence ${(mlConfidence! * 100).toStringAsFixed(1)}%'
            : 'Evaluated every 12 receiver frames',
      ),
    ];
  }

  Map<String, Object?> toJson() => {
    'timestamp': timestamp.toUtc().toIso8601String(),
    'sequence': sequence,
    'step_count': stepCount,
    'ready': ready,
    'source': isLiveSource ? 'live_grpc' : 'on_device_lab',
    'kalman': {
      'x': stateEstimateX,
      'p_prior': priorCovariancePMinus,
      'p_posterior': posteriorCovarianceP,
      'gain_k': kalmanGainK,
      'gain_k_steady_state': steadyStateGain,
      'p_steady_state': steadyStateCovariance,
      'covariance_gap': covarianceGap,
      'q': processNoiseQ,
      'r': measurementNoiseR,
      'rho': trackingRatioRho,
      'z_measurement': rawMeasurementZ,
      'innovation_y': innovationY,
      'innovation_cov_s': innovationCovarianceS,
      'nis': normalizedInnovationSquared,
      'nis_consistent_95': nisConsistent95,
      'residual_rms': residualRms,
      'true_dc_offset': trueStateOffset,
      'true_tracking_error': trueTrackingError,
      'reset_count': resetCount,
    },
    'channel': {
      'snr_db': snrDb,
      'noise_variance': noiseVariance,
      'received_power': receivedPower,
      'ber': ber,
      'compared_bits': comparedBits,
      'bit_errors': bitErrors,
      'psnr_db': psnrDb == double.infinity ? 'infinity' : psnrDb,
      'ssim': ssim,
      'latency_ms': latencyMs,
      'queue_depth': queueDepth,
      'sequence_gaps': sequenceGaps,
    },
    'adaptive_ml': {
      'policy': policyName,
      'recommend_only': recommendOnly,
      'active_config_version': activeConfigVersion,
      'proposed_config_version': proposedConfigVersion,
      'effective_sequence': effectiveSequence,
      'recommended_q': recommendedQ,
      'recommended_r': recommendedR,
      'predicted_rho': predictedRho,
      'measured_class': measuredClass,
      'predicted_class': predictedClass,
      'confidence': mlConfidence,
    },
  };

  String toPrettyJson() => const JsonEncoder.withIndent('  ').convert(toJson());
}
