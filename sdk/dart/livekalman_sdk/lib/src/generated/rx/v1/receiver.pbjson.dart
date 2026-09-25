// This is a generated file - do not edit.
//
// Generated from rx/v1/receiver.proto.

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

@$core.Deprecated('Use txFrameDescriptor instead')
const TxFrame$json = {
  '1': 'TxFrame',
  '2': [
    {'1': 'run_id', '3': 1, '4': 1, '5': 9, '10': 'runId'},
    {'1': 'stream_id', '3': 2, '4': 1, '5': 4, '10': 'streamId'},
    {'1': 'sequence', '3': 3, '4': 1, '5': 4, '10': 'sequence'},
    {
      '1': 'first_sample_index',
      '3': 4,
      '4': 1,
      '5': 4,
      '10': 'firstSampleIndex'
    },
    {'1': 'sample_rate_hz', '3': 5, '4': 1, '5': 13, '10': 'sampleRateHz'},
    {
      '1': 'samples_per_symbol',
      '3': 6,
      '4': 1,
      '5': 13,
      '10': 'samplesPerSymbol'
    },
    {
      '1': 'capture_timestamp_us',
      '3': 7,
      '4': 1,
      '5': 4,
      '10': 'captureTimestampUs'
    },
    {'1': 'config_version', '3': 8, '4': 1, '5': 4, '10': 'configVersion'},
    {'1': 'samples', '3': 9, '4': 3, '5': 2, '10': 'samples'},
    {'1': 'reference_bits', '3': 10, '4': 1, '5': 12, '10': 'referenceBits'},
    {
      '1': 'sample_format',
      '3': 11,
      '4': 1,
      '5': 14,
      '6': '.livekalman.common.v1.SampleFormat',
      '10': 'sampleFormat'
    },
    {'1': 'packed_samples', '3': 12, '4': 1, '5': 12, '10': 'packedSamples'},
  ],
};

/// Descriptor for `TxFrame`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List txFrameDescriptor = $convert.base64Decode(
    'CgdUeEZyYW1lEhUKBnJ1bl9pZBgBIAEoCVIFcnVuSWQSGwoJc3RyZWFtX2lkGAIgASgEUghzdH'
    'JlYW1JZBIaCghzZXF1ZW5jZRgDIAEoBFIIc2VxdWVuY2USLAoSZmlyc3Rfc2FtcGxlX2luZGV4'
    'GAQgASgEUhBmaXJzdFNhbXBsZUluZGV4EiQKDnNhbXBsZV9yYXRlX2h6GAUgASgNUgxzYW1wbG'
    'VSYXRlSHoSLAoSc2FtcGxlc19wZXJfc3ltYm9sGAYgASgNUhBzYW1wbGVzUGVyU3ltYm9sEjAK'
    'FGNhcHR1cmVfdGltZXN0YW1wX3VzGAcgASgEUhJjYXB0dXJlVGltZXN0YW1wVXMSJQoOY29uZm'
    'lnX3ZlcnNpb24YCCABKARSDWNvbmZpZ1ZlcnNpb24SGAoHc2FtcGxlcxgJIAMoAlIHc2FtcGxl'
    'cxIlCg5yZWZlcmVuY2VfYml0cxgKIAEoDFINcmVmZXJlbmNlQml0cxJHCg1zYW1wbGVfZm9ybW'
    'F0GAsgASgOMiIubGl2ZWthbG1hbi5jb21tb24udjEuU2FtcGxlRm9ybWF0UgxzYW1wbGVGb3Jt'
    'YXQSJQoOcGFja2VkX3NhbXBsZXMYDCABKAxSDXBhY2tlZFNhbXBsZXM=');

@$core.Deprecated('Use rxFeedbackDescriptor instead')
const RxFeedback$json = {
  '1': 'RxFeedback',
  '2': [
    {'1': 'sequence', '3': 1, '4': 1, '5': 4, '10': 'sequence'},
    {'1': 'snr_db', '3': 2, '4': 1, '5': 2, '10': 'snrDb'},
    {'1': 'noise_variance', '3': 3, '4': 1, '5': 2, '10': 'noiseVariance'},
    {'1': 'compared_bits', '3': 4, '4': 1, '5': 4, '10': 'comparedBits'},
    {'1': 'bit_errors', '3': 5, '4': 1, '5': 4, '10': 'bitErrors'},
    {'1': 'ber', '3': 6, '4': 1, '5': 2, '10': 'ber'},
    {'1': 'latency_ms', '3': 7, '4': 1, '5': 1, '10': 'latencyMs'},
    {
      '1': 'active_config_version',
      '3': 8,
      '4': 1,
      '5': 4,
      '10': 'activeConfigVersion'
    },
    {'1': 'queue_depth', '3': 9, '4': 1, '5': 13, '10': 'queueDepth'},
  ],
};

