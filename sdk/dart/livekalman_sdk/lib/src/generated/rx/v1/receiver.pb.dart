// This is a generated file - do not edit.
//
// Generated from rx/v1/receiver.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import '../../common/v1/common.pbenum.dart' as $1;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class TxFrame extends $pb.GeneratedMessage {
  factory TxFrame({
    $core.String? runId,
    $fixnum.Int64? streamId,
    $fixnum.Int64? sequence,
    $fixnum.Int64? firstSampleIndex,
    $core.int? sampleRateHz,
    $core.int? samplesPerSymbol,
    $fixnum.Int64? captureTimestampUs,
    $fixnum.Int64? configVersion,
    $core.Iterable<$core.double>? samples,
    $core.List<$core.int>? referenceBits,
    $1.SampleFormat? sampleFormat,
    $core.List<$core.int>? packedSamples,
  }) {
    final result = TxFrame._();
    if (runId != null) result.runId = runId;
    if (streamId != null) result.streamId = streamId;
    if (sequence != null) result.sequence = sequence;
    if (firstSampleIndex != null) result.firstSampleIndex = firstSampleIndex;
    if (sampleRateHz != null) result.sampleRateHz = sampleRateHz;
    if (samplesPerSymbol != null) result.samplesPerSymbol = samplesPerSymbol;
    if (captureTimestampUs != null)
      result.captureTimestampUs = captureTimestampUs;
    if (configVersion != null) result.configVersion = configVersion;
    if (samples != null) result.samples.addAll(samples);
    if (referenceBits != null) result.referenceBits = referenceBits;
    if (sampleFormat != null) result.sampleFormat = sampleFormat;
    if (packedSamples != null) result.packedSamples = packedSamples;
    return result;
  }

  TxFrame._();

  factory TxFrame.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TxFrame()..mergeFromBuffer(data, registry);
  factory TxFrame.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TxFrame()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TxFrame',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'livekalman.rx.v1'),
      createEmptyInstance: TxFrame.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'runId')
    ..a<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'streamId', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        3, _omitFieldNames ? '' : 'sequence', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        4, _omitFieldNames ? '' : 'firstSampleIndex', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aI(5, _omitFieldNames ? '' : 'sampleRateHz',
        fieldType: $pb.PbFieldType.OU3)
    ..aI(6, _omitFieldNames ? '' : 'samplesPerSymbol',
        fieldType: $pb.PbFieldType.OU3)
    ..a<$fixnum.Int64>(
        7, _omitFieldNames ? '' : 'captureTimestampUs', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        8, _omitFieldNames ? '' : 'configVersion', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..p<$core.double>(9, _omitFieldNames ? '' : 'samples', $pb.PbFieldType.KF)
    ..a<$core.List<$core.int>>(
        10, _omitFieldNames ? '' : 'referenceBits', $pb.PbFieldType.OY)
    ..aE<$1.SampleFormat>(11, _omitFieldNames ? '' : 'sampleFormat',
        enumValues: $1.SampleFormat.values)
    ..a<$core.List<$core.int>>(
        12, _omitFieldNames ? '' : 'packedSamples', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TxFrame clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TxFrame copyWith(void Function(TxFrame) updates) =>
      super.copyWith((message) => updates(message as TxFrame)) as TxFrame;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use TxFrame() / TxFrame.new instead')
  static TxFrame create() => TxFrame._();
  static $pb.GeneratedMessage $_createMessage() => TxFrame._();
  @$core.override
  TxFrame createEmptyInstance() => TxFrame._();
  @$core.pragma('dart2js:noInline')
  static TxFrame getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TxFrame>(TxFrame.$_createMessage);
  static TxFrame? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get runId => $_getSZ(0);
  @$pb.TagNumber(1)
  set runId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRunId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRunId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get streamId => $_getI64(1);
  @$pb.TagNumber(2)
  set streamId($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasStreamId() => $_has(1);
  @$pb.TagNumber(2)
  void clearStreamId() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get sequence => $_getI64(2);
  @$pb.TagNumber(3)
  set sequence($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSequence() => $_has(2);
  @$pb.TagNumber(3)
  void clearSequence() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get firstSampleIndex => $_getI64(3);
  @$pb.TagNumber(4)
  set firstSampleIndex($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasFirstSampleIndex() => $_has(3);
  @$pb.TagNumber(4)
  void clearFirstSampleIndex() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get sampleRateHz => $_getIZ(4);
  @$pb.TagNumber(5)
  set sampleRateHz($core.int value) => $_setUnsignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasSampleRateHz() => $_has(4);
  @$pb.TagNumber(5)
  void clearSampleRateHz() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get samplesPerSymbol => $_getIZ(5);
  @$pb.TagNumber(6)
  set samplesPerSymbol($core.int value) => $_setUnsignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasSamplesPerSymbol() => $_has(5);
  @$pb.TagNumber(6)
  void clearSamplesPerSymbol() => $_clearField(6);

  @$pb.TagNumber(7)
  $fixnum.Int64 get captureTimestampUs => $_getI64(6);
  @$pb.TagNumber(7)
  set captureTimestampUs($fixnum.Int64 value) => $_setInt64(6, value);
  @$pb.TagNumber(7)
  $core.bool hasCaptureTimestampUs() => $_has(6);
  @$pb.TagNumber(7)
  void clearCaptureTimestampUs() => $_clearField(7);

  @$pb.TagNumber(8)
  $fixnum.Int64 get configVersion => $_getI64(7);
  @$pb.TagNumber(8)
  set configVersion($fixnum.Int64 value) => $_setInt64(7, value);
  @$pb.TagNumber(8)
  $core.bool hasConfigVersion() => $_has(7);
  @$pb.TagNumber(8)
  void clearConfigVersion() => $_clearField(8);

  @$pb.TagNumber(9)
  $pb.PbList<$core.double> get samples => $_getList(8);

  @$pb.TagNumber(10)
  $core.List<$core.int> get referenceBits => $_getN(9);
  @$pb.TagNumber(10)
  set referenceBits($core.List<$core.int> value) => $_setBytes(9, value);
  @$pb.TagNumber(10)
  $core.bool hasReferenceBits() => $_has(9);
  @$pb.TagNumber(10)
  void clearReferenceBits() => $_clearField(10);

  @$pb.TagNumber(11)
  $1.SampleFormat get sampleFormat => $_getN(10);
  @$pb.TagNumber(11)
  set sampleFormat($1.SampleFormat value) => $_setField(11, value);
  @$pb.TagNumber(11)
  $core.bool hasSampleFormat() => $_has(10);
  @$pb.TagNumber(11)
  void clearSampleFormat() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.List<$core.int> get packedSamples => $_getN(11);
  @$pb.TagNumber(12)
  set packedSamples($core.List<$core.int> value) => $_setBytes(11, value);
  @$pb.TagNumber(12)
  $core.bool hasPackedSamples() => $_has(11);
  @$pb.TagNumber(12)
  void clearPackedSamples() => $_clearField(12);
}

class RxFeedback extends $pb.GeneratedMessage {
  factory RxFeedback({
    $fixnum.Int64? sequence,
    $core.double? snrDb,
    $core.double? noiseVariance,
    $fixnum.Int64? comparedBits,
    $fixnum.Int64? bitErrors,
    $core.double? ber,
    $core.double? latencyMs,
    $fixnum.Int64? activeConfigVersion,
    $core.int? queueDepth,
  }) {
    final result = RxFeedback._();
    if (sequence != null) result.sequence = sequence;
    if (snrDb != null) result.snrDb = snrDb;
    if (noiseVariance != null) result.noiseVariance = noiseVariance;
    if (comparedBits != null) result.comparedBits = comparedBits;
    if (bitErrors != null) result.bitErrors = bitErrors;
    if (ber != null) result.ber = ber;
    if (latencyMs != null) result.latencyMs = latencyMs;
    if (activeConfigVersion != null)
      result.activeConfigVersion = activeConfigVersion;
    if (queueDepth != null) result.queueDepth = queueDepth;
    return result;
  }

  RxFeedback._();

  factory RxFeedback.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RxFeedback()..mergeFromBuffer(data, registry);
  factory RxFeedback.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RxFeedback()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RxFeedback',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'livekalman.rx.v1'),
      createEmptyInstance: RxFeedback.$_createMessage)
    ..a<$fixnum.Int64>(
        1, _omitFieldNames ? '' : 'sequence', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aD(2, _omitFieldNames ? '' : 'snrDb', fieldType: $pb.PbFieldType.OF)
    ..aD(3, _omitFieldNames ? '' : 'noiseVariance',
        fieldType: $pb.PbFieldType.OF)
    ..a<$fixnum.Int64>(
        4, _omitFieldNames ? '' : 'comparedBits', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        5, _omitFieldNames ? '' : 'bitErrors', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aD(6, _omitFieldNames ? '' : 'ber', fieldType: $pb.PbFieldType.OF)
    ..aD(7, _omitFieldNames ? '' : 'latencyMs')
    ..a<$fixnum.Int64>(
        8, _omitFieldNames ? '' : 'activeConfigVersion', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aI(9, _omitFieldNames ? '' : 'queueDepth', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RxFeedback clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RxFeedback copyWith(void Function(RxFeedback) updates) =>
      super.copyWith((message) => updates(message as RxFeedback)) as RxFeedback;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use RxFeedback() / RxFeedback.new instead')
  static RxFeedback create() => RxFeedback._();
  static $pb.GeneratedMessage $_createMessage() => RxFeedback._();
  @$core.override
  RxFeedback createEmptyInstance() => RxFeedback._();
  @$core.pragma('dart2js:noInline')
  static RxFeedback getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RxFeedback>(RxFeedback.$_createMessage);
  static RxFeedback? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get sequence => $_getI64(0);
  @$pb.TagNumber(1)
  set sequence($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSequence() => $_has(0);
  @$pb.TagNumber(1)
  void clearSequence() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.double get snrDb => $_getN(1);
  @$pb.TagNumber(2)
  set snrDb($core.double value) => $_setFloat(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSnrDb() => $_has(1);
  @$pb.TagNumber(2)
  void clearSnrDb() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.double get noiseVariance => $_getN(2);
  @$pb.TagNumber(3)
  set noiseVariance($core.double value) => $_setFloat(2, value);
  @$pb.TagNumber(3)
  $core.bool hasNoiseVariance() => $_has(2);
  @$pb.TagNumber(3)
  void clearNoiseVariance() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get comparedBits => $_getI64(3);
  @$pb.TagNumber(4)
  set comparedBits($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasComparedBits() => $_has(3);
  @$pb.TagNumber(4)
  void clearComparedBits() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get bitErrors => $_getI64(4);
  @$pb.TagNumber(5)
  set bitErrors($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasBitErrors() => $_has(4);
  @$pb.TagNumber(5)
  void clearBitErrors() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.double get ber => $_getN(5);
  @$pb.TagNumber(6)
  set ber($core.double value) => $_setFloat(5, value);
  @$pb.TagNumber(6)
  $core.bool hasBer() => $_has(5);
  @$pb.TagNumber(6)
  void clearBer() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.double get latencyMs => $_getN(6);
  @$pb.TagNumber(7)
  set latencyMs($core.double value) => $_setDouble(6, value);
  @$pb.TagNumber(7)
  $core.bool hasLatencyMs() => $_has(6);
  @$pb.TagNumber(7)
  void clearLatencyMs() => $_clearField(7);

  @$pb.TagNumber(8)
  $fixnum.Int64 get activeConfigVersion => $_getI64(7);
  @$pb.TagNumber(8)
  set activeConfigVersion($fixnum.Int64 value) => $_setInt64(7, value);
  @$pb.TagNumber(8)
  $core.bool hasActiveConfigVersion() => $_has(7);
  @$pb.TagNumber(8)
  void clearActiveConfigVersion() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.int get queueDepth => $_getIZ(8);
  @$pb.TagNumber(9)
  set queueDepth($core.int value) => $_setUnsignedInt32(8, value);
  @$pb.TagNumber(9)
  $core.bool hasQueueDepth() => $_has(8);
  @$pb.TagNumber(9)
  void clearQueueDepth() => $_clearField(9);
}

class RxConfig extends $pb.GeneratedMessage {
  factory RxConfig({
    $fixnum.Int64? commandId,
    $fixnum.Int64? version,
    $fixnum.Int64? effectiveSequence,
    $core.double? kalmanQ,
    $core.double? kalmanR,
    $core.bool? resetState,
  }) {
    final result = RxConfig._();
    if (commandId != null) result.commandId = commandId;
    if (version != null) result.version = version;
    if (effectiveSequence != null) result.effectiveSequence = effectiveSequence;
    if (kalmanQ != null) result.kalmanQ = kalmanQ;
    if (kalmanR != null) result.kalmanR = kalmanR;
    if (resetState != null) result.resetState = resetState;
    return result;
  }

  RxConfig._();

  factory RxConfig.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RxConfig()..mergeFromBuffer(data, registry);
  factory RxConfig.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RxConfig()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RxConfig',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'livekalman.rx.v1'),
      createEmptyInstance: RxConfig.$_createMessage)
    ..a<$fixnum.Int64>(
        1, _omitFieldNames ? '' : 'commandId', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(2, _omitFieldNames ? '' : 'version', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        3, _omitFieldNames ? '' : 'effectiveSequence', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aD(4, _omitFieldNames ? '' : 'kalmanQ', fieldType: $pb.PbFieldType.OF)
    ..aD(5, _omitFieldNames ? '' : 'kalmanR', fieldType: $pb.PbFieldType.OF)
    ..aOB(6, _omitFieldNames ? '' : 'resetState')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RxConfig clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RxConfig copyWith(void Function(RxConfig) updates) =>
      super.copyWith((message) => updates(message as RxConfig)) as RxConfig;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use RxConfig() / RxConfig.new instead')
  static RxConfig create() => RxConfig._();
  static $pb.GeneratedMessage $_createMessage() => RxConfig._();
  @$core.override
  RxConfig createEmptyInstance() => RxConfig._();
  @$core.pragma('dart2js:noInline')
  static RxConfig getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RxConfig>(RxConfig.$_createMessage);
  static RxConfig? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get commandId => $_getI64(0);
  @$pb.TagNumber(1)
  set commandId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCommandId() => $_has(0);
  @$pb.TagNumber(1)
  void clearCommandId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get version => $_getI64(1);
  @$pb.TagNumber(2)
  set version($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasVersion() => $_has(1);
  @$pb.TagNumber(2)
  void clearVersion() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get effectiveSequence => $_getI64(2);
  @$pb.TagNumber(3)
  set effectiveSequence($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasEffectiveSequence() => $_has(2);
  @$pb.TagNumber(3)
  void clearEffectiveSequence() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.double get kalmanQ => $_getN(3);
  @$pb.TagNumber(4)
  set kalmanQ($core.double value) => $_setFloat(3, value);
  @$pb.TagNumber(4)
  $core.bool hasKalmanQ() => $_has(3);
  @$pb.TagNumber(4)
  void clearKalmanQ() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.double get kalmanR => $_getN(4);
  @$pb.TagNumber(5)
  set kalmanR($core.double value) => $_setFloat(4, value);
  @$pb.TagNumber(5)
  $core.bool hasKalmanR() => $_has(4);
  @$pb.TagNumber(5)
  void clearKalmanR() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.bool get resetState => $_getBF(5);
  @$pb.TagNumber(6)
  set resetState($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasResetState() => $_has(5);
  @$pb.TagNumber(6)
  void clearResetState() => $_clearField(6);
}

class ApplyRxReply extends $pb.GeneratedMessage {
  factory ApplyRxReply({
    $core.bool? accepted,
    $core.String? reason,
    $fixnum.Int64? appliedVersion,
  }) {
    final result = ApplyRxReply._();
    if (accepted != null) result.accepted = accepted;
    if (reason != null) result.reason = reason;
    if (appliedVersion != null) result.appliedVersion = appliedVersion;
    return result;
  }

  ApplyRxReply._();

  factory ApplyRxReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ApplyRxReply()..mergeFromBuffer(data, registry);
  factory ApplyRxReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ApplyRxReply()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ApplyRxReply',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'livekalman.rx.v1'),
      createEmptyInstance: ApplyRxReply.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'accepted')
    ..aOS(2, _omitFieldNames ? '' : 'reason')
    ..a<$fixnum.Int64>(
        3, _omitFieldNames ? '' : 'appliedVersion', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ApplyRxReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ApplyRxReply copyWith(void Function(ApplyRxReply) updates) =>
      super.copyWith((message) => updates(message as ApplyRxReply))
          as ApplyRxReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ApplyRxReply() / ApplyRxReply.new instead')
  static ApplyRxReply create() => ApplyRxReply._();
  static $pb.GeneratedMessage $_createMessage() => ApplyRxReply._();
  @$core.override
  ApplyRxReply createEmptyInstance() => ApplyRxReply._();
  @$core.pragma('dart2js:noInline')
  static ApplyRxReply getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ApplyRxReply>(
          ApplyRxReply.$_createMessage);
  static ApplyRxReply? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get accepted => $_getBF(0);
  @$pb.TagNumber(1)
  set accepted($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAccepted() => $_has(0);
  @$pb.TagNumber(1)
  void clearAccepted() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get reason => $_getSZ(1);
  @$pb.TagNumber(2)
  set reason($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasReason() => $_has(1);
  @$pb.TagNumber(2)
  void clearReason() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get appliedVersion => $_getI64(2);
  @$pb.TagNumber(3)
  set appliedVersion($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAppliedVersion() => $_has(2);
  @$pb.TagNumber(3)
  void clearAppliedVersion() => $_clearField(3);
}

class RxStatus extends $pb.GeneratedMessage {
  factory RxStatus({
    $fixnum.Int64? activeVersion,
    $core.bool? streamActive,
    $fixnum.Int64? lastSequence,
    $fixnum.Int64? sequenceGaps,
  }) {
    final result = RxStatus._();
    if (activeVersion != null) result.activeVersion = activeVersion;
    if (streamActive != null) result.streamActive = streamActive;
    if (lastSequence != null) result.lastSequence = lastSequence;
    if (sequenceGaps != null) result.sequenceGaps = sequenceGaps;
    return result;
  }

  RxStatus._();

  factory RxStatus.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RxStatus()..mergeFromBuffer(data, registry);
  factory RxStatus.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RxStatus()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RxStatus',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'livekalman.rx.v1'),
      createEmptyInstance: RxStatus.$_createMessage)
    ..a<$fixnum.Int64>(
        1, _omitFieldNames ? '' : 'activeVersion', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOB(2, _omitFieldNames ? '' : 'streamActive')
    ..a<$fixnum.Int64>(
        3, _omitFieldNames ? '' : 'lastSequence', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        4, _omitFieldNames ? '' : 'sequenceGaps', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RxStatus clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RxStatus copyWith(void Function(RxStatus) updates) =>
      super.copyWith((message) => updates(message as RxStatus)) as RxStatus;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use RxStatus() / RxStatus.new instead')
  static RxStatus create() => RxStatus._();
  static $pb.GeneratedMessage $_createMessage() => RxStatus._();
  @$core.override
  RxStatus createEmptyInstance() => RxStatus._();
  @$core.pragma('dart2js:noInline')
  static RxStatus getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RxStatus>(RxStatus.$_createMessage);
  static RxStatus? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get activeVersion => $_getI64(0);
  @$pb.TagNumber(1)
  set activeVersion($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasActiveVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearActiveVersion() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get streamActive => $_getBF(1);
  @$pb.TagNumber(2)
  set streamActive($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasStreamActive() => $_has(1);
  @$pb.TagNumber(2)
  void clearStreamActive() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get lastSequence => $_getI64(2);
  @$pb.TagNumber(3)
  set lastSequence($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLastSequence() => $_has(2);
  @$pb.TagNumber(3)
  void clearLastSequence() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get sequenceGaps => $_getI64(3);
  @$pb.TagNumber(4)
  set sequenceGaps($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSequenceGaps() => $_has(3);
  @$pb.TagNumber(4)
  void clearSequenceGaps() => $_clearField(4);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
