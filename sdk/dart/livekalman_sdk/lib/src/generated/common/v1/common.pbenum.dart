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

/// MediaType is the receiver's content classification. A producer may provide a
/// hint, but the receiver derives the final value from the reconstructed bytes.
class MediaType extends $pb.ProtobufEnum {
  static const MediaType MEDIA_TYPE_UNSPECIFIED =
      MediaType._(0, _omitEnumNames ? '' : 'MEDIA_TYPE_UNSPECIFIED');
  static const MediaType MEDIA_TYPE_BINARY =
      MediaType._(1, _omitEnumNames ? '' : 'MEDIA_TYPE_BINARY');
  static const MediaType MEDIA_TYPE_TEXT =
      MediaType._(2, _omitEnumNames ? '' : 'MEDIA_TYPE_TEXT');
  static const MediaType MEDIA_TYPE_IMAGE =
      MediaType._(3, _omitEnumNames ? '' : 'MEDIA_TYPE_IMAGE');
  static const MediaType MEDIA_TYPE_AUDIO =
      MediaType._(4, _omitEnumNames ? '' : 'MEDIA_TYPE_AUDIO');

  static const $core.List<MediaType> values = <MediaType>[
    MEDIA_TYPE_UNSPECIFIED,
    MEDIA_TYPE_BINARY,
    MEDIA_TYPE_TEXT,
    MEDIA_TYPE_IMAGE,
    MEDIA_TYPE_AUDIO,
  ];

  static final $core.List<MediaType?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 4);
  static MediaType? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const MediaType._(super.value, super.name);
}

/// Modulation identifies how payload bits were converted into signal symbols.
class Modulation extends $pb.ProtobufEnum {
  static const Modulation MODULATION_UNSPECIFIED =
      Modulation._(0, _omitEnumNames ? '' : 'MODULATION_UNSPECIFIED');
  static const Modulation MODULATION_BPSK =
      Modulation._(1, _omitEnumNames ? '' : 'MODULATION_BPSK');

  static const $core.List<Modulation> values = <Modulation>[
    MODULATION_UNSPECIFIED,
    MODULATION_BPSK,
  ];

  static final $core.List<Modulation?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 1);
  static Modulation? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const Modulation._(super.value, super.name);
}

/// PayloadEncoding is applied to bytes before modulation and reversed only
/// after demodulation. BYTE_SHIFT is useful for teaching, not for security.
class PayloadEncoding extends $pb.ProtobufEnum {
  static const PayloadEncoding PAYLOAD_ENCODING_UNSPECIFIED = PayloadEncoding._(
      0, _omitEnumNames ? '' : 'PAYLOAD_ENCODING_UNSPECIFIED');
  static const PayloadEncoding PAYLOAD_ENCODING_RAW =
      PayloadEncoding._(1, _omitEnumNames ? '' : 'PAYLOAD_ENCODING_RAW');
  static const PayloadEncoding PAYLOAD_ENCODING_BYTE_SHIFT =
      PayloadEncoding._(2, _omitEnumNames ? '' : 'PAYLOAD_ENCODING_BYTE_SHIFT');

  static const $core.List<PayloadEncoding> values = <PayloadEncoding>[
    PAYLOAD_ENCODING_UNSPECIFIED,
    PAYLOAD_ENCODING_RAW,
    PAYLOAD_ENCODING_BYTE_SHIFT,
  ];

  static final $core.List<PayloadEncoding?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static PayloadEncoding? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const PayloadEncoding._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
