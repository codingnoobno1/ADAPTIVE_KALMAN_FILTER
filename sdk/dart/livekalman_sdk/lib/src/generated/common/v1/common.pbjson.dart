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