/// Descriptor for `RxFeedback`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List rxFeedbackDescriptor = $convert.base64Decode(
    'CgpSeEZlZWRiYWNrEhoKCHNlcXVlbmNlGAEgASgEUghzZXF1ZW5jZRIVCgZzbnJfZGIYAiABKA'
    'JSBXNuckRiEiUKDm5vaXNlX3ZhcmlhbmNlGAMgASgCUg1ub2lzZVZhcmlhbmNlEiMKDWNvbXBh'
    'cmVkX2JpdHMYBCABKARSDGNvbXBhcmVkQml0cxIdCgpiaXRfZXJyb3JzGAUgASgEUgliaXRFcn'
    'JvcnMSEAoDYmVyGAYgASgCUgNiZXISHQoKbGF0ZW5jeV9tcxgHIAEoAVIJbGF0ZW5jeU1zEjIK'
    'FWFjdGl2ZV9jb25maWdfdmVyc2lvbhgIIAEoBFITYWN0aXZlQ29uZmlnVmVyc2lvbhIfCgtxdW'
    'V1ZV9kZXB0aBgJIAEoDVIKcXVldWVEZXB0aA==');

@$core.Deprecated('Use rxConfigDescriptor instead')
const RxConfig$json = {
  '1': 'RxConfig',
  '2': [
    {'1': 'command_id', '3': 1, '4': 1, '5': 4, '10': 'commandId'},
    {'1': 'version', '3': 2, '4': 1, '5': 4, '10': 'version'},
    {
      '1': 'effective_sequence',
      '3': 3,
      '4': 1,
      '5': 4,
      '10': 'effectiveSequence'
    },
    {'1': 'kalman_q', '3': 4, '4': 1, '5': 2, '10': 'kalmanQ'},
    {'1': 'kalman_r', '3': 5, '4': 1, '5': 2, '10': 'kalmanR'},
    {'1': 'reset_state', '3': 6, '4': 1, '5': 8, '10': 'resetState'},
  ],
};

/// Descriptor for `RxConfig`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List rxConfigDescriptor = $convert.base64Decode(
    'CghSeENvbmZpZxIdCgpjb21tYW5kX2lkGAEgASgEUgljb21tYW5kSWQSGAoHdmVyc2lvbhgCIA'
    'EoBFIHdmVyc2lvbhItChJlZmZlY3RpdmVfc2VxdWVuY2UYAyABKARSEWVmZmVjdGl2ZVNlcXVl'
    'bmNlEhkKCGthbG1hbl9xGAQgASgCUgdrYWxtYW5REhkKCGthbG1hbl9yGAUgASgCUgdrYWxtYW'
    '5SEh8KC3Jlc2V0X3N0YXRlGAYgASgIUgpyZXNldFN0YXRl');

@$core.Deprecated('Use applyRxReplyDescriptor instead')
const ApplyRxReply$json = {
  '1': 'ApplyRxReply',
  '2': [
    {'1': 'accepted', '3': 1, '4': 1, '5': 8, '10': 'accepted'},
    {'1': 'reason', '3': 2, '4': 1, '5': 9, '10': 'reason'},
    {'1': 'applied_version', '3': 3, '4': 1, '5': 4, '10': 'appliedVersion'},
  ],
};

/// Descriptor for `ApplyRxReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List applyRxReplyDescriptor = $convert.base64Decode(
    'CgxBcHBseVJ4UmVwbHkSGgoIYWNjZXB0ZWQYASABKAhSCGFjY2VwdGVkEhYKBnJlYXNvbhgCIA'
    'EoCVIGcmVhc29uEicKD2FwcGxpZWRfdmVyc2lvbhgDIAEoBFIOYXBwbGllZFZlcnNpb24=');

@$core.Deprecated('Use rxStatusDescriptor instead')
const RxStatus$json = {
  '1': 'RxStatus',
  '2': [
    {'1': 'active_version', '3': 1, '4': 1, '5': 4, '10': 'activeVersion'},
    {'1': 'stream_active', '3': 2, '4': 1, '5': 8, '10': 'streamActive'},
    {'1': 'last_sequence', '3': 3, '4': 1, '5': 4, '10': 'lastSequence'},
    {'1': 'sequence_gaps', '3': 4, '4': 1, '5': 4, '10': 'sequenceGaps'},
  ],
};

/// Descriptor for `RxStatus`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List rxStatusDescriptor = $convert.base64Decode(
    'CghSeFN0YXR1cxIlCg5hY3RpdmVfdmVyc2lvbhgBIAEoBFINYWN0aXZlVmVyc2lvbhIjCg1zdH'
    'JlYW1fYWN0aXZlGAIgASgIUgxzdHJlYW1BY3RpdmUSIwoNbGFzdF9zZXF1ZW5jZRgDIAEoBFIM'
    'bGFzdFNlcXVlbmNlEiMKDXNlcXVlbmNlX2dhcHMYBCABKARSDHNlcXVlbmNlR2Fwcw==');
