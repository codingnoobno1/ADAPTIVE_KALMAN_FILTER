import 'package:grpc/grpc.dart';

import '../generated/common/v1/common.pb.dart' as common;
import '../generated/common/v1/common.pbgrpc.dart' as common_grpc;
import '../generated/control/v1/controller.pb.dart' as control;
import '../generated/control/v1/controller.pbgrpc.dart' as control_grpc;
import '../generated/rx/v1/receiver.pbgrpc.dart' as rx_grpc;
import '../generated/tx/v1/transmitter.pbgrpc.dart' as tx_grpc;

final class LabEndpoints {
  const LabEndpoints({
    required this.transmitterHost,
    required this.receiverHost,
    required this.controllerHost,
    this.transmitterPort = 50051,
    this.receiverPort = 50052,
    this.controllerPort = 50053,
  });

  final String transmitterHost;
  final String receiverHost;
  final String controllerHost;
  final int transmitterPort;
  final int receiverPort;
  final int controllerPort;
}

/// Owns channels and typed clients for all three independently deployed nodes.
/// Use one instance per application and close it during application shutdown.
final class LiveKalmanClient {
  LiveKalmanClient._(this._txChannel, this._rxChannel, this._controllerChannel)
    : transmitter = tx_grpc.TransmitterServiceClient(_txChannel),
      receiver = rx_grpc.ReceiverServiceClient(_rxChannel),
      controller = control_grpc.ControllerServiceClient(_controllerChannel),
      transmitterNode = common_grpc.NodeServiceClient(_txChannel),
      receiverNode = common_grpc.NodeServiceClient(_rxChannel),
      controllerNode = common_grpc.NodeServiceClient(_controllerChannel);

  factory LiveKalmanClient.insecure(LabEndpoints endpoints) {
    ClientChannel channel(String host, int port) => ClientChannel(
      host,
      port: port,
      options: const ChannelOptions(credentials: ChannelCredentials.insecure()),
    );
    return LiveKalmanClient._(
      channel(endpoints.transmitterHost, endpoints.transmitterPort),
      channel(endpoints.receiverHost, endpoints.receiverPort),
      channel(endpoints.controllerHost, endpoints.controllerPort),
    );
  }

  final ClientChannel _txChannel;
  final ClientChannel _rxChannel;
  final ClientChannel _controllerChannel;
  final tx_grpc.TransmitterServiceClient transmitter;
  final rx_grpc.ReceiverServiceClient receiver;
  final control_grpc.ControllerServiceClient controller;
  final common_grpc.NodeServiceClient transmitterNode;
  final common_grpc.NodeServiceClient receiverNode;
  final common_grpc.NodeServiceClient controllerNode;

  Future<List<common.NodeInfo>> discoverNodes() => Future.wait([
    transmitterNode.getNodeInfo(common.Empty()),
    receiverNode.getNodeInfo(common.Empty()),
    controllerNode.getNodeInfo(common.Empty()),
  ]);

  Future<List<common.NodeStatus>> nodeStatuses() => Future.wait([
    transmitterNode.getNodeStatus(common.Empty()),
    receiverNode.getNodeStatus(common.Empty()),
    controllerNode.getNodeStatus(common.Empty()),
  ]);

  Stream<control.ExperimentEvent> watchExperiment({String runId = ''}) =>
      controller.watchExperiment(control.WatchRequest(runId: runId));

  Future<void> close() async {
    await Future.wait([
      _txChannel.shutdown(),
      _rxChannel.shutdown(),
      _controllerChannel.shutdown(),
    ]);
  }
}
