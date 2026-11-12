import 'dart:math' as math;

import 'package:grpc/grpc.dart';

import '../client/live_kalman_client.dart';
import '../generated/common/v1/common.pb.dart' as common;

/// Connection state of one node, derived from application-level probes
/// (real gRPC calls with deadlines), never from socket or tunnel reachability.
enum LinkStatus {
  checking('Connection Checking'),
  connected('Connected'),
  connectionLost('Connection Lost'),
  reconnecting('Reconnecting'),
  serviceUnavailable('Service Unavailable');

  const LinkStatus(this.label);
  final String label;
}

/// Whether frames are actually moving through a node, judged by its reported
/// sequence number advancing between probes.
enum DataFlowStatus {
  unknown('Data Flow Unknown'),
  active('Data Flow Active'),
  inactive('Data Flow Inactive');

  const DataFlowStatus(this.label);
  final String label;
}

/// Health of one node after the latest probe.
final class NodeHealth {
  const NodeHealth({
    required this.role,
    this.link = LinkStatus.checking,
    this.dataFlow = DataFlowStatus.unknown,
    this.latencyMs,
    this.lastSequence,
    this.lastProgressAt,
    this.lastSuccessAt,
    this.failures = 0,
    this.peerConnected,
    this.message = 'Waiting for the first probe',
    this.checkedAt,
  });

  final common.NodeRole role;
  final LinkStatus link;
  final DataFlowStatus dataFlow;
  final int? latencyMs;
  final int? lastSequence;
  final DateTime? lastProgressAt;
  final DateTime? lastSuccessAt;
  final int failures;
  final bool? peerConnected;
  final String message;
  final DateTime? checkedAt;

  bool get healthy =>
      link == LinkStatus.connected && dataFlow == DataFlowStatus.active;

  Map<String, Object?> toJson() => {
    'role': role.name,
    'connection_status': link.name,
    'stream_status': dataFlow.name,
    'latency_ms': latencyMs,
    'sequence_number': lastSequence,
    'last_progress_at': lastProgressAt?.toUtc().toIso8601String(),
    'peer_connected': peerConnected,
    'consecutive_failures': failures,
    'message': message,
    'checked_at': checkedAt?.toUtc().toIso8601String(),
  };
}

/// gRPC status codes that mean "the network path or process is down".
const _networkCodes = {
  StatusCode.unavailable,
  StatusCode.deadlineExceeded,
  StatusCode.cancelled,
  StatusCode.unknown,
};

