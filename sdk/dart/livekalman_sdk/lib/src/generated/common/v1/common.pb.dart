// This is a generated file - do not edit.
//
// Generated from common/v1/common.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'common.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'common.pbenum.dart';

class Empty extends $pb.GeneratedMessage {
  factory Empty() => Empty._();

  Empty._();

  factory Empty.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Empty()..mergeFromBuffer(data, registry);
  factory Empty.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Empty()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Empty',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'livekalman.common.v1'),
      createEmptyInstance: Empty.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Empty clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Empty copyWith(void Function(Empty) updates) =>
      super.copyWith((message) => updates(message as Empty)) as Empty;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Empty() / Empty.new instead')
  static Empty create() => Empty._();
  static $pb.GeneratedMessage $_createMessage() => Empty._();
  @$core.override
  Empty createEmptyInstance() => Empty._();
  @$core.pragma('dart2js:noInline')
  static Empty getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Empty>(Empty.$_createMessage);
  static Empty? _defaultInstance;
}

class Capability extends $pb.GeneratedMessage {
  factory Capability({
    $core.String? name,
    $core.String? version,
    $core.Iterable<$core.MapEntry<$core.String, $core.String>>? attributes,
  }) {
    final result = Capability._();
    if (name != null) result.name = name;
    if (version != null) result.version = version;
    if (attributes != null) result.attributes.addEntries(attributes);
    return result;
  }

  Capability._();

  factory Capability.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Capability()..mergeFromBuffer(data, registry);
  factory Capability.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Capability()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Capability',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'livekalman.common.v1'),
      createEmptyInstance: Capability.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOS(2, _omitFieldNames ? '' : 'version')
    ..m<$core.String, $core.String>(3, _omitFieldNames ? '' : 'attributes',
        entryClassName: 'Capability.AttributesEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OS,
        packageName: const $pb.PackageName('livekalman.common.v1'))
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Capability clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Capability copyWith(void Function(Capability) updates) =>
      super.copyWith((message) => updates(message as Capability)) as Capability;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Capability() / Capability.new instead')
  static Capability create() => Capability._();
  static $pb.GeneratedMessage $_createMessage() => Capability._();
  @$core.override
  Capability createEmptyInstance() => Capability._();
  @$core.pragma('dart2js:noInline')
  static Capability getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Capability>(Capability.$_createMessage);
  static Capability? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get version => $_getSZ(1);
  @$pb.TagNumber(2)
  set version($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasVersion() => $_has(1);
  @$pb.TagNumber(2)
  void clearVersion() => $_clearField(2);

  @$pb.TagNumber(3)
  $pb.PbMap<$core.String, $core.String> get attributes => $_getMap(2);
}

class NodeInfo extends $pb.GeneratedMessage {
  factory NodeInfo({
    $core.String? nodeId,
    $core.String? displayName,
    NodeRole? role,
    $core.String? apiVersion,
    $core.String? listenAddress,
    $core.Iterable<Capability>? capabilities,
  }) {
    final result = NodeInfo._();
    if (nodeId != null) result.nodeId = nodeId;
    if (displayName != null) result.displayName = displayName;
    if (role != null) result.role = role;
    if (apiVersion != null) result.apiVersion = apiVersion;
    if (listenAddress != null) result.listenAddress = listenAddress;
    if (capabilities != null) result.capabilities.addAll(capabilities);
    return result;
  }

  NodeInfo._();

