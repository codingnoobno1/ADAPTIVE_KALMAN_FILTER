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

import 'package:protobuf/protobuf.dart' as $pb;

/// SampleFormat makes the byte representation explicit for embedded producers.
class SampleFormat extends $pb.ProtobufEnum {
  static const SampleFormat SAMPLE_FORMAT_UNSPECIFIED =
      SampleFormat._(0, _omitEnumNames ? '' : 'SAMPLE_FORMAT_UNSPECIFIED');
  static const SampleFormat SAMPLE_FORMAT_FLOAT32_LE =
      SampleFormat._(1, _omitEnumNames ? '' : 'SAMPLE_FORMAT_FLOAT32_LE');
  static const SampleFormat SAMPLE_FORMAT_INT16_LE =
      SampleFormat._(2, _omitEnumNames ? '' : 'SAMPLE_FORMAT_INT16_LE');

  static const $core.List<SampleFormat> values = <SampleFormat>[
    SAMPLE_FORMAT_UNSPECIFIED,
    SAMPLE_FORMAT_FLOAT32_LE,
    SAMPLE_FORMAT_INT16_LE,
  ];

  static final $core.List<SampleFormat?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static SampleFormat? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const SampleFormat._(super.value, super.name);
}

/// NodeRole identifies the independently deployable process behind an endpoint.
class NodeRole extends $pb.ProtobufEnum {
  static const NodeRole NODE_ROLE_UNSPECIFIED =
      NodeRole._(0, _omitEnumNames ? '' : 'NODE_ROLE_UNSPECIFIED');
  static const NodeRole NODE_ROLE_TRANSMITTER =
      NodeRole._(1, _omitEnumNames ? '' : 'NODE_ROLE_TRANSMITTER');
  static const NodeRole NODE_ROLE_RECEIVER =
      NodeRole._(2, _omitEnumNames ? '' : 'NODE_ROLE_RECEIVER');
  static const NodeRole NODE_ROLE_CONTROLLER =
      NodeRole._(3, _omitEnumNames ? '' : 'NODE_ROLE_CONTROLLER');

  static const $core.List<NodeRole> values = <NodeRole>[
    NODE_ROLE_UNSPECIFIED,
    NODE_ROLE_TRANSMITTER,
    NODE_ROLE_RECEIVER,
    NODE_ROLE_CONTROLLER,
  ];

  static final $core.List<NodeRole?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static NodeRole? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const NodeRole._(super.value, super.name);
}

class HealthState extends $pb.ProtobufEnum {
  static const HealthState HEALTH_STATE_UNSPECIFIED =
      HealthState._(0, _omitEnumNames ? '' : 'HEALTH_STATE_UNSPECIFIED');
  static const HealthState HEALTH_STATE_STARTING =
      HealthState._(1, _omitEnumNames ? '' : 'HEALTH_STATE_STARTING');
  static const HealthState HEALTH_STATE_READY =
      HealthState._(2, _omitEnumNames ? '' : 'HEALTH_STATE_READY');
  static const HealthState HEALTH_STATE_DEGRADED =
      HealthState._(3, _omitEnumNames ? '' : 'HEALTH_STATE_DEGRADED');
  static const HealthState HEALTH_STATE_STOPPING =
      HealthState._(4, _omitEnumNames ? '' : 'HEALTH_STATE_STOPPING');

  static const $core.List<HealthState> values = <HealthState>[
    HEALTH_STATE_UNSPECIFIED,
    HEALTH_STATE_STARTING,
    HEALTH_STATE_READY,
    HEALTH_STATE_DEGRADED,
    HEALTH_STATE_STOPPING,
  ];

  static final $core.List<HealthState?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 4);
  static HealthState? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const HealthState._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
