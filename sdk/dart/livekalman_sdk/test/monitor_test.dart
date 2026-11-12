import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'package:grpc/grpc.dart';
import 'package:livekalman_sdk/livekalman_sdk.dart';
import 'package:test/test.dart';

NodeProbe ok(NodeRole role, int sequence, {bool peer = true}) => NodeProbe(
  info: NodeInfo(nodeId: 'n1', role: role),
  status: NodeStatus(
    role: role,
    health: HealthState.HEALTH_STATE_READY,
    lastSequence: Int64(sequence),
    peerConnected: peer,
  ),
  latency: const Duration(milliseconds: 4),
);

NodeProbe failed(int code) => NodeProbe(
  error: GrpcError.custom(code, 'test'),
  latency: const Duration(milliseconds: 2000),
);

void main() {
  group('health state machine', () {
    final t0 = DateTime.utc(2026, 11, 12, 10);
    const role = NodeRole.NODE_ROLE_RECEIVER;

    test('unreachable before first success is Service Unavailable', () {
      final h = evaluateProbe(
        const NodeHealth(role: role),
        failed(StatusCode.unavailable),
        t0,
      );
      expect(h.link, LinkStatus.serviceUnavailable);
      expect(h.failures, 1);
    });

    test('connected -> data flow -> lost -> reconnecting -> reconnected', () {
      var h = evaluateProbe(const NodeHealth(role: role), ok(role, 10), t0);
      expect(h.link, LinkStatus.connected);
      expect(h.dataFlow, DataFlowStatus.unknown);

      h = evaluateProbe(h, ok(role, 25), t0.add(const Duration(seconds: 1)));
      expect(h.dataFlow, DataFlowStatus.active);
      expect(h.latencyMs, 4);

      h = evaluateProbe(
        h,
        failed(StatusCode.deadlineExceeded),
        t0.add(const Duration(seconds: 2)),
      );
      expect(h.link, LinkStatus.connectionLost);
      expect(h.dataFlow, DataFlowStatus.inactive);
      expect(h.message, contains('Timeout'));

      h = evaluateProbe(
        h,
        failed(StatusCode.unavailable),
        t0.add(const Duration(seconds: 3)),
      );
      expect(h.link, LinkStatus.reconnecting);
      expect(h.failures, 2);

      h = evaluateProbe(h, ok(role, 40), t0.add(const Duration(seconds: 4)));
      expect(h.link, LinkStatus.connected);
      expect(h.dataFlow, DataFlowStatus.active);
      expect(h.failures, 0);
      expect(h.message, contains('reconnected'));
    });

    test('responding but sequence frozen becomes Data Flow Inactive', () {
      var h = evaluateProbe(const NodeHealth(role: role), ok(role, 10), t0);
      h = evaluateProbe(h, ok(role, 11), t0.add(const Duration(seconds: 1)));
      h = evaluateProbe(h, ok(role, 11), t0.add(const Duration(seconds: 2)));
      expect(
        h.dataFlow,
        DataFlowStatus.active,
        reason: 'still within staleAfter',
      );
      h = evaluateProbe(h, ok(role, 11), t0.add(const Duration(seconds: 6)));
      expect(h.link, LinkStatus.connected);
      expect(h.dataFlow, DataFlowStatus.inactive);
    });

    test('wrong role on the endpoint is rejected', () {
      final h = evaluateProbe(
        const NodeHealth(role: role),
        ok(NodeRole.NODE_ROLE_CONTROLLER, 5),
        t0,
      );
      expect(h.link, LinkStatus.serviceUnavailable);
      expect(h.message, contains('Unexpected response'));
    });

    test('missing service is Service Unavailable, not Connection Lost', () {
      var h = evaluateProbe(const NodeHealth(role: role), ok(role, 1), t0);
      h = evaluateProbe(h, failed(StatusCode.unimplemented), t0);
      expect(h.link, LinkStatus.serviceUnavailable);
    });

    test('transmitter -> receiver summary', () {
      const s = NodeRole.NODE_ROLE_TRANSMITTER;
      var tx = evaluateProbe(const NodeHealth(role: s), ok(s, 1), t0);
      tx = evaluateProbe(tx, ok(s, 5), t0.add(const Duration(seconds: 1)));
      var rx = evaluateProbe(const NodeHealth(role: role), ok(role, 1), t0);
      rx = evaluateProbe(rx, ok(role, 5), t0.add(const Duration(seconds: 1)));
      expect(
        transmitterToReceiver(tx, rx),
        'Frames flowing sender -> receiver',
      );
      final noPeer = evaluateProbe(
        tx,
        ok(s, 9, peer: false),
        t0.add(const Duration(seconds: 2)),
      );
      expect(transmitterToReceiver(noPeer, rx), contains('no open stream'));
    });

    test('reconnect delay grows and is capped', () {
      final r = math.Random(1);
      expect(reconnectDelay(0, r).inMilliseconds, inInclusiveRange(500, 750));
      expect(reconnectDelay(1, r).inMilliseconds, inInclusiveRange(1000, 1250));
      expect(
        reconnectDelay(10, r).inMilliseconds,
        inInclusiveRange(8000, 8250),
      );
    });
  });

  group('monitor JSON', () {
    Map<String, Object?> valid() => {
      'schema_version': '1',
      'generated_at': '2026-11-12T10:00:00Z',
      'device_id': 'controller-1',
      'policy': 'onnx',
      'recommend_only': false,
      'quality_model_version': 'quality-v1',
      'runs': [
        {
          'run_id': 'r',
          'connection_status': 'connected',
          'stream_status': 'data_flow_active',
          'sequence_number': 125,
          'timestamp': '2026-11-12T09:59:59.5Z',
          'age_ms': 40,
          'frames_lost': 0,
          'snr': 6.5,
          'ber': null,
          'noise_variance': 0.2,
          'phase_error': null,
          'latency_ms': 1.2,
          'psnr': null,
          'ssim': null,
          'applied': {'config_version': 3, 'rho': 0.0268},
          'recommended': {'rho': 0.03, 'sent_to_receiver': true},
          'ml': {
            'measured_class': 'moderate',
            'predicted_class': 'poor',
            'confidence': 0.6,
          },
          'ber_note': 'no reference bits',
        },
      ],
    };

    test('parses values and keeps nulls as null', () {
      final s = MonitorSnapshot.fromJson(valid());
      final r = s.runs.single;
      expect(r.sequenceNumber, 125);
      expect(r.snr, 6.5);
      expect(r.ber, isNull);
      expect(r.phaseError, isNull);
      expect(r.predictedClass, 'poor');
      expect(r.recommendationSent, isTrue);
      expect(r.notes['ber_note'], isNotEmpty);
    });

    test('rejects wrong schema, types and out-of-range values', () {
      expect(
        () => MonitorSnapshot.fromJson({...valid(), 'schema_version': '9'}),
        throwsFormatException,
      );
      final badType = valid();
      ((badType['runs'] as List).first as Map)['snr'] = 'high';
      expect(() => MonitorSnapshot.fromJson(badType), throwsFormatException);
      final badBer = valid();
      ((badBer['runs'] as List).first as Map)['ber'] = 1.5;
      expect(() => MonitorSnapshot.fromJson(badBer), throwsFormatException);
      final badStatus = valid();
      ((badStatus['runs'] as List).first as Map)['connection_status'] = 'up';
      expect(() => MonitorSnapshot.fromJson(badStatus), throwsFormatException);
      expect(() => MonitorSnapshot.fromJson('not json'), throwsFormatException);
    });
  });

  group('image quality', () {
    RgbImage testImage(int w, int h) {
      final rgb = Uint8List(w * h * 3);
      for (var i = 0; i < rgb.length; i++) {
        rgb[i] = (i * 37 + (i ~/ 3) * 11) % 200;
      }
      return RgbImage(w, h, rgb);
    }

    test('SSIM matches the NumPy reference (ml/quality_reference.py)', () {
      final a = testImage(20, 16);
      final rgb = Uint8List(a.rgb.length);
      for (var i = 0; i < rgb.length; i++) {
        rgb[i] = (a.rgb[i] + (i * 7) % 23) % 256;
      }
      final m = compareImages(a, RgbImage(20, 16, rgb));
      expect(m.ssim, closeTo(0.9896971288, 1e-6));
      expect(m.mse, closeTo(165.1958333333, 1e-6));
      expect(m.psnr, closeTo(25.9508127178, 1e-6));
    });

    test('identical images', () {
      final a = testImage(16, 16);
      final m = compareImages(a, a);
      expect(m.mse, 0);
      expect(m.psnr, double.infinity);
      expect(m.ssim, closeTo(1, 1e-12));
    });

    test('BMP with corrupted header and truncated reconstruction', () {
      final file = File('../../../examples/media/kalman.bmp');
      if (!file.existsSync()) {
        markTestSkipped('example image not available');
        return;
      }
      final orig = file.readAsBytesSync();
      final recon = Uint8List.fromList(orig);
      recon[0] = 0x58;
      recon[18] = 0xFF;
      recon[recon.length - 1] ^= 0x10;
      final m = compareBmp(orig, recon);
      expect(m.width, 64);
      expect(m.height, 48);
      expect(m.mse, greaterThan(0));
      expect(m.psnr, greaterThan(40));
      expect(
        () => compareBmp(orig, Uint8List.sublistView(recon, 0, 100)),
        throwsFormatException,
      );
    });
  });
}
