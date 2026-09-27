// This is a generated file - do not edit.
//
// Generated from common/v1/common.proto.

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

@$core.Deprecated('Use sampleFormatDescriptor instead')
const SampleFormat$json = {
  '1': 'SampleFormat',
  '2': [
    {'1': 'SAMPLE_FORMAT_UNSPECIFIED', '2': 0},
    {'1': 'SAMPLE_FORMAT_FLOAT32_LE', '2': 1},
    {'1': 'SAMPLE_FORMAT_INT16_LE', '2': 2},
  ],
};

/// Descriptor for `SampleFormat`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List sampleFormatDescriptor = $convert.base64Decode(
    'CgxTYW1wbGVGb3JtYXQSHQoZU0FNUExFX0ZPUk1BVF9VTlNQRUNJRklFRBAAEhwKGFNBTVBMRV'
    '9GT1JNQVRfRkxPQVQzMl9MRRABEhoKFlNBTVBMRV9GT1JNQVRfSU5UMTZfTEUQAg==');

@$core.Deprecated('Use nodeRoleDescriptor instead')
const NodeRole$json = {
  '1': 'NodeRole',
  '2': [
    {'1': 'NODE_ROLE_UNSPECIFIED', '2': 0},
    {'1': 'NODE_ROLE_TRANSMITTER', '2': 1},
    {'1': 'NODE_ROLE_RECEIVER', '2': 2},
    {'1': 'NODE_ROLE_CONTROLLER', '2': 3},
  ],
};

/// Descriptor for `NodeRole`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List nodeRoleDescriptor = $convert.base64Decode(
    'CghOb2RlUm9sZRIZChVOT0RFX1JPTEVfVU5TUEVDSUZJRUQQABIZChVOT0RFX1JPTEVfVFJBTl'
    'NNSVRURVIQARIWChJOT0RFX1JPTEVfUkVDRUlWRVIQAhIYChROT0RFX1JPTEVfQ09OVFJPTExF'
    'UhAD');

@$core.Deprecated('Use healthStateDescriptor instead')
const HealthState$json = {
  '1': 'HealthState',
  '2': [
    {'1': 'HEALTH_STATE_UNSPECIFIED', '2': 0},
    {'1': 'HEALTH_STATE_STARTING', '2': 1},
    {'1': 'HEALTH_STATE_READY', '2': 2},
    {'1': 'HEALTH_STATE_DEGRADED', '2': 3},
    {'1': 'HEALTH_STATE_STOPPING', '2': 4},
  ],
};

/// Descriptor for `HealthState`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List healthStateDescriptor = $convert.base64Decode(
    'CgtIZWFsdGhTdGF0ZRIcChhIRUFMVEhfU1RBVEVfVU5TUEVDSUZJRUQQABIZChVIRUFMVEhfU1'
    'RBVEVfU1RBUlRJTkcQARIWChJIRUFMVEhfU1RBVEVfUkVBRFkQAhIZChVIRUFMVEhfU1RBVEVf'
    'REVHUkFERUQQAxIZChVIRUFMVEhfU1RBVEVfU1RPUFBJTkcQBA==');

@$core.Deprecated('Use mediaTypeDescriptor instead')
const MediaType$json = {
  '1': 'MediaType',
  '2': [
    {'1': 'MEDIA_TYPE_UNSPECIFIED', '2': 0},
    {'1': 'MEDIA_TYPE_BINARY', '2': 1},
    {'1': 'MEDIA_TYPE_TEXT', '2': 2},
    {'1': 'MEDIA_TYPE_IMAGE', '2': 3},
    {'1': 'MEDIA_TYPE_AUDIO', '2': 4},
  ],
};

/// Descriptor for `MediaType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List mediaTypeDescriptor = $convert.base64Decode(
    'CglNZWRpYVR5cGUSGgoWTUVESUFfVFlQRV9VTlNQRUNJRklFRBAAEhUKEU1FRElBX1RZUEVfQk'
    'lOQVJZEAESEwoPTUVESUFfVFlQRV9URVhUEAISFAoQTUVESUFfVFlQRV9JTUFHRRADEhQKEE1F'
    'RElBX1RZUEVfQVVESU8QBA==');

@$core.Deprecated('Use modulationDescriptor instead')
const Modulation$json = {
  '1': 'Modulation',
  '2': [
    {'1': 'MODULATION_UNSPECIFIED', '2': 0},
    {'1': 'MODULATION_BPSK', '2': 1},
  ],
};

/// Descriptor for `Modulation`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List modulationDescriptor = $convert.base64Decode(
    'CgpNb2R1bGF0aW9uEhoKFk1PRFVMQVRJT05fVU5TUEVDSUZJRUQQABITCg9NT0RVTEFUSU9OX0'
    'JQU0sQAQ==');

