// This is a generated file - do not edit.
//
// Generated from tx/v1/transmitter.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class TxConfig extends $pb.GeneratedMessage {
  factory TxConfig({
    $fixnum.Int64? commandId,
    $fixnum.Int64? version,
    $fixnum.Int64? effectiveSequence,
    $core.int? symbolRate,
    $core.double? amplitude,
    $core.double? noiseStddev,
  }) {
    final result = TxConfig._();
    if (commandId != null) result.commandId = commandId;
    if (version != null) result.version = version;
    if (effectiveSequence != null) result.effectiveSequence = effectiveSequence;
    if (symbolRate != null) result.symbolRate = symbolRate;
    if (amplitude != null) result.amplitude = amplitude;
    if (noiseStddev != null) result.noiseStddev = noiseStddev;
    return result;
  }

  TxConfig._();

  factory TxConfig.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TxConfig()..mergeFromBuffer(data, registry);
  factory TxConfig.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TxConfig()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TxConfig',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'livekalman.tx.v1'),
      createEmptyInstance: TxConfig.$_createMessage)
    ..a<$fixnum.Int64>(
        1, _omitFieldNames ? '' : 'commandId', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(2, _omitFieldNames ? '' : 'version', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        3, _omitFieldNames ? '' : 'effectiveSequence', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aI(4, _omitFieldNames ? '' : 'symbolRate', fieldType: $pb.PbFieldType.OU3)
    ..aD(5, _omitFieldNames ? '' : 'amplitude', fieldType: $pb.PbFieldType.OF)
    ..aD(6, _omitFieldNames ? '' : 'noiseStddev', fieldType: $pb.PbFieldType.OF)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TxConfig clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TxConfig copyWith(void Function(TxConfig) updates) =>
      super.copyWith((message) => updates(message as TxConfig)) as TxConfig;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use TxConfig() / TxConfig.new instead')
  static TxConfig create() => TxConfig._();
  static $pb.GeneratedMessage $_createMessage() => TxConfig._();
  @$core.override
  TxConfig createEmptyInstance() => TxConfig._();
  @$core.pragma('dart2js:noInline')
  static TxConfig getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TxConfig>(TxConfig.$_createMessage);
  static TxConfig? _defaultInstance;

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
  $core.int get symbolRate => $_getIZ(3);
  @$pb.TagNumber(4)
  set symbolRate($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSymbolRate() => $_has(3);
  @$pb.TagNumber(4)
  void clearSymbolRate() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.double get amplitude => $_getN(4);
  @$pb.TagNumber(5)
  set amplitude($core.double value) => $_setFloat(4, value);
  @$pb.TagNumber(5)
  $core.bool hasAmplitude() => $_has(4);
  @$pb.TagNumber(5)
  void clearAmplitude() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.double get noiseStddev => $_getN(5);
  @$pb.TagNumber(6)
  set noiseStddev($core.double value) => $_setFloat(5, value);
  @$pb.TagNumber(6)
  $core.bool hasNoiseStddev() => $_has(5);
  @$pb.TagNumber(6)
  void clearNoiseStddev() => $_clearField(6);
}

class ApplyTxReply extends $pb.GeneratedMessage {
  factory ApplyTxReply({
    $core.bool? accepted,
    $core.String? reason,
    $fixnum.Int64? appliedVersion,
  }) {
    final result = ApplyTxReply._();
    if (accepted != null) result.accepted = accepted;
    if (reason != null) result.reason = reason;
    if (appliedVersion != null) result.appliedVersion = appliedVersion;
    return result;
  }

  ApplyTxReply._();

  factory ApplyTxReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ApplyTxReply()..mergeFromBuffer(data, registry);
  factory ApplyTxReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ApplyTxReply()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ApplyTxReply',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'livekalman.tx.v1'),
      createEmptyInstance: ApplyTxReply.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'accepted')
    ..aOS(2, _omitFieldNames ? '' : 'reason')
    ..a<$fixnum.Int64>(
        3, _omitFieldNames ? '' : 'appliedVersion', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ApplyTxReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ApplyTxReply copyWith(void Function(ApplyTxReply) updates) =>
      super.copyWith((message) => updates(message as ApplyTxReply))
          as ApplyTxReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ApplyTxReply() / ApplyTxReply.new instead')
  static ApplyTxReply create() => ApplyTxReply._();
  static $pb.GeneratedMessage $_createMessage() => ApplyTxReply._();
  @$core.override
  ApplyTxReply createEmptyInstance() => ApplyTxReply._();
  @$core.pragma('dart2js:noInline')
  static ApplyTxReply getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ApplyTxReply>(
          ApplyTxReply.$_createMessage);
  static ApplyTxReply? _defaultInstance;

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

class TxStatus extends $pb.GeneratedMessage {
  factory TxStatus({
    $fixnum.Int64? activeVersion,
    $core.bool? running,
    $fixnum.Int64? sequence,
    $core.String? runId,
  }) {
    final result = TxStatus._();
    if (activeVersion != null) result.activeVersion = activeVersion;
    if (running != null) result.running = running;
    if (sequence != null) result.sequence = sequence;
    if (runId != null) result.runId = runId;
    return result;
  }

  TxStatus._();

  factory TxStatus.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TxStatus()..mergeFromBuffer(data, registry);
  factory TxStatus.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TxStatus()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TxStatus',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'livekalman.tx.v1'),
      createEmptyInstance: TxStatus.$_createMessage)
    ..a<$fixnum.Int64>(
        1, _omitFieldNames ? '' : 'activeVersion', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOB(2, _omitFieldNames ? '' : 'running')
    ..a<$fixnum.Int64>(
        3, _omitFieldNames ? '' : 'sequence', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(4, _omitFieldNames ? '' : 'runId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TxStatus clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TxStatus copyWith(void Function(TxStatus) updates) =>
      super.copyWith((message) => updates(message as TxStatus)) as TxStatus;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use TxStatus() / TxStatus.new instead')
  static TxStatus create() => TxStatus._();
  static $pb.GeneratedMessage $_createMessage() => TxStatus._();
  @$core.override
  TxStatus createEmptyInstance() => TxStatus._();
  @$core.pragma('dart2js:noInline')
  static TxStatus getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TxStatus>(TxStatus.$_createMessage);
  static TxStatus? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get activeVersion => $_getI64(0);
  @$pb.TagNumber(1)
  set activeVersion($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasActiveVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearActiveVersion() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get running => $_getBF(1);
  @$pb.TagNumber(2)
  set running($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRunning() => $_has(1);
  @$pb.TagNumber(2)
  void clearRunning() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get sequence => $_getI64(2);
  @$pb.TagNumber(3)
  set sequence($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSequence() => $_has(2);
  @$pb.TagNumber(3)
  void clearSequence() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get runId => $_getSZ(3);
  @$pb.TagNumber(4)
  set runId($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasRunId() => $_has(3);
  @$pb.TagNumber(4)
  void clearRunId() => $_clearField(4);
}

class TxEvent extends $pb.GeneratedMessage {
  factory TxEvent({
    $fixnum.Int64? sequence,
    $core.String? description,
    TxFrameTrace? trace,
  }) {
    final result = TxEvent._();
    if (sequence != null) result.sequence = sequence;
    if (description != null) result.description = description;
    if (trace != null) result.trace = trace;
    return result;
  }

  TxEvent._();

  factory TxEvent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TxEvent()..mergeFromBuffer(data, registry);
  factory TxEvent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TxEvent()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TxEvent',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'livekalman.tx.v1'),
      createEmptyInstance: TxEvent.$_createMessage)
    ..a<$fixnum.Int64>(
        1, _omitFieldNames ? '' : 'sequence', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(2, _omitFieldNames ? '' : 'description')
    ..aOM<TxFrameTrace>(3, _omitFieldNames ? '' : 'trace',
        subBuilder: TxFrameTrace.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TxEvent clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TxEvent copyWith(void Function(TxEvent) updates) =>
      super.copyWith((message) => updates(message as TxEvent)) as TxEvent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use TxEvent() / TxEvent.new instead')
  static TxEvent create() => TxEvent._();
  static $pb.GeneratedMessage $_createMessage() => TxEvent._();
  @$core.override
  TxEvent createEmptyInstance() => TxEvent._();
  @$core.pragma('dart2js:noInline')
  static TxEvent getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TxEvent>(TxEvent.$_createMessage);
  static TxEvent? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get sequence => $_getI64(0);
  @$pb.TagNumber(1)
  set sequence($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSequence() => $_has(0);
  @$pb.TagNumber(1)
  void clearSequence() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get description => $_getSZ(1);
  @$pb.TagNumber(2)
  set description($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDescription() => $_has(1);
  @$pb.TagNumber(2)
  void clearDescription() => $_clearField(2);

  @$pb.TagNumber(3)
  TxFrameTrace get trace => $_getN(2);
  @$pb.TagNumber(3)
  set trace(TxFrameTrace value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasTrace() => $_has(2);
  @$pb.TagNumber(3)
  void clearTrace() => $_clearField(3);
  @$pb.TagNumber(3)
  TxFrameTrace ensureTrace() => $_ensure(2);
}

/// TxFrameTrace is a reduced diagnostic view of a real signal frame. It is
/// intentionally bounded so dashboards never subscribe to the full sample-rate
/// stream used between Sender and Receiver.
class TxFrameTrace extends $pb.GeneratedMessage {
  factory TxFrameTrace({
    $fixnum.Int64? sequence,
    $core.String? transferId,
    $core.String? fileName,
    $fixnum.Int64? mediaOffset,
    $fixnum.Int64? totalBytes,
    $core.List<$core.int>? originalBytes,
    $core.List<$core.int>? encodedBytes,
    $core.List<$core.int>? scrambledBytes,
    $core.String? payloadBits,
    $core.Iterable<$core.double>? cleanSymbols,
    $core.Iterable<$core.double>? noisySamples,
    $core.double? noiseStddev,
    $core.bool? grpcSent,
    $fixnum.Int64? observedAtUnixMs,
  }) {
    final result = TxFrameTrace._();
    if (sequence != null) result.sequence = sequence;
    if (transferId != null) result.transferId = transferId;
    if (fileName != null) result.fileName = fileName;
    if (mediaOffset != null) result.mediaOffset = mediaOffset;
    if (totalBytes != null) result.totalBytes = totalBytes;
    if (originalBytes != null) result.originalBytes = originalBytes;
    if (encodedBytes != null) result.encodedBytes = encodedBytes;
    if (scrambledBytes != null) result.scrambledBytes = scrambledBytes;
    if (payloadBits != null) result.payloadBits = payloadBits;
    if (cleanSymbols != null) result.cleanSymbols.addAll(cleanSymbols);
    if (noisySamples != null) result.noisySamples.addAll(noisySamples);
    if (noiseStddev != null) result.noiseStddev = noiseStddev;
    if (grpcSent != null) result.grpcSent = grpcSent;
    if (observedAtUnixMs != null) result.observedAtUnixMs = observedAtUnixMs;
    return result;
  }

  TxFrameTrace._();

  factory TxFrameTrace.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TxFrameTrace()..mergeFromBuffer(data, registry);
  factory TxFrameTrace.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TxFrameTrace()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TxFrameTrace',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'livekalman.tx.v1'),
      createEmptyInstance: TxFrameTrace.$_createMessage)
    ..a<$fixnum.Int64>(
        1, _omitFieldNames ? '' : 'sequence', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(2, _omitFieldNames ? '' : 'transferId')
    ..aOS(3, _omitFieldNames ? '' : 'fileName')
    ..a<$fixnum.Int64>(
        4, _omitFieldNames ? '' : 'mediaOffset', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        5, _omitFieldNames ? '' : 'totalBytes', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$core.List<$core.int>>(
        6, _omitFieldNames ? '' : 'originalBytes', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        7, _omitFieldNames ? '' : 'encodedBytes', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        8, _omitFieldNames ? '' : 'scrambledBytes', $pb.PbFieldType.OY)
    ..aOS(9, _omitFieldNames ? '' : 'payloadBits')
    ..p<$core.double>(
        10, _omitFieldNames ? '' : 'cleanSymbols', $pb.PbFieldType.KF)
    ..p<$core.double>(
        11, _omitFieldNames ? '' : 'noisySamples', $pb.PbFieldType.KF)
    ..aD(12, _omitFieldNames ? '' : 'noiseStddev',
        fieldType: $pb.PbFieldType.OF)
    ..aOB(13, _omitFieldNames ? '' : 'grpcSent')
    ..a<$fixnum.Int64>(
        14, _omitFieldNames ? '' : 'observedAtUnixMs', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TxFrameTrace clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TxFrameTrace copyWith(void Function(TxFrameTrace) updates) =>
      super.copyWith((message) => updates(message as TxFrameTrace))
          as TxFrameTrace;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use TxFrameTrace() / TxFrameTrace.new instead')
  static TxFrameTrace create() => TxFrameTrace._();
  static $pb.GeneratedMessage $_createMessage() => TxFrameTrace._();
  @$core.override
  TxFrameTrace createEmptyInstance() => TxFrameTrace._();
  @$core.pragma('dart2js:noInline')
  static TxFrameTrace getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TxFrameTrace>(
          TxFrameTrace.$_createMessage);
  static TxFrameTrace? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get sequence => $_getI64(0);
  @$pb.TagNumber(1)
  set sequence($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSequence() => $_has(0);
  @$pb.TagNumber(1)
  void clearSequence() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get transferId => $_getSZ(1);
  @$pb.TagNumber(2)
  set transferId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTransferId() => $_has(1);
  @$pb.TagNumber(2)
  void clearTransferId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get fileName => $_getSZ(2);
  @$pb.TagNumber(3)
  set fileName($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasFileName() => $_has(2);
  @$pb.TagNumber(3)
  void clearFileName() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get mediaOffset => $_getI64(3);
  @$pb.TagNumber(4)
  set mediaOffset($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasMediaOffset() => $_has(3);
  @$pb.TagNumber(4)
  void clearMediaOffset() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get totalBytes => $_getI64(4);
  @$pb.TagNumber(5)
  set totalBytes($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasTotalBytes() => $_has(4);
  @$pb.TagNumber(5)
  void clearTotalBytes() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.List<$core.int> get originalBytes => $_getN(5);
  @$pb.TagNumber(6)
  set originalBytes($core.List<$core.int> value) => $_setBytes(5, value);
  @$pb.TagNumber(6)
  $core.bool hasOriginalBytes() => $_has(5);
  @$pb.TagNumber(6)
  void clearOriginalBytes() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.List<$core.int> get encodedBytes => $_getN(6);
  @$pb.TagNumber(7)
  set encodedBytes($core.List<$core.int> value) => $_setBytes(6, value);
  @$pb.TagNumber(7)
  $core.bool hasEncodedBytes() => $_has(6);
  @$pb.TagNumber(7)
  void clearEncodedBytes() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.List<$core.int> get scrambledBytes => $_getN(7);
  @$pb.TagNumber(8)
  set scrambledBytes($core.List<$core.int> value) => $_setBytes(7, value);
  @$pb.TagNumber(8)
  $core.bool hasScrambledBytes() => $_has(7);
  @$pb.TagNumber(8)
  void clearScrambledBytes() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get payloadBits => $_getSZ(8);
  @$pb.TagNumber(9)
  set payloadBits($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasPayloadBits() => $_has(8);
  @$pb.TagNumber(9)
  void clearPayloadBits() => $_clearField(9);

  @$pb.TagNumber(10)
  $pb.PbList<$core.double> get cleanSymbols => $_getList(9);

  @$pb.TagNumber(11)
  $pb.PbList<$core.double> get noisySamples => $_getList(10);

  @$pb.TagNumber(12)
  $core.double get noiseStddev => $_getN(11);
  @$pb.TagNumber(12)
  set noiseStddev($core.double value) => $_setFloat(11, value);
  @$pb.TagNumber(12)
  $core.bool hasNoiseStddev() => $_has(11);
  @$pb.TagNumber(12)
  void clearNoiseStddev() => $_clearField(12);

  @$pb.TagNumber(13)
  $core.bool get grpcSent => $_getBF(12);
  @$pb.TagNumber(13)
  set grpcSent($core.bool value) => $_setBool(12, value);
  @$pb.TagNumber(13)
  $core.bool hasGrpcSent() => $_has(12);
  @$pb.TagNumber(13)
  void clearGrpcSent() => $_clearField(13);

  @$pb.TagNumber(14)
  $fixnum.Int64 get observedAtUnixMs => $_getI64(13);
  @$pb.TagNumber(14)
  set observedAtUnixMs($fixnum.Int64 value) => $_setInt64(13, value);
  @$pb.TagNumber(14)
  $core.bool hasObservedAtUnixMs() => $_has(13);
  @$pb.TagNumber(14)
  void clearObservedAtUnixMs() => $_clearField(14);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