/// Updates [previous] with one probe result. Pure: all time comes from [now].
NodeHealth evaluateProbe(
  NodeHealth previous,
  NodeProbe probe,
  DateTime now, {
  Duration staleAfter = const Duration(seconds: 3),
}) {
  final latency = probe.latency.inMilliseconds;
  if (!probe.succeeded) {
    final error = probe.error;
    final network = error is! GrpcError || _networkCodes.contains(error.code);
    final everConnected = previous.lastSuccessAt != null;
    final LinkStatus link;
    if (!network) {
      link = LinkStatus.serviceUnavailable;
    } else if (!everConnected) {
      link = LinkStatus.serviceUnavailable;
    } else if (previous.link == LinkStatus.connected ||
        previous.link == LinkStatus.checking) {
      link = LinkStatus.connectionLost;
    } else {
      link = LinkStatus.reconnecting;
    }
    return NodeHealth(
      role: previous.role,
      link: link,
      dataFlow: previous.dataFlow == DataFlowStatus.unknown
          ? DataFlowStatus.unknown
          : DataFlowStatus.inactive,
      latencyMs: null,
      lastSequence: previous.lastSequence,
      lastProgressAt: previous.lastProgressAt,
      lastSuccessAt: previous.lastSuccessAt,
      failures: previous.failures + 1,
      peerConnected: null,
      message: describeError(error),
      checkedAt: now,
    );
  }

  final info = probe.info!;
  final status = probe.status!;
  // Validate that the expected protobuf response came back from the expected
  // role; a tunnel or wrong port can answer with something else entirely.
  if (info.role != previous.role || status.role != previous.role) {
    return NodeHealth(
      role: previous.role,
      link: LinkStatus.serviceUnavailable,
      failures: previous.failures + 1,
      lastSuccessAt: previous.lastSuccessAt,
      message:
          'Unexpected response: expected ${previous.role.name}, got ${info.role.name}',
      checkedAt: now,
    );
  }
  if (info.nodeId.isEmpty) {
    return NodeHealth(
      role: previous.role,
      link: LinkStatus.serviceUnavailable,
      failures: previous.failures + 1,
      lastSuccessAt: previous.lastSuccessAt,
      message: 'Invalid response: empty node id',
      checkedAt: now,
    );
  }

  final sequence = status.lastSequence.toInt();
  final advanced =
      previous.lastSequence != null && sequence > previous.lastSequence!;
  final restarted =
      previous.lastSequence != null && sequence < previous.lastSequence!;
  var progressAt = previous.lastProgressAt;
  if (advanced || (restarted && sequence > 0)) progressAt = now;
  final DataFlowStatus flow;
  if (advanced) {
    flow = DataFlowStatus.active;
  } else if (progressAt != null && now.difference(progressAt) <= staleAfter) {
    flow = DataFlowStatus.active;
  } else if (previous.lastSequence == null && progressAt == null) {
    flow = DataFlowStatus.unknown; // first sample: no progress measurable yet
  } else {
    flow = DataFlowStatus.inactive;
  }

  final link = status.health == common.HealthState.HEALTH_STATE_STARTING
      ? LinkStatus.checking
      : LinkStatus.connected;
  final detail = <String>[
    if (status.message.isNotEmpty) status.message,
    if (status.health == common.HealthState.HEALTH_STATE_DEGRADED) 'degraded',
    if (previous.link == LinkStatus.reconnecting ||
        previous.link == LinkStatus.connectionLost)
      'reconnected',
  ];
  return NodeHealth(
    role: previous.role,
    link: link,
    dataFlow: flow,
    latencyMs: latency,
    lastSequence: sequence,
    lastProgressAt: progressAt,
    lastSuccessAt: now,
    failures: 0,
    peerConnected: status.peerConnected,
    message: detail.isEmpty ? 'Responding' : detail.join(' · '),
    checkedAt: now,
  );
}

/// End-to-end transmitter -> receiver state from the two node healths.
String transmitterToReceiver(NodeHealth sender, NodeHealth receiver) {
  if (sender.link != LinkStatus.connected ||
      receiver.link != LinkStatus.connected) {
    return 'Unknown: ${sender.link != LinkStatus.connected ? 'sender' : 'receiver'} not reachable';
  }
  if (sender.peerConnected != true) {
    return 'Sender has no open stream to the receiver';
  }
  if (sender.dataFlow == DataFlowStatus.active &&
      receiver.dataFlow == DataFlowStatus.active) {
    return 'Frames flowing sender -> receiver';
  }
  return 'Stream open but no frames advancing';
}

/// Exponential reconnect delay with jitter: 0.5 s, 1 s, 2 s ... capped at 8 s.
Duration reconnectDelay(int attempt, [math.Random? random]) {
  final base = 500 * math.pow(2, math.min(attempt, 4)).toInt();
  final jitter = (random ?? math.Random()).nextInt(250);
  return Duration(milliseconds: base + jitter);
}

/// A short operator-facing description of a gRPC or network error.
String describeError(Object? error) {
  if (error is GrpcError) {
    return switch (error.code) {
      StatusCode.unavailable => 'Unavailable: node not reachable',
      StatusCode.deadlineExceeded => 'Timeout: no response before deadline',
      StatusCode.unimplemented => 'Service missing on this endpoint',
      StatusCode.cancelled => 'Call cancelled',
      _ => 'gRPC ${error.codeName}: ${error.message ?? ''}'.trim(),
    };
  }
  return error?.toString() ?? 'Unknown error';
}
