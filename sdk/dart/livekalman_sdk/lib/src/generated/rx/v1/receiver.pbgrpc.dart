// This is a generated file - do not edit.
//
// Generated from rx/v1/receiver.proto.

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
import 'receiver.pb.dart' as $0;

export 'receiver.pb.dart';

@$pb.GrpcServiceName('livekalman.rx.v1.ReceiverService')
class ReceiverServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  ReceiverServiceClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseStream<$0.RxFeedback> processSignal(
    $async.Stream<$0.TxFrame> request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(_$processSignal, request, options: options);
  }

  $grpc.ResponseFuture<$0.ApplyRxReply> applyReceiverConfig(
    $0.RxConfig request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$applyReceiverConfig, request, options: options);
  }

  $grpc.ResponseFuture<$0.RxStatus> getRxStatus(
    $1.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getRxStatus, request, options: options);
  }

  // method descriptors

  static final _$processSignal = $grpc.ClientMethod<$0.TxFrame, $0.RxFeedback>(
      '/livekalman.rx.v1.ReceiverService/ProcessSignal',
      ($0.TxFrame value) => value.writeToBuffer(),
      $0.RxFeedback.fromBuffer);
  static final _$applyReceiverConfig =
      $grpc.ClientMethod<$0.RxConfig, $0.ApplyRxReply>(
          '/livekalman.rx.v1.ReceiverService/ApplyReceiverConfig',
          ($0.RxConfig value) => value.writeToBuffer(),
          $0.ApplyRxReply.fromBuffer);
  static final _$getRxStatus = $grpc.ClientMethod<$1.Empty, $0.RxStatus>(
      '/livekalman.rx.v1.ReceiverService/GetRxStatus',
      ($1.Empty value) => value.writeToBuffer(),
      $0.RxStatus.fromBuffer);
}

@$pb.GrpcServiceName('livekalman.rx.v1.ReceiverService')
abstract class ReceiverServiceBase extends $grpc.Service {
  $core.String get $name => 'livekalman.rx.v1.ReceiverService';

  ReceiverServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.TxFrame, $0.RxFeedback>(
        'ProcessSignal',
        processSignal,
        true,
        true,
        ($core.List<$core.int> value) => $0.TxFrame.fromBuffer(value),
        ($0.RxFeedback value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.RxConfig, $0.ApplyRxReply>(
        'ApplyReceiverConfig',
        applyReceiverConfig_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.RxConfig.fromBuffer(value),
        ($0.ApplyRxReply value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.Empty, $0.RxStatus>(
        'GetRxStatus',
        getRxStatus_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.Empty.fromBuffer(value),
        ($0.RxStatus value) => value.writeToBuffer()));
  }

  $async.Stream<$0.RxFeedback> processSignal(
      $grpc.ServiceCall call, $async.Stream<$0.TxFrame> request);

  $async.Future<$0.ApplyRxReply> applyReceiverConfig_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.RxConfig> $request) async {
    return applyReceiverConfig($call, await $request);
  }

  $async.Future<$0.ApplyRxReply> applyReceiverConfig(
      $grpc.ServiceCall call, $0.RxConfig request);

  $async.Future<$0.RxStatus> getRxStatus_Pre(
      $grpc.ServiceCall $call, $async.Future<$1.Empty> $request) async {
    return getRxStatus($call, await $request);
  }

  $async.Future<$0.RxStatus> getRxStatus(
      $grpc.ServiceCall call, $1.Empty request);
}
