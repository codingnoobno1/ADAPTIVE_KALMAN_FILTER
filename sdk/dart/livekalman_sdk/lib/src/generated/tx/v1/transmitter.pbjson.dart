// This is a generated file - do not edit.
//
// Generated from tx/v1/transmitter.proto.

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

@$core.Deprecated('Use txConfigDescriptor instead')
const TxConfig$json = {
  '1': 'TxConfig',
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
    {'1': 'symbol_rate', '3': 4, '4': 1, '5': 13, '10': 'symbolRate'},
    {'1': 'amplitude', '3': 5, '4': 1, '5': 2, '10': 'amplitude'},
    {'1': 'noise_stddev', '3': 6, '4': 1, '5': 2, '10': 'noiseStddev'},
  ],
};

/// Descriptor for `TxConfig`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List txConfigDescriptor = $convert.base64Decode(
    'CghUeENvbmZpZxIdCgpjb21tYW5kX2lkGAEgASgEUgljb21tYW5kSWQSGAoHdmVyc2lvbhgCIA'
    'EoBFIHdmVyc2lvbhItChJlZmZlY3RpdmVfc2VxdWVuY2UYAyABKARSEWVmZmVjdGl2ZVNlcXVl'
    'bmNlEh8KC3N5bWJvbF9yYXRlGAQgASgNUgpzeW1ib2xSYXRlEhwKCWFtcGxpdHVkZRgFIAEoAl'
    'IJYW1wbGl0dWRlEiEKDG5vaXNlX3N0ZGRldhgGIAEoAlILbm9pc2VTdGRkZXY=');

@$core.Deprecated('Use applyTxReplyDescriptor instead')
const ApplyTxReply$json = {
  '1': 'ApplyTxReply',
  '2': [
    {'1': 'accepted', '3': 1, '4': 1, '5': 8, '10': 'accepted'},
    {'1': 'reason', '3': 2, '4': 1, '5': 9, '10': 'reason'},
    {'1': 'applied_version', '3': 3, '4': 1, '5': 4, '10': 'appliedVersion'},
  ],
};

/// Descriptor for `ApplyTxReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List applyTxReplyDescriptor = $convert.base64Decode(
    'CgxBcHBseVR4UmVwbHkSGgoIYWNjZXB0ZWQYASABKAhSCGFjY2VwdGVkEhYKBnJlYXNvbhgCIA'
    'EoCVIGcmVhc29uEicKD2FwcGxpZWRfdmVyc2lvbhgDIAEoBFIOYXBwbGllZFZlcnNpb24=');

@$core.Deprecated('Use txStatusDescriptor instead')
const TxStatus$json = {
  '1': 'TxStatus',
  '2': [
    {'1': 'active_version', '3': 1, '4': 1, '5': 4, '10': 'activeVersion'},
    {'1': 'running', '3': 2, '4': 1, '5': 8, '10': 'running'},
    {'1': 'sequence', '3': 3, '4': 1, '5': 4, '10': 'sequence'},
    {'1': 'run_id', '3': 4, '4': 1, '5': 9, '10': 'runId'},
  ],
};

/// Descriptor for `TxStatus`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List txStatusDescriptor = $convert.base64Decode(
    'CghUeFN0YXR1cxIlCg5hY3RpdmVfdmVyc2lvbhgBIAEoBFINYWN0aXZlVmVyc2lvbhIYCgdydW'
    '5uaW5nGAIgASgIUgdydW5uaW5nEhoKCHNlcXVlbmNlGAMgASgEUghzZXF1ZW5jZRIVCgZydW5f'
    'aWQYBCABKAlSBXJ1bklk');

@$core.Deprecated('Use txEventDescriptor instead')
const TxEvent$json = {
  '1': 'TxEvent',
  '2': [
    {'1': 'sequence', '3': 1, '4': 1, '5': 4, '10': 'sequence'},
    {'1': 'description', '3': 2, '4': 1, '5': 9, '10': 'description'},
    {
      '1': 'trace',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.livekalman.tx.v1.TxFrameTrace',
      '10': 'trace'
    },
  ],
};