@$core.Deprecated('Use payloadEncodingDescriptor instead')
const PayloadEncoding$json = {
  '1': 'PayloadEncoding',
  '2': [
    {'1': 'PAYLOAD_ENCODING_UNSPECIFIED', '2': 0},
    {'1': 'PAYLOAD_ENCODING_RAW', '2': 1},
    {'1': 'PAYLOAD_ENCODING_BYTE_SHIFT', '2': 2},
  ],
};

/// Descriptor for `PayloadEncoding`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List payloadEncodingDescriptor = $convert.base64Decode(
    'Cg9QYXlsb2FkRW5jb2RpbmcSIAocUEFZTE9BRF9FTkNPRElOR19VTlNQRUNJRklFRBAAEhgKFF'
    'BBWUxPQURfRU5DT0RJTkdfUkFXEAESHwobUEFZTE9BRF9FTkNPRElOR19CWVRFX1NISUZUEAI=');

@$core.Deprecated('Use emptyDescriptor instead')
const Empty$json = {
  '1': 'Empty',
};

/// Descriptor for `Empty`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List emptyDescriptor =
    $convert.base64Decode('CgVFbXB0eQ==');

@$core.Deprecated('Use capabilityDescriptor instead')
const Capability$json = {
  '1': 'Capability',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'version', '3': 2, '4': 1, '5': 9, '10': 'version'},
    {
      '1': 'attributes',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.livekalman.common.v1.Capability.AttributesEntry',
      '10': 'attributes'
    },
  ],
  '3': [Capability_AttributesEntry$json],
};

@$core.Deprecated('Use capabilityDescriptor instead')
const Capability_AttributesEntry$json = {
  '1': 'AttributesEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
  '7': {'7': true},
};

/// Descriptor for `Capability`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List capabilityDescriptor = $convert.base64Decode(
    'CgpDYXBhYmlsaXR5EhIKBG5hbWUYASABKAlSBG5hbWUSGAoHdmVyc2lvbhgCIAEoCVIHdmVyc2'
    'lvbhJQCgphdHRyaWJ1dGVzGAMgAygLMjAubGl2ZWthbG1hbi5jb21tb24udjEuQ2FwYWJpbGl0'
    'eS5BdHRyaWJ1dGVzRW50cnlSCmF0dHJpYnV0ZXMaPQoPQXR0cmlidXRlc0VudHJ5EhAKA2tleR'
    'gBIAEoCVIDa2V5EhQKBXZhbHVlGAIgASgJUgV2YWx1ZToCOAE=');

@$core.Deprecated('Use nodeInfoDescriptor instead')
const NodeInfo$json = {
  '1': 'NodeInfo',
  '2': [
    {'1': 'node_id', '3': 1, '4': 1, '5': 9, '10': 'nodeId'},
    {'1': 'display_name', '3': 2, '4': 1, '5': 9, '10': 'displayName'},
    {
      '1': 'role',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.livekalman.common.v1.NodeRole',
      '10': 'role'
    },
    {'1': 'api_version', '3': 4, '4': 1, '5': 9, '10': 'apiVersion'},
    {'1': 'listen_address', '3': 5, '4': 1, '5': 9, '10': 'listenAddress'},
    {
      '1': 'capabilities',
      '3': 6,
      '4': 3,
      '5': 11,
      '6': '.livekalman.common.v1.Capability',
      '10': 'capabilities'
    },
  ],
};

/// Descriptor for `NodeInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List nodeInfoDescriptor = $convert.base64Decode(
    'CghOb2RlSW5mbxIXCgdub2RlX2lkGAEgASgJUgZub2RlSWQSIQoMZGlzcGxheV9uYW1lGAIgAS'
    'gJUgtkaXNwbGF5TmFtZRIyCgRyb2xlGAMgASgOMh4ubGl2ZWthbG1hbi5jb21tb24udjEuTm9k'
    'ZVJvbGVSBHJvbGUSHwoLYXBpX3ZlcnNpb24YBCABKAlSCmFwaVZlcnNpb24SJQoObGlzdGVuX2'
    'FkZHJlc3MYBSABKAlSDWxpc3RlbkFkZHJlc3MSRAoMY2FwYWJpbGl0aWVzGAYgAygLMiAubGl2'
    'ZWthbG1hbi5jb21tb24udjEuQ2FwYWJpbGl0eVIMY2FwYWJpbGl0aWVz');

