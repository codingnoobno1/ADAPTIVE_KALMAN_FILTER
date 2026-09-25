// This is a generated file - do not edit.
//
// Generated from control/v1/controller.proto.

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

class ReceiverMetrics extends $pb.GeneratedMessage {
  factory ReceiverMetrics({
    $core.String? runId,
    $fixnum.Int64? sequence,
    $core.double? snrDb,
    $core.double? noiseVariance,
    $fixnum.Int64? comparedBits,
    $fixnum.Int64? bitErrors,
    $core.double? ber,
    $core.double? latencyMs,
    $fixnum.Int64? activeConfigVersion,
    $core.int? queueDepth,
    $fixnum.Int64? observedAtUnixMs,
  }) {
    final result = ReceiverMetrics._();
    if (runId != null) result.runId = runId;
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
    if (observedAtUnixMs != null) result.observedAtUnixMs = observedAtUnixMs;
    return result;
  }

  ReceiverMetrics._();

  factory ReceiverMetrics.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReceiverMetrics()..mergeFromBuffer(data, registry);
  factory ReceiverMetrics.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReceiverMetrics()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReceiverMetrics',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'livekalman.control.v1'),
      createEmptyInstance: ReceiverMetrics.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'runId')
    ..a<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'sequence', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aD(3, _omitFieldNames ? '' : 'snrDb', fieldType: $pb.PbFieldType.OF)
    ..aD(4, _omitFieldNames ? '' : 'noiseVariance',
        fieldType: $pb.PbFieldType.OF)
    ..a<$fixnum.Int64>(
        5, _omitFieldNames ? '' : 'comparedBits', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        6, _omitFieldNames ? '' : 'bitErrors', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aD(7, _omitFieldNames ? '' : 'ber', fieldType: $pb.PbFieldType.OF)
    ..aD(8, _omitFieldNames ? '' : 'latencyMs')
    ..a<$fixnum.Int64>(
        9, _omitFieldNames ? '' : 'activeConfigVersion', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aI(10, _omitFieldNames ? '' : 'queueDepth',
        fieldType: $pb.PbFieldType.OU3)
    ..a<$fixnum.Int64>(
        11, _omitFieldNames ? '' : 'observedAtUnixMs', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReceiverMetrics clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReceiverMetrics copyWith(void Function(ReceiverMetrics) updates) =>
      super.copyWith((message) => updates(message as ReceiverMetrics))
          as ReceiverMetrics;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReceiverMetrics() / ReceiverMetrics.new instead')
  static ReceiverMetrics create() => ReceiverMetrics._();
  static $pb.GeneratedMessage $_createMessage() => ReceiverMetrics._();
  @$core.override
  ReceiverMetrics createEmptyInstance() => ReceiverMetrics._();
  @$core.pragma('dart2js:noInline')
  static ReceiverMetrics getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReceiverMetrics>(
          ReceiverMetrics.$_createMessage);
  static ReceiverMetrics? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get runId => $_getSZ(0);
  @$pb.TagNumber(1)
  set runId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRunId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRunId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get sequence => $_getI64(1);
  @$pb.TagNumber(2)
  set sequence($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSequence() => $_has(1);
  @$pb.TagNumber(2)
  void clearSequence() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.double get snrDb => $_getN(2);
  @$pb.TagNumber(3)
  set snrDb($core.double value) => $_setFloat(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSnrDb() => $_has(2);
  @$pb.TagNumber(3)
  void clearSnrDb() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.double get noiseVariance => $_getN(3);
  @$pb.TagNumber(4)
  set noiseVariance($core.double value) => $_setFloat(3, value);
  @$pb.TagNumber(4)
  $core.bool hasNoiseVariance() => $_has(3);
  @$pb.TagNumber(4)
  void clearNoiseVariance() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get comparedBits => $_getI64(4);
  @$pb.TagNumber(5)
  set comparedBits($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasComparedBits() => $_has(4);
  @$pb.TagNumber(5)
  void clearComparedBits() => $_clearField(5);

  @$pb.TagNumber(6)
  $fixnum.Int64 get bitErrors => $_getI64(5);
  @$pb.TagNumber(6)
  set bitErrors($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(6)
  $core.bool hasBitErrors() => $_has(5);
  @$pb.TagNumber(6)
  void clearBitErrors() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.double get ber => $_getN(6);
  @$pb.TagNumber(7)
  set ber($core.double value) => $_setFloat(6, value);
  @$pb.TagNumber(7)
  $core.bool hasBer() => $_has(6);
  @$pb.TagNumber(7)
  void clearBer() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.double get latencyMs => $_getN(7);
  @$pb.TagNumber(8)
  set latencyMs($core.double value) => $_setDouble(7, value);
  @$pb.TagNumber(8)
  $core.bool hasLatencyMs() => $_has(7);
  @$pb.TagNumber(8)
  void clearLatencyMs() => $_clearField(8);

  @$pb.TagNumber(9)
  $fixnum.Int64 get activeConfigVersion => $_getI64(8);
  @$pb.TagNumber(9)
  set activeConfigVersion($fixnum.Int64 value) => $_setInt64(8, value);
  @$pb.TagNumber(9)
  $core.bool hasActiveConfigVersion() => $_has(8);
  @$pb.TagNumber(9)
  void clearActiveConfigVersion() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.int get queueDepth => $_getIZ(9);
  @$pb.TagNumber(10)
  set queueDepth($core.int value) => $_setUnsignedInt32(9, value);
  @$pb.TagNumber(10)
  $core.bool hasQueueDepth() => $_has(9);
  @$pb.TagNumber(10)
  void clearQueueDepth() => $_clearField(10);

  @$pb.TagNumber(11)
  $fixnum.Int64 get observedAtUnixMs => $_getI64(10);
  @$pb.TagNumber(11)
  set observedAtUnixMs($fixnum.Int64 value) => $_setInt64(10, value);
  @$pb.TagNumber(11)
  $core.bool hasObservedAtUnixMs() => $_has(10);
  @$pb.TagNumber(11)
  void clearObservedAtUnixMs() => $_clearField(11);
}

class PolicyDecision extends $pb.GeneratedMessage {
  factory PolicyDecision({
    $fixnum.Int64? commandId,
    $fixnum.Int64? proposedVersion,
    $fixnum.Int64? effectiveSequence,
    $core.double? proposedKalmanQ,
    $core.double? proposedKalmanR,
    $core.bool? resetState,
    $core.String? reason,
  }) {
    final result = PolicyDecision._();
    if (commandId != null) result.commandId = commandId;
    if (proposedVersion != null) result.proposedVersion = proposedVersion;
    if (effectiveSequence != null) result.effectiveSequence = effectiveSequence;
    if (proposedKalmanQ != null) result.proposedKalmanQ = proposedKalmanQ;
    if (proposedKalmanR != null) result.proposedKalmanR = proposedKalmanR;
    if (resetState != null) result.resetState = resetState;
    if (reason != null) result.reason = reason;
    return result;
  }

  PolicyDecision._();

  factory PolicyDecision.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PolicyDecision()..mergeFromBuffer(data, registry);
  factory PolicyDecision.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PolicyDecision()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PolicyDecision',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'livekalman.control.v1'),
      createEmptyInstance: PolicyDecision.$_createMessage)
    ..a<$fixnum.Int64>(
        1, _omitFieldNames ? '' : 'commandId', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'proposedVersion', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        3, _omitFieldNames ? '' : 'effectiveSequence', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aD(4, _omitFieldNames ? '' : 'proposedKalmanQ',
        fieldType: $pb.PbFieldType.OF)
    ..aD(5, _omitFieldNames ? '' : 'proposedKalmanR',
        fieldType: $pb.PbFieldType.OF)
    ..aOB(6, _omitFieldNames ? '' : 'resetState')
    ..aOS(7, _omitFieldNames ? '' : 'reason')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PolicyDecision clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PolicyDecision copyWith(void Function(PolicyDecision) updates) =>
      super.copyWith((message) => updates(message as PolicyDecision))
          as PolicyDecision;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use PolicyDecision() / PolicyDecision.new instead')
  static PolicyDecision create() => PolicyDecision._();
  static $pb.GeneratedMessage $_createMessage() => PolicyDecision._();
  @$core.override
  PolicyDecision createEmptyInstance() => PolicyDecision._();
  @$core.pragma('dart2js:noInline')
  static PolicyDecision getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PolicyDecision>(
          PolicyDecision.$_createMessage);
  static PolicyDecision? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get commandId => $_getI64(0);
  @$pb.TagNumber(1)
  set commandId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCommandId() => $_has(0);
  @$pb.TagNumber(1)
  void clearCommandId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get proposedVersion => $_getI64(1);
  @$pb.TagNumber(2)
  set proposedVersion($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasProposedVersion() => $_has(1);
  @$pb.TagNumber(2)
  void clearProposedVersion() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get effectiveSequence => $_getI64(2);
  @$pb.TagNumber(3)
  set effectiveSequence($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasEffectiveSequence() => $_has(2);
  @$pb.TagNumber(3)
  void clearEffectiveSequence() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.double get proposedKalmanQ => $_getN(3);
  @$pb.TagNumber(4)
  set proposedKalmanQ($core.double value) => $_setFloat(3, value);
  @$pb.TagNumber(4)
  $core.bool hasProposedKalmanQ() => $_has(3);
  @$pb.TagNumber(4)
  void clearProposedKalmanQ() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.double get proposedKalmanR => $_getN(4);
  @$pb.TagNumber(5)
  set proposedKalmanR($core.double value) => $_setFloat(4, value);
  @$pb.TagNumber(5)
  $core.bool hasProposedKalmanR() => $_has(4);
  @$pb.TagNumber(5)
  void clearProposedKalmanR() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.bool get resetState => $_getBF(5);
  @$pb.TagNumber(6)
  set resetState($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasResetState() => $_has(5);
  @$pb.TagNumber(6)
  void clearResetState() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get reason => $_getSZ(6);
  @$pb.TagNumber(7)
  set reason($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasReason() => $_has(6);
  @$pb.TagNumber(7)
  void clearReason() => $_clearField(7);
}

class WatchRequest extends $pb.GeneratedMessage {
  factory WatchRequest({
    $core.String? runId,
  }) {
    final result = WatchRequest._();
    if (runId != null) result.runId = runId;
    return result;
  }

  WatchRequest._();

  factory WatchRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      WatchRequest()..mergeFromBuffer(data, registry);
  factory WatchRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      WatchRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WatchRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'livekalman.control.v1'),
      createEmptyInstance: WatchRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'runId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WatchRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WatchRequest copyWith(void Function(WatchRequest) updates) =>
      super.copyWith((message) => updates(message as WatchRequest))
          as WatchRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use WatchRequest() / WatchRequest.new instead')
  static WatchRequest create() => WatchRequest._();
  static $pb.GeneratedMessage $_createMessage() => WatchRequest._();
  @$core.override
  WatchRequest createEmptyInstance() => WatchRequest._();
  @$core.pragma('dart2js:noInline')
  static WatchRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<WatchRequest>(
          WatchRequest.$_createMessage);
  static WatchRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get runId => $_getSZ(0);
  @$pb.TagNumber(1)
  set runId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRunId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRunId() => $_clearField(1);
}

class ExperimentEvent extends $pb.GeneratedMessage {
  factory ExperimentEvent({
    $core.String? runId,
    $fixnum.Int64? sequence,
    $core.String? kind,
    $core.String? description,
    ReceiverMetrics? metrics,
    PolicyDecision? decision,
    $fixnum.Int64? emittedAtUnixMs,
  }) {
    final result = ExperimentEvent._();
    if (runId != null) result.runId = runId;
    if (sequence != null) result.sequence = sequence;
    if (kind != null) result.kind = kind;
    if (description != null) result.description = description;
    if (metrics != null) result.metrics = metrics;
    if (decision != null) result.decision = decision;
    if (emittedAtUnixMs != null) result.emittedAtUnixMs = emittedAtUnixMs;
    return result;
  }

  ExperimentEvent._();

  factory ExperimentEvent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ExperimentEvent()..mergeFromBuffer(data, registry);
  factory ExperimentEvent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ExperimentEvent()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ExperimentEvent',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'livekalman.control.v1'),
      createEmptyInstance: ExperimentEvent.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'runId')
    ..a<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'sequence', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(3, _omitFieldNames ? '' : 'kind')
    ..aOS(4, _omitFieldNames ? '' : 'description')
    ..aOM<ReceiverMetrics>(5, _omitFieldNames ? '' : 'metrics',
        subBuilder: ReceiverMetrics.$_createMessage)
    ..aOM<PolicyDecision>(6, _omitFieldNames ? '' : 'decision',
        subBuilder: PolicyDecision.$_createMessage)
    ..a<$fixnum.Int64>(
        7, _omitFieldNames ? '' : 'emittedAtUnixMs', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExperimentEvent clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExperimentEvent copyWith(void Function(ExperimentEvent) updates) =>
      super.copyWith((message) => updates(message as ExperimentEvent))
          as ExperimentEvent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ExperimentEvent() / ExperimentEvent.new instead')
  static ExperimentEvent create() => ExperimentEvent._();
  static $pb.GeneratedMessage $_createMessage() => ExperimentEvent._();
  @$core.override
  ExperimentEvent createEmptyInstance() => ExperimentEvent._();
  @$core.pragma('dart2js:noInline')
  static ExperimentEvent getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ExperimentEvent>(
          ExperimentEvent.$_createMessage);
  static ExperimentEvent? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get runId => $_getSZ(0);
  @$pb.TagNumber(1)
  set runId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRunId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRunId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get sequence => $_getI64(1);
  @$pb.TagNumber(2)
  set sequence($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSequence() => $_has(1);
  @$pb.TagNumber(2)
  void clearSequence() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get kind => $_getSZ(2);
  @$pb.TagNumber(3)
  set kind($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasKind() => $_has(2);
  @$pb.TagNumber(3)
  void clearKind() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get description => $_getSZ(3);
  @$pb.TagNumber(4)
  set description($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasDescription() => $_has(3);
  @$pb.TagNumber(4)
  void clearDescription() => $_clearField(4);

  @$pb.TagNumber(5)
  ReceiverMetrics get metrics => $_getN(4);
  @$pb.TagNumber(5)
  set metrics(ReceiverMetrics value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasMetrics() => $_has(4);
  @$pb.TagNumber(5)
  void clearMetrics() => $_clearField(5);
  @$pb.TagNumber(5)
  ReceiverMetrics ensureMetrics() => $_ensure(4);

  @$pb.TagNumber(6)
  PolicyDecision get decision => $_getN(5);
  @$pb.TagNumber(6)
  set decision(PolicyDecision value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasDecision() => $_has(5);
  @$pb.TagNumber(6)
  void clearDecision() => $_clearField(6);
  @$pb.TagNumber(6)
  PolicyDecision ensureDecision() => $_ensure(5);

  @$pb.TagNumber(7)
  $fixnum.Int64 get emittedAtUnixMs => $_getI64(6);
  @$pb.TagNumber(7)
  set emittedAtUnixMs($fixnum.Int64 value) => $_setInt64(6, value);
  @$pb.TagNumber(7)
  $core.bool hasEmittedAtUnixMs() => $_has(6);
  @$pb.TagNumber(7)
  void clearEmittedAtUnixMs() => $_clearField(7);
}

class ExperimentStateRequest extends $pb.GeneratedMessage {
  factory ExperimentStateRequest({
    $core.String? runId,
  }) {
    final result = ExperimentStateRequest._();
    if (runId != null) result.runId = runId;
    return result;
  }

  ExperimentStateRequest._();

  factory ExperimentStateRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ExperimentStateRequest()..mergeFromBuffer(data, registry);
  factory ExperimentStateRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ExperimentStateRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ExperimentStateRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'livekalman.control.v1'),
      createEmptyInstance: ExperimentStateRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'runId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExperimentStateRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExperimentStateRequest copyWith(
          void Function(ExperimentStateRequest) updates) =>
      super.copyWith((message) => updates(message as ExperimentStateRequest))
          as ExperimentStateRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ExperimentStateRequest() / ExperimentStateRequest.new instead')
  static ExperimentStateRequest create() => ExperimentStateRequest._();
  static $pb.GeneratedMessage $_createMessage() => ExperimentStateRequest._();
  @$core.override
  ExperimentStateRequest createEmptyInstance() => ExperimentStateRequest._();
  @$core.pragma('dart2js:noInline')
  static ExperimentStateRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ExperimentStateRequest>(
          ExperimentStateRequest.$_createMessage);
  static ExperimentStateRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get runId => $_getSZ(0);
  @$pb.TagNumber(1)
  set runId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRunId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRunId() => $_clearField(1);
}

class ExperimentState extends $pb.GeneratedMessage {
  factory ExperimentState({
    $core.String? runId,
    $core.bool? active,
    ReceiverMetrics? latest,
    $fixnum.Int64? desiredConfigVersion,
  }) {
    final result = ExperimentState._();
    if (runId != null) result.runId = runId;
    if (active != null) result.active = active;
    if (latest != null) result.latest = latest;
    if (desiredConfigVersion != null)
      result.desiredConfigVersion = desiredConfigVersion;
    return result;
  }

  ExperimentState._();

  factory ExperimentState.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ExperimentState()..mergeFromBuffer(data, registry);
  factory ExperimentState.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ExperimentState()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ExperimentState',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'livekalman.control.v1'),
      createEmptyInstance: ExperimentState.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'runId')
    ..aOB(2, _omitFieldNames ? '' : 'active')
    ..aOM<ReceiverMetrics>(3, _omitFieldNames ? '' : 'latest',
        subBuilder: ReceiverMetrics.$_createMessage)
    ..a<$fixnum.Int64>(
        4, _omitFieldNames ? '' : 'desiredConfigVersion', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExperimentState clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExperimentState copyWith(void Function(ExperimentState) updates) =>
      super.copyWith((message) => updates(message as ExperimentState))
          as ExperimentState;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ExperimentState() / ExperimentState.new instead')
  static ExperimentState create() => ExperimentState._();
  static $pb.GeneratedMessage $_createMessage() => ExperimentState._();
  @$core.override
  ExperimentState createEmptyInstance() => ExperimentState._();
  @$core.pragma('dart2js:noInline')
  static ExperimentState getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ExperimentState>(
          ExperimentState.$_createMessage);
  static ExperimentState? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get runId => $_getSZ(0);
  @$pb.TagNumber(1)
  set runId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRunId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRunId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get active => $_getBF(1);
  @$pb.TagNumber(2)
  set active($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasActive() => $_has(1);
  @$pb.TagNumber(2)
  void clearActive() => $_clearField(2);

  @$pb.TagNumber(3)
  ReceiverMetrics get latest => $_getN(2);
  @$pb.TagNumber(3)
  set latest(ReceiverMetrics value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasLatest() => $_has(2);
  @$pb.TagNumber(3)
  void clearLatest() => $_clearField(3);
  @$pb.TagNumber(3)
  ReceiverMetrics ensureLatest() => $_ensure(2);

  @$pb.TagNumber(4)
  $fixnum.Int64 get desiredConfigVersion => $_getI64(3);
  @$pb.TagNumber(4)
  set desiredConfigVersion($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasDesiredConfigVersion() => $_has(3);
  @$pb.TagNumber(4)
  void clearDesiredConfigVersion() => $_clearField(4);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
