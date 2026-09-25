// This is a generated file - do not edit.
//
// Generated from control/v1/controller.proto.

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

import 'controller.pb.dart' as $0;

export 'controller.pb.dart';

@$pb.GrpcServiceName('livekalman.control.v1.ControllerService')
class ControllerServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  ControllerServiceClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseStream<$0.PolicyDecision> adapt(
    $async.Stream<$0.ReceiverMetrics> request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(_$adapt, request, options: options);
  }

  $grpc.ResponseStream<$0.ExperimentEvent> watchExperiment(
    $0.WatchRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$watchExperiment, $async.Stream.fromIterable([request]),
        options: options);
  }

  $grpc.ResponseFuture<$0.ExperimentState> getExperimentState(
    $0.ExperimentStateRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getExperimentState, request, options: options);
  }

  // method descriptors

  static final _$adapt =
      $grpc.ClientMethod<$0.ReceiverMetrics, $0.PolicyDecision>(
          '/livekalman.control.v1.ControllerService/Adapt',
          ($0.ReceiverMetrics value) => value.writeToBuffer(),
          $0.PolicyDecision.fromBuffer);
  static final _$watchExperiment =
      $grpc.ClientMethod<$0.WatchRequest, $0.ExperimentEvent>(
          '/livekalman.control.v1.ControllerService/WatchExperiment',
          ($0.WatchRequest value) => value.writeToBuffer(),
          $0.ExperimentEvent.fromBuffer);
  static final _$getExperimentState =
      $grpc.ClientMethod<$0.ExperimentStateRequest, $0.ExperimentState>(
          '/livekalman.control.v1.ControllerService/GetExperimentState',
          ($0.ExperimentStateRequest value) => value.writeToBuffer(),
          $0.ExperimentState.fromBuffer);
}

@$pb.GrpcServiceName('livekalman.control.v1.ControllerService')
abstract class ControllerServiceBase extends $grpc.Service {
  $core.String get $name => 'livekalman.control.v1.ControllerService';

  ControllerServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.ReceiverMetrics, $0.PolicyDecision>(
        'Adapt',
        adapt,
        true,
        true,
        ($core.List<$core.int> value) => $0.ReceiverMetrics.fromBuffer(value),
        ($0.PolicyDecision value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.WatchRequest, $0.ExperimentEvent>(
        'WatchExperiment',
        watchExperiment_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $0.WatchRequest.fromBuffer(value),
        ($0.ExperimentEvent value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.ExperimentStateRequest, $0.ExperimentState>(
            'GetExperimentState',
            getExperimentState_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.ExperimentStateRequest.fromBuffer(value),
            ($0.ExperimentState value) => value.writeToBuffer()));
  }

  $async.Stream<$0.PolicyDecision> adapt(
      $grpc.ServiceCall call, $async.Stream<$0.ReceiverMetrics> request);

  $async.Stream<$0.ExperimentEvent> watchExperiment_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.WatchRequest> $request) async* {
    yield* watchExperiment($call, await $request);
  }

  $async.Stream<$0.ExperimentEvent> watchExperiment(
      $grpc.ServiceCall call, $0.WatchRequest request);

  $async.Future<$0.ExperimentState> getExperimentState_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ExperimentStateRequest> $request) async {
    return getExperimentState($call, await $request);
  }

  $async.Future<$0.ExperimentState> getExperimentState(
      $grpc.ServiceCall call, $0.ExperimentStateRequest request);
}
