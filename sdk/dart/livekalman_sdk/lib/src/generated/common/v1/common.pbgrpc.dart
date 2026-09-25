// This is a generated file - do not edit.
//
// Generated from common/v1/common.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'package:protobuf/protobuf.dart' as $pb;

import 'common.pb.dart' as $0;

export 'common.pb.dart';

/// NodeService is implemented by TX, RX and Controller. Clients can discover
/// role/capabilities and monitor health without knowing the role-specific API.
@$pb.GrpcServiceName('livekalman.common.v1.NodeService')
class NodeServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  NodeServiceClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.NodeInfo> getNodeInfo(
    $0.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getNodeInfo, request, options: options);
  }

  $grpc.ResponseFuture<$0.NodeStatus> getNodeStatus(
    $0.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getNodeStatus, request, options: options);
  }

  $grpc.ResponseStream<$0.NodeStatus> watchNodeStatus(
    $0.WatchNodeRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$watchNodeStatus, $async.Stream.fromIterable([request]),
        options: options);
  }

  // method descriptors

  static final _$getNodeInfo = $grpc.ClientMethod<$0.Empty, $0.NodeInfo>(
      '/livekalman.common.v1.NodeService/GetNodeInfo',
      ($0.Empty value) => value.writeToBuffer(),
      $0.NodeInfo.fromBuffer);
  static final _$getNodeStatus = $grpc.ClientMethod<$0.Empty, $0.NodeStatus>(
      '/livekalman.common.v1.NodeService/GetNodeStatus',
      ($0.Empty value) => value.writeToBuffer(),
      $0.NodeStatus.fromBuffer);
  static final _$watchNodeStatus =
      $grpc.ClientMethod<$0.WatchNodeRequest, $0.NodeStatus>(
          '/livekalman.common.v1.NodeService/WatchNodeStatus',
          ($0.WatchNodeRequest value) => value.writeToBuffer(),
          $0.NodeStatus.fromBuffer);
}

@$pb.GrpcServiceName('livekalman.common.v1.NodeService')
abstract class NodeServiceBase extends $grpc.Service {
  $core.String get $name => 'livekalman.common.v1.NodeService';

  NodeServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.Empty, $0.NodeInfo>(
        'GetNodeInfo',
        getNodeInfo_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($0.NodeInfo value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Empty, $0.NodeStatus>(
        'GetNodeStatus',
        getNodeStatus_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($0.NodeStatus value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.WatchNodeRequest, $0.NodeStatus>(
        'WatchNodeStatus',
        watchNodeStatus_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $0.WatchNodeRequest.fromBuffer(value),
        ($0.NodeStatus value) => value.writeToBuffer()));
  }

  $async.Future<$0.NodeInfo> getNodeInfo_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Empty> $request) async {
    return getNodeInfo($call, await $request);
  }

  $async.Future<$0.NodeInfo> getNodeInfo(
      $grpc.ServiceCall call, $0.Empty request);

  $async.Future<$0.NodeStatus> getNodeStatus_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Empty> $request) async {
    return getNodeStatus($call, await $request);
  }

  $async.Future<$0.NodeStatus> getNodeStatus(
      $grpc.ServiceCall call, $0.Empty request);

  $async.Stream<$0.NodeStatus> watchNodeStatus_Pre($grpc.ServiceCall $call,
      $async.Future<$0.WatchNodeRequest> $request) async* {
    yield* watchNodeStatus($call, await $request);
  }

  $async.Stream<$0.NodeStatus> watchNodeStatus(
      $grpc.ServiceCall call, $0.WatchNodeRequest request);
}
