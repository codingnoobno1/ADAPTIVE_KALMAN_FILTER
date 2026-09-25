// This is a generated file - do not edit.
//
// Generated from control/v1/controller.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use receiverMetricsDescriptor instead')
const ReceiverMetrics$json = {
  '1': 'ReceiverMetrics',
  '2': [
    {'1': 'run_id', '3': 1, '4': 1, '5': 9, '10': 'runId'},
    {'1': 'sequence', '3': 2, '4': 1, '5': 4, '10': 'sequence'},
    {'1': 'snr_db', '3': 3, '4': 1, '5': 2, '10': 'snrDb'},
    {'1': 'noise_variance', '3': 4, '4': 1, '5': 2, '10': 'noiseVariance'},
    {'1': 'compared_bits', '3': 5, '4': 1, '5': 4, '10': 'comparedBits'},
    {'1': 'bit_errors', '3': 6, '4': 1, '5': 4, '10': 'bitErrors'},
    {'1': 'ber', '3': 7, '4': 1, '5': 2, '10': 'ber'},
    {'1': 'latency_ms', '3': 8, '4': 1, '5': 1, '10': 'latencyMs'},
    {
      '1': 'active_config_version',
      '3': 9,
      '4': 1,
      '5': 4,
      '10': 'activeConfigVersion'
    },
    {'1': 'queue_depth', '3': 10, '4': 1, '5': 13, '10': 'queueDepth'},
    {
      '1': 'observed_at_unix_ms',
      '3': 11,
      '4': 1,
      '5': 4,
      '10': 'observedAtUnixMs'
    },
  ],
};

/// Descriptor for `ReceiverMetrics`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List receiverMetricsDescriptor = $convert.base64Decode(
    'Cg9SZWNlaXZlck1ldHJpY3MSFQoGcnVuX2lkGAEgASgJUgVydW5JZBIaCghzZXF1ZW5jZRgCIA'
    'EoBFIIc2VxdWVuY2USFQoGc25yX2RiGAMgASgCUgVzbnJEYhIlCg5ub2lzZV92YXJpYW5jZRgE'
    'IAEoAlINbm9pc2VWYXJpYW5jZRIjCg1jb21wYXJlZF9iaXRzGAUgASgEUgxjb21wYXJlZEJpdH'
    'MSHQoKYml0X2Vycm9ycxgGIAEoBFIJYml0RXJyb3JzEhAKA2JlchgHIAEoAlIDYmVyEh0KCmxh'
    'dGVuY3lfbXMYCCABKAFSCWxhdGVuY3lNcxIyChVhY3RpdmVfY29uZmlnX3ZlcnNpb24YCSABKA'
    'RSE2FjdGl2ZUNvbmZpZ1ZlcnNpb24SHwoLcXVldWVfZGVwdGgYCiABKA1SCnF1ZXVlRGVwdGgS'
    'LQoTb2JzZXJ2ZWRfYXRfdW5peF9tcxgLIAEoBFIQb2JzZXJ2ZWRBdFVuaXhNcw==');

@$core.Deprecated('Use policyDecisionDescriptor instead')
const PolicyDecision$json = {
  '1': 'PolicyDecision',
  '2': [
    {'1': 'command_id', '3': 1, '4': 1, '5': 4, '10': 'commandId'},
    {'1': 'proposed_version', '3': 2, '4': 1, '5': 4, '10': 'proposedVersion'},
    {
      '1': 'effective_sequence',
      '3': 3,
      '4': 1,
      '5': 4,
      '10': 'effectiveSequence'
    },
    {'1': 'proposed_kalman_q', '3': 4, '4': 1, '5': 2, '10': 'proposedKalmanQ'},
    {'1': 'proposed_kalman_r', '3': 5, '4': 1, '5': 2, '10': 'proposedKalmanR'},
    {'1': 'reset_state', '3': 6, '4': 1, '5': 8, '10': 'resetState'},
    {'1': 'reason', '3': 7, '4': 1, '5': 9, '10': 'reason'},
  ],
};

/// Descriptor for `PolicyDecision`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List policyDecisionDescriptor = $convert.base64Decode(
    'Cg5Qb2xpY3lEZWNpc2lvbhIdCgpjb21tYW5kX2lkGAEgASgEUgljb21tYW5kSWQSKQoQcHJvcG'
    '9zZWRfdmVyc2lvbhgCIAEoBFIPcHJvcG9zZWRWZXJzaW9uEi0KEmVmZmVjdGl2ZV9zZXF1ZW5j'
    'ZRgDIAEoBFIRZWZmZWN0aXZlU2VxdWVuY2USKgoRcHJvcG9zZWRfa2FsbWFuX3EYBCABKAJSD3'
    'Byb3Bvc2VkS2FsbWFuURIqChFwcm9wb3NlZF9rYWxtYW5fchgFIAEoAlIPcHJvcG9zZWRLYWxt'
    'YW5SEh8KC3Jlc2V0X3N0YXRlGAYgASgIUgpyZXNldFN0YXRlEhYKBnJlYXNvbhgHIAEoCVIGcm'
    'Vhc29u');