/// Descriptor for `TxEvent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List txEventDescriptor = $convert.base64Decode(
    'CgdUeEV2ZW50EhoKCHNlcXVlbmNlGAEgASgEUghzZXF1ZW5jZRIgCgtkZXNjcmlwdGlvbhgCIA'
    'EoCVILZGVzY3JpcHRpb24SNAoFdHJhY2UYAyABKAsyHi5saXZla2FsbWFuLnR4LnYxLlR4RnJh'
    'bWVUcmFjZVIFdHJhY2U=');

@$core.Deprecated('Use txFrameTraceDescriptor instead')
const TxFrameTrace$json = {
  '1': 'TxFrameTrace',
  '2': [
    {'1': 'sequence', '3': 1, '4': 1, '5': 4, '10': 'sequence'},
    {'1': 'transfer_id', '3': 2, '4': 1, '5': 9, '10': 'transferId'},
    {'1': 'file_name', '3': 3, '4': 1, '5': 9, '10': 'fileName'},
    {'1': 'media_offset', '3': 4, '4': 1, '5': 4, '10': 'mediaOffset'},
    {'1': 'total_bytes', '3': 5, '4': 1, '5': 4, '10': 'totalBytes'},
    {'1': 'original_bytes', '3': 6, '4': 1, '5': 12, '10': 'originalBytes'},
    {'1': 'encoded_bytes', '3': 7, '4': 1, '5': 12, '10': 'encodedBytes'},
    {'1': 'scrambled_bytes', '3': 8, '4': 1, '5': 12, '10': 'scrambledBytes'},
    {'1': 'payload_bits', '3': 9, '4': 1, '5': 9, '10': 'payloadBits'},
    {'1': 'clean_symbols', '3': 10, '4': 3, '5': 2, '10': 'cleanSymbols'},
    {'1': 'noisy_samples', '3': 11, '4': 3, '5': 2, '10': 'noisySamples'},
    {'1': 'noise_stddev', '3': 12, '4': 1, '5': 2, '10': 'noiseStddev'},
    {'1': 'grpc_sent', '3': 13, '4': 1, '5': 8, '10': 'grpcSent'},
    {
      '1': 'observed_at_unix_ms',
      '3': 14,
      '4': 1,
      '5': 4,
      '10': 'observedAtUnixMs'
    },
  ],
};

/// Descriptor for `TxFrameTrace`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List txFrameTraceDescriptor = $convert.base64Decode(
    'CgxUeEZyYW1lVHJhY2USGgoIc2VxdWVuY2UYASABKARSCHNlcXVlbmNlEh8KC3RyYW5zZmVyX2'
    'lkGAIgASgJUgp0cmFuc2ZlcklkEhsKCWZpbGVfbmFtZRgDIAEoCVIIZmlsZU5hbWUSIQoMbWVk'
    'aWFfb2Zmc2V0GAQgASgEUgttZWRpYU9mZnNldBIfCgt0b3RhbF9ieXRlcxgFIAEoBFIKdG90YW'
    'xCeXRlcxIlCg5vcmlnaW5hbF9ieXRlcxgGIAEoDFINb3JpZ2luYWxCeXRlcxIjCg1lbmNvZGVk'
    'X2J5dGVzGAcgASgMUgxlbmNvZGVkQnl0ZXMSJwoPc2NyYW1ibGVkX2J5dGVzGAggASgMUg5zY3'
    'JhbWJsZWRCeXRlcxIhCgxwYXlsb2FkX2JpdHMYCSABKAlSC3BheWxvYWRCaXRzEiMKDWNsZWFu'
    'X3N5bWJvbHMYCiADKAJSDGNsZWFuU3ltYm9scxIjCg1ub2lzeV9zYW1wbGVzGAsgAygCUgxub2'
    'lzeVNhbXBsZXMSIQoMbm9pc2Vfc3RkZGV2GAwgASgCUgtub2lzZVN0ZGRldhIbCglncnBjX3Nl'
    'bnQYDSABKAhSCGdycGNTZW50Ei0KE29ic2VydmVkX2F0X3VuaXhfbXMYDiABKARSEG9ic2Vydm'
    'VkQXRVbml4TXM=');