  factory NodeInfo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      NodeInfo()..mergeFromBuffer(data, registry);
  factory NodeInfo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      NodeInfo()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'NodeInfo',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'livekalman.common.v1'),
      createEmptyInstance: NodeInfo.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'nodeId')
    ..aOS(2, _omitFieldNames ? '' : 'displayName')
    ..aE<NodeRole>(3, _omitFieldNames ? '' : 'role',
        enumValues: NodeRole.values)
    ..aOS(4, _omitFieldNames ? '' : 'apiVersion')
    ..aOS(5, _omitFieldNames ? '' : 'listenAddress')
    ..pPM<Capability>(6, _omitFieldNames ? '' : 'capabilities',
        subBuilder: Capability.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NodeInfo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NodeInfo copyWith(void Function(NodeInfo) updates) =>
      super.copyWith((message) => updates(message as NodeInfo)) as NodeInfo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use NodeInfo() / NodeInfo.new instead')
  static NodeInfo create() => NodeInfo._();
  static $pb.GeneratedMessage $_createMessage() => NodeInfo._();
  @$core.override
  NodeInfo createEmptyInstance() => NodeInfo._();
  @$core.pragma('dart2js:noInline')
  static NodeInfo getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<NodeInfo>(NodeInfo.$_createMessage);
  static NodeInfo? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get nodeId => $_getSZ(0);
  @$pb.TagNumber(1)
  set nodeId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasNodeId() => $_has(0);
  @$pb.TagNumber(1)
  void clearNodeId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get displayName => $_getSZ(1);
  @$pb.TagNumber(2)
  set displayName($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDisplayName() => $_has(1);
  @$pb.TagNumber(2)
  void clearDisplayName() => $_clearField(2);

  @$pb.TagNumber(3)
  NodeRole get role => $_getN(2);
  @$pb.TagNumber(3)
  set role(NodeRole value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasRole() => $_has(2);
  @$pb.TagNumber(3)
  void clearRole() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get apiVersion => $_getSZ(3);
  @$pb.TagNumber(4)
  set apiVersion($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasApiVersion() => $_has(3);
  @$pb.TagNumber(4)
  void clearApiVersion() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get listenAddress => $_getSZ(4);
  @$pb.TagNumber(5)
  set listenAddress($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasListenAddress() => $_has(4);
  @$pb.TagNumber(5)
  void clearListenAddress() => $_clearField(5);

  @$pb.TagNumber(6)
  $pb.PbList<Capability> get capabilities => $_getList(5);
}

class NodeStatus extends $pb.GeneratedMessage {
  factory NodeStatus({
    $core.String? nodeId,
    NodeRole? role,
    HealthState? health,
    $core.bool? active,
    $core.bool? peerConnected,
    $core.String? activeRunId,
    $fixnum.Int64? activeConfigVersion,
    $fixnum.Int64? lastSequence,
    $fixnum.Int64? uptimeMs,
    $core.String? message,
    $fixnum.Int64? observedAtUnixMs,
  }) {
    final result = NodeStatus._();
    if (nodeId != null) result.nodeId = nodeId;
    if (role != null) result.role = role;
    if (health != null) result.health = health;
    if (active != null) result.active = active;
    if (peerConnected != null) result.peerConnected = peerConnected;
    if (activeRunId != null) result.activeRunId = activeRunId;
    if (activeConfigVersion != null)
      result.activeConfigVersion = activeConfigVersion;
    if (lastSequence != null) result.lastSequence = lastSequence;
    if (uptimeMs != null) result.uptimeMs = uptimeMs;
    if (message != null) result.message = message;
    if (observedAtUnixMs != null) result.observedAtUnixMs = observedAtUnixMs;
    return result;
  }

  NodeStatus._();

  factory NodeStatus.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      NodeStatus()..mergeFromBuffer(data, registry);
  factory NodeStatus.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      NodeStatus()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'NodeStatus',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'livekalman.common.v1'),
      createEmptyInstance: NodeStatus.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'nodeId')
    ..aE<NodeRole>(2, _omitFieldNames ? '' : 'role',
        enumValues: NodeRole.values)
    ..aE<HealthState>(3, _omitFieldNames ? '' : 'health',
        enumValues: HealthState.values)
    ..aOB(4, _omitFieldNames ? '' : 'active')
    ..aOB(5, _omitFieldNames ? '' : 'peerConnected')
    ..aOS(6, _omitFieldNames ? '' : 'activeRunId')
    ..a<$fixnum.Int64>(
        7, _omitFieldNames ? '' : 'activeConfigVersion', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        8, _omitFieldNames ? '' : 'lastSequence', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        9, _omitFieldNames ? '' : 'uptimeMs', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(10, _omitFieldNames ? '' : 'message')
    ..a<$fixnum.Int64>(
        11, _omitFieldNames ? '' : 'observedAtUnixMs', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NodeStatus clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NodeStatus copyWith(void Function(NodeStatus) updates) =>
      super.copyWith((message) => updates(message as NodeStatus)) as NodeStatus;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use NodeStatus() / NodeStatus.new instead')
  static NodeStatus create() => NodeStatus._();
  static $pb.GeneratedMessage $_createMessage() => NodeStatus._();
  @$core.override
  NodeStatus createEmptyInstance() => NodeStatus._();
  @$core.pragma('dart2js:noInline')
  static NodeStatus getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<NodeStatus>(NodeStatus.$_createMessage);
  static NodeStatus? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get nodeId => $_getSZ(0);
  @$pb.TagNumber(1)
  set nodeId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasNodeId() => $_has(0);
  @$pb.TagNumber(1)
  void clearNodeId() => $_clearField(1);

  @$pb.TagNumber(2)
  NodeRole get role => $_getN(1);
  @$pb.TagNumber(2)
  set role(NodeRole value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasRole() => $_has(1);
  @$pb.TagNumber(2)
  void clearRole() => $_clearField(2);

  @$pb.TagNumber(3)
  HealthState get health => $_getN(2);
  @$pb.TagNumber(3)
  set health(HealthState value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasHealth() => $_has(2);
  @$pb.TagNumber(3)
  void clearHealth() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get active => $_getBF(3);
  @$pb.TagNumber(4)
  set active($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasActive() => $_has(3);
  @$pb.TagNumber(4)
  void clearActive() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get peerConnected => $_getBF(4);
  @$pb.TagNumber(5)
  set peerConnected($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasPeerConnected() => $_has(4);
  @$pb.TagNumber(5)
  void clearPeerConnected() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get activeRunId => $_getSZ(5);
  @$pb.TagNumber(6)
  set activeRunId($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasActiveRunId() => $_has(5);
  @$pb.TagNumber(6)
  void clearActiveRunId() => $_clearField(6);

  @$pb.TagNumber(7)
  $fixnum.Int64 get activeConfigVersion => $_getI64(6);
  @$pb.TagNumber(7)
  set activeConfigVersion($fixnum.Int64 value) => $_setInt64(6, value);
  @$pb.TagNumber(7)
  $core.bool hasActiveConfigVersion() => $_has(6);
  @$pb.TagNumber(7)
  void clearActiveConfigVersion() => $_clearField(7);

  @$pb.TagNumber(8)
  $fixnum.Int64 get lastSequence => $_getI64(7);
  @$pb.TagNumber(8)
  set lastSequence($fixnum.Int64 value) => $_setInt64(7, value);
  @$pb.TagNumber(8)
  $core.bool hasLastSequence() => $_has(7);
  @$pb.TagNumber(8)
  void clearLastSequence() => $_clearField(8);

  @$pb.TagNumber(9)
  $fixnum.Int64 get uptimeMs => $_getI64(8);
  @$pb.TagNumber(9)
  set uptimeMs($fixnum.Int64 value) => $_setInt64(8, value);
  @$pb.TagNumber(9)
  $core.bool hasUptimeMs() => $_has(8);
  @$pb.TagNumber(9)
  void clearUptimeMs() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.String get message => $_getSZ(9);
  @$pb.TagNumber(10)
  set message($core.String value) => $_setString(9, value);
  @$pb.TagNumber(10)
  $core.bool hasMessage() => $_has(9);
  @$pb.TagNumber(10)
  void clearMessage() => $_clearField(10);

  @$pb.TagNumber(11)
  $fixnum.Int64 get observedAtUnixMs => $_getI64(10);
  @$pb.TagNumber(11)
  set observedAtUnixMs($fixnum.Int64 value) => $_setInt64(10, value);
  @$pb.TagNumber(11)
  $core.bool hasObservedAtUnixMs() => $_has(10);
  @$pb.TagNumber(11)
  void clearObservedAtUnixMs() => $_clearField(11);
}

class WatchNodeRequest extends $pb.GeneratedMessage {
  factory WatchNodeRequest({
    $core.int? intervalMs,
  }) {
    final result = WatchNodeRequest._();
    if (intervalMs != null) result.intervalMs = intervalMs;
    return result;
  }

  WatchNodeRequest._();

  factory WatchNodeRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      WatchNodeRequest()..mergeFromBuffer(data, registry);
  factory WatchNodeRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      WatchNodeRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WatchNodeRequest',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'livekalman.common.v1'),
      createEmptyInstance: WatchNodeRequest.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'intervalMs', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WatchNodeRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WatchNodeRequest copyWith(void Function(WatchNodeRequest) updates) =>
      super.copyWith((message) => updates(message as WatchNodeRequest))
          as WatchNodeRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use WatchNodeRequest() / WatchNodeRequest.new instead')
  static WatchNodeRequest create() => WatchNodeRequest._();
  static $pb.GeneratedMessage $_createMessage() => WatchNodeRequest._();
  @$core.override
  WatchNodeRequest createEmptyInstance() => WatchNodeRequest._();
  @$core.pragma('dart2js:noInline')
  static WatchNodeRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<WatchNodeRequest>(
          WatchNodeRequest.$_createMessage);
  static WatchNodeRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get intervalMs => $_getIZ(0);
  @$pb.TagNumber(1)
  set intervalMs($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasIntervalMs() => $_has(0);
  @$pb.TagNumber(1)
  void clearIntervalMs() => $_clearField(1);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