@$core.Deprecated('Use nodeStatusDescriptor instead')
const NodeStatus$json = {
  '1': 'NodeStatus',
  '2': [
    {'1': 'node_id', '3': 1, '4': 1, '5': 9, '10': 'nodeId'},
    {
      '1': 'role',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.livekalman.common.v1.NodeRole',
      '10': 'role'
    },
    {
      '1': 'health',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.livekalman.common.v1.HealthState',
      '10': 'health'
    },
    {'1': 'active', '3': 4, '4': 1, '5': 8, '10': 'active'},
    {'1': 'peer_connected', '3': 5, '4': 1, '5': 8, '10': 'peerConnected'},
    {'1': 'active_run_id', '3': 6, '4': 1, '5': 9, '10': 'activeRunId'},
    {
      '1': 'active_config_version',
      '3': 7,
      '4': 1,
      '5': 4,
      '10': 'activeConfigVersion'
    },
    {'1': 'last_sequence', '3': 8, '4': 1, '5': 4, '10': 'lastSequence'},
    {'1': 'uptime_ms', '3': 9, '4': 1, '5': 4, '10': 'uptimeMs'},
    {'1': 'message', '3': 10, '4': 1, '5': 9, '10': 'message'},
    {
      '1': 'observed_at_unix_ms',
      '3': 11,
      '4': 1,
      '5': 4,
      '10': 'observedAtUnixMs'
    },
  ],
};

/// Descriptor for `NodeStatus`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List nodeStatusDescriptor = $convert.base64Decode(
    'CgpOb2RlU3RhdHVzEhcKB25vZGVfaWQYASABKAlSBm5vZGVJZBIyCgRyb2xlGAIgASgOMh4ubG'
    'l2ZWthbG1hbi5jb21tb24udjEuTm9kZVJvbGVSBHJvbGUSOQoGaGVhbHRoGAMgASgOMiEubGl2'
    'ZWthbG1hbi5jb21tb24udjEuSGVhbHRoU3RhdGVSBmhlYWx0aBIWCgZhY3RpdmUYBCABKAhSBm'
    'FjdGl2ZRIlCg5wZWVyX2Nvbm5lY3RlZBgFIAEoCFINcGVlckNvbm5lY3RlZBIiCg1hY3RpdmVf'
    'cnVuX2lkGAYgASgJUgthY3RpdmVSdW5JZBIyChVhY3RpdmVfY29uZmlnX3ZlcnNpb24YByABKA'
    'RSE2FjdGl2ZUNvbmZpZ1ZlcnNpb24SIwoNbGFzdF9zZXF1ZW5jZRgIIAEoBFIMbGFzdFNlcXVl'
    'bmNlEhsKCXVwdGltZV9tcxgJIAEoBFIIdXB0aW1lTXMSGAoHbWVzc2FnZRgKIAEoCVIHbWVzc2'
    'FnZRItChNvYnNlcnZlZF9hdF91bml4X21zGAsgASgEUhBvYnNlcnZlZEF0VW5peE1z');

@$core.Deprecated('Use watchNodeRequestDescriptor instead')
const WatchNodeRequest$json = {
  '1': 'WatchNodeRequest',
  '2': [
    {'1': 'interval_ms', '3': 1, '4': 1, '5': 13, '10': 'intervalMs'},
  ],
};

/// Descriptor for `WatchNodeRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List watchNodeRequestDescriptor = $convert.base64Decode(
    'ChBXYXRjaE5vZGVSZXF1ZXN0Eh8KC2ludGVydmFsX21zGAEgASgNUgppbnRlcnZhbE1z');

@$core.Deprecated('Use mediaDescriptorDescriptor instead')
const MediaDescriptor$json = {
  '1': 'MediaDescriptor',
  '2': [
    {'1': 'transfer_id', '3': 1, '4': 1, '5': 9, '10': 'transferId'},
    {'1': 'file_name', '3': 2, '4': 1, '5': 9, '10': 'fileName'},
    {
      '1': 'media_type_hint',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.livekalman.common.v1.MediaType',
      '10': 'mediaTypeHint'
    },
    {'1': 'content_type_hint', '3': 4, '4': 1, '5': 9, '10': 'contentTypeHint'},
    {'1': 'total_size', '3': 5, '4': 1, '5': 4, '10': 'totalSize'},
    {'1': 'crc32', '3': 6, '4': 1, '5': 13, '10': 'crc32'},
    {
      '1': 'modulation',
      '3': 7,
      '4': 1,
      '5': 14,
      '6': '.livekalman.common.v1.Modulation',
      '10': 'modulation'
    },
    {
      '1': 'encoding',
      '3': 8,
      '4': 1,
      '5': 14,
      '6': '.livekalman.common.v1.PayloadEncoding',
      '10': 'encoding'
    },
    {'1': 'shift_key', '3': 9, '4': 1, '5': 13, '10': 'shiftKey'},
  ],
};