@$core.Deprecated('Use watchRequestDescriptor instead')
const WatchRequest$json = {
  '1': 'WatchRequest',
  '2': [
    {'1': 'run_id', '3': 1, '4': 1, '5': 9, '10': 'runId'},
  ],
};

/// Descriptor for `WatchRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List watchRequestDescriptor = $convert
    .base64Decode('CgxXYXRjaFJlcXVlc3QSFQoGcnVuX2lkGAEgASgJUgVydW5JZA==');

@$core.Deprecated('Use experimentEventDescriptor instead')
const ExperimentEvent$json = {
  '1': 'ExperimentEvent',
  '2': [
    {'1': 'run_id', '3': 1, '4': 1, '5': 9, '10': 'runId'},
    {'1': 'sequence', '3': 2, '4': 1, '5': 4, '10': 'sequence'},
    {'1': 'kind', '3': 3, '4': 1, '5': 9, '10': 'kind'},
    {'1': 'description', '3': 4, '4': 1, '5': 9, '10': 'description'},
    {
      '1': 'metrics',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.livekalman.control.v1.ReceiverMetrics',
      '10': 'metrics'
    },
    {
      '1': 'decision',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.livekalman.control.v1.PolicyDecision',
      '10': 'decision'
    },
    {
      '1': 'emitted_at_unix_ms',
      '3': 7,
      '4': 1,
      '5': 4,
      '10': 'emittedAtUnixMs'
    },
  ],
};

/// Descriptor for `ExperimentEvent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List experimentEventDescriptor = $convert.base64Decode(
    'Cg9FeHBlcmltZW50RXZlbnQSFQoGcnVuX2lkGAEgASgJUgVydW5JZBIaCghzZXF1ZW5jZRgCIA'
    'EoBFIIc2VxdWVuY2USEgoEa2luZBgDIAEoCVIEa2luZBIgCgtkZXNjcmlwdGlvbhgEIAEoCVIL'
    'ZGVzY3JpcHRpb24SQAoHbWV0cmljcxgFIAEoCzImLmxpdmVrYWxtYW4uY29udHJvbC52MS5SZW'
    'NlaXZlck1ldHJpY3NSB21ldHJpY3MSQQoIZGVjaXNpb24YBiABKAsyJS5saXZla2FsbWFuLmNv'
    'bnRyb2wudjEuUG9saWN5RGVjaXNpb25SCGRlY2lzaW9uEisKEmVtaXR0ZWRfYXRfdW5peF9tcx'
    'gHIAEoBFIPZW1pdHRlZEF0VW5peE1z');

@$core.Deprecated('Use experimentStateRequestDescriptor instead')
const ExperimentStateRequest$json = {
  '1': 'ExperimentStateRequest',
  '2': [
    {'1': 'run_id', '3': 1, '4': 1, '5': 9, '10': 'runId'},
  ],
};

/// Descriptor for `ExperimentStateRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List experimentStateRequestDescriptor =
    $convert.base64Decode(
        'ChZFeHBlcmltZW50U3RhdGVSZXF1ZXN0EhUKBnJ1bl9pZBgBIAEoCVIFcnVuSWQ=');

@$core.Deprecated('Use experimentStateDescriptor instead')
const ExperimentState$json = {
  '1': 'ExperimentState',
  '2': [
    {'1': 'run_id', '3': 1, '4': 1, '5': 9, '10': 'runId'},
    {'1': 'active', '3': 2, '4': 1, '5': 8, '10': 'active'},
    {
      '1': 'latest',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.livekalman.control.v1.ReceiverMetrics',
      '10': 'latest'
    },
    {
      '1': 'desired_config_version',
      '3': 4,
      '4': 1,
      '5': 4,
      '10': 'desiredConfigVersion'
    },
  ],
};

/// Descriptor for `ExperimentState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List experimentStateDescriptor = $convert.base64Decode(
    'Cg9FeHBlcmltZW50U3RhdGUSFQoGcnVuX2lkGAEgASgJUgVydW5JZBIWCgZhY3RpdmUYAiABKA'
    'hSBmFjdGl2ZRI+CgZsYXRlc3QYAyABKAsyJi5saXZla2FsbWFuLmNvbnRyb2wudjEuUmVjZWl2'
    'ZXJNZXRyaWNzUgZsYXRlc3QSNAoWZGVzaXJlZF9jb25maWdfdmVyc2lvbhgEIAEoBFIUZGVzaX'
    'JlZENvbmZpZ1ZlcnNpb24=');
