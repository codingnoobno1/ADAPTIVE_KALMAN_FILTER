// This is a generated file - do not edit.
//
// Generated from tx/v1/transmitter.proto.

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

import '../../common/v1/common.pb.dart' as $1;
import 'transmitter.pb.dart' as $0;

export 'transmitter.pb.dart';

@$pb.GrpcServiceName('livekalman.tx.v1.TransmitterService')
class TransmitterServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  TransmitterServiceClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.ApplyTxReply> applyTransmitterConfig(
    $0.TxConfig request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$applyTransmitterConfig, request,
        options: options);
  }

  $grpc.ResponseFuture<$0.TxStatus> getTxStatus(
    $1.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getTxStatus, request, options: options);
  }

  $grpc.ResponseStream<$0.TxEvent> watchTxEvents(
    $1.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$watchTxEvents, $async.Stream.fromIterable([request]),
        options: options);
  }

  // method descriptors

  static final _$applyTransmitterConfig =
      $grpc.ClientMethod<$0.TxConfig, $0.ApplyTxReply>(
          '/livekalman.tx.v1.TransmitterService/ApplyTransmitterConfig',
          ($0.TxConfig value) => value.writeToBuffer(),
          $0.ApplyTxReply.fromBuffer);
  static final _$getTxStatus = $grpc.ClientMethod<$1.Empty, $0.TxStatus>(
      '/livekalman.tx.v1.TransmitterService/GetTxStatus',
      ($1.Empty value) => value.writeToBuffer(),
      $0.TxStatus.fromBuffer);
  static final _$watchTxEvents = $grpc.ClientMethod<$1.Empty, $0.TxEvent>(
      '/livekalman.tx.v1.TransmitterService/WatchTxEvents',
      ($1.Empty value) => value.writeToBuffer(),
      $0.TxEvent.fromBuffer);
}

@$pb.GrpcServiceName('livekalman.tx.v1.TransmitterService')
abstract class TransmitterServiceBase extends $grpc.Service {
  $core.String get $name => 'livekalman.tx.v1.TransmitterService';

  TransmitterServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.TxConfig, $0.ApplyTxReply>(
        'ApplyTransmitterConfig',
        applyTransmitterConfig_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.TxConfig.fromBuffer(value),
        ($0.ApplyTxReply value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.Empty, $0.TxStatus>(
        'GetTxStatus',
        getTxStatus_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.Empty.fromBuffer(value),
        ($0.TxStatus value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.Empty, $0.TxEvent>(
        'WatchTxEvents',
        watchTxEvents_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $1.Empty.fromBuffer(value),
        ($0.TxEvent value) => value.writeToBuffer()));
  }

  $async.Future<$0.ApplyTxReply> applyTransmitterConfig_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.TxConfig> $request) async {
    return applyTransmitterConfig($call, await $request);
  }

  $async.Future<$0.ApplyTxReply> applyTransmitterConfig(
      $grpc.ServiceCall call, $0.TxConfig request);

  $async.Future<$0.TxStatus> getTxStatus_Pre(
      $grpc.ServiceCall $call, $async.Future<$1.Empty> $request) async {
    return getTxStatus($call, await $request);
  }

  $async.Future<$0.TxStatus> getTxStatus(
      $grpc.ServiceCall call, $1.Empty request);

  $async.Stream<$0.TxEvent> watchTxEvents_Pre(
      $grpc.ServiceCall $call, $async.Future<$1.Empty> $request) async* {
    yield* watchTxEvents($call, await $request);
  }

  $async.Stream<$0.TxEvent> watchTxEvents(
      $grpc.ServiceCall call, $1.Empty request);
}