/// Descriptor for `MediaDescriptor`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List mediaDescriptorDescriptor = $convert.base64Decode(
    'Cg9NZWRpYURlc2NyaXB0b3ISHwoLdHJhbnNmZXJfaWQYASABKAlSCnRyYW5zZmVySWQSGwoJZm'
    'lsZV9uYW1lGAIgASgJUghmaWxlTmFtZRJHCg9tZWRpYV90eXBlX2hpbnQYAyABKA4yHy5saXZl'
    'a2FsbWFuLmNvbW1vbi52MS5NZWRpYVR5cGVSDW1lZGlhVHlwZUhpbnQSKgoRY29udGVudF90eX'
    'BlX2hpbnQYBCABKAlSD2NvbnRlbnRUeXBlSGludBIdCgp0b3RhbF9zaXplGAUgASgEUgl0b3Rh'
    'bFNpemUSFAoFY3JjMzIYBiABKA1SBWNyYzMyEkAKCm1vZHVsYXRpb24YByABKA4yIC5saXZla2'
    'FsbWFuLmNvbW1vbi52MS5Nb2R1bGF0aW9uUgptb2R1bGF0aW9uEkEKCGVuY29kaW5nGAggASgO'
    'MiUubGl2ZWthbG1hbi5jb21tb24udjEuUGF5bG9hZEVuY29kaW5nUghlbmNvZGluZxIbCglzaG'
    'lmdF9rZXkYCSABKA1SCHNoaWZ0S2V5');

@$core.Deprecated('Use mediaEventDescriptor instead')
const MediaEvent$json = {
  '1': 'MediaEvent',
  '2': [
    {
      '1': 'media',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.livekalman.common.v1.MediaDescriptor',
      '10': 'media'
    },
    {
      '1': 'detected_type',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.livekalman.common.v1.MediaType',
      '10': 'detectedType'
    },
    {
      '1': 'detected_content_type',
      '3': 3,
      '4': 1,
      '5': 9,
      '10': 'detectedContentType'
    },
    {'1': 'offset', '3': 4, '4': 1, '5': 4, '10': 'offset'},
    {'1': 'data', '3': 5, '4': 1, '5': 12, '10': 'data'},
    {'1': 'end_of_stream', '3': 6, '4': 1, '5': 8, '10': 'endOfStream'},
    {'1': 'received_size', '3': 7, '4': 1, '5': 4, '10': 'receivedSize'},
    {'1': 'checksum_valid', '3': 8, '4': 1, '5': 8, '10': 'checksumValid'},
    {'1': 'message', '3': 9, '4': 1, '5': 9, '10': 'message'},
    {
      '1': 'observed_at_unix_ms',
      '3': 10,
      '4': 1,
      '5': 4,
      '10': 'observedAtUnixMs'
    },
  ],
};

/// Descriptor for `MediaEvent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List mediaEventDescriptor = $convert.base64Decode(
    'CgpNZWRpYUV2ZW50EjsKBW1lZGlhGAEgASgLMiUubGl2ZWthbG1hbi5jb21tb24udjEuTWVkaW'
    'FEZXNjcmlwdG9yUgVtZWRpYRJECg1kZXRlY3RlZF90eXBlGAIgASgOMh8ubGl2ZWthbG1hbi5j'
    'b21tb24udjEuTWVkaWFUeXBlUgxkZXRlY3RlZFR5cGUSMgoVZGV0ZWN0ZWRfY29udGVudF90eX'
    'BlGAMgASgJUhNkZXRlY3RlZENvbnRlbnRUeXBlEhYKBm9mZnNldBgEIAEoBFIGb2Zmc2V0EhIK'
    'BGRhdGEYBSABKAxSBGRhdGESIgoNZW5kX29mX3N0cmVhbRgGIAEoCFILZW5kT2ZTdHJlYW0SIw'
    'oNcmVjZWl2ZWRfc2l6ZRgHIAEoBFIMcmVjZWl2ZWRTaXplEiUKDmNoZWNrc3VtX3ZhbGlkGAgg'
    'ASgIUg1jaGVja3N1bVZhbGlkEhgKB21lc3NhZ2UYCSABKAlSB21lc3NhZ2USLQoTb2JzZXJ2ZW'
    'RfYXRfdW5peF9tcxgKIAEoBFIQb2JzZXJ2ZWRBdFVuaXhNcw==');

@$core.Deprecated('Use watchMediaRequestDescriptor instead')
const WatchMediaRequest$json = {
  '1': 'WatchMediaRequest',
  '2': [
    {
      '1': 'types',
      '3': 1,
      '4': 3,
      '5': 14,
      '6': '.livekalman.common.v1.MediaType',
      '10': 'types'
    },
  ],
};

/// Descriptor for `WatchMediaRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List watchMediaRequestDescriptor = $convert.base64Decode(
    'ChFXYXRjaE1lZGlhUmVxdWVzdBI1CgV0eXBlcxgBIAMoDjIfLmxpdmVrYWxtYW4uY29tbW9uLn'
    'YxLk1lZGlhVHlwZVIFdHlwZXM=');
