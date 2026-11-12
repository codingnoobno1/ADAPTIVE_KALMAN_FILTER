import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kalman_mobile/dsp/kalman_engine.dart';
import 'package:kalman_mobile/models/kalman_parameters.dart';
import 'package:kalman_mobile/services/live_telemetry_controller.dart';

void main() {
  group('ScalarKalmanFilter & Algebraic Riccati Parity', () {
    test('converges to exact algebraic Riccati steady-state K_inf and P_inf', () {
      const q = 0.02;
      const r = 0.50;
      const rho = q / r;
      final filter = ScalarKalmanFilter(q: q, r: r);

      for (var i = 0; i < 200; i++) {
        filter.update(0.42);
      }

      final expectedKInf = steadyStateKalmanGain(rho);
      final expectedPInf = steadyStatePosteriorCovariance(q, r);

      expect(filter.gainK, closeTo(expectedKInf, 1e-9));
      expect(filter.p, closeTo(expectedPInf, 1e-9));
      expect(filter.x, closeTo(0.42, 1e-6));
      // Identity P_inf = K_inf * R
      expect(expectedPInf, closeTo(expectedKInf * r, 1e-12));
    });

    test('computes innovation y_k, covariance S_k, and NIS accurately', () {
      final filter = ScalarKalmanFilter(q: 0.1, r: 0.4);
      filter.primeZeroState();
      final step = filter.update(0.5);

      // Prior P^- = 1.0 + 0.1 = 1.1; S = 1.1 + 0.4 = 1.5; K = 1.1 / 1.5
      expect(step.pPrior, closeTo(1.1, 1e-9));
      expect(step.innovationCovS, closeTo(1.5, 1e-9));
      expect(step.gainK, closeTo(1.1 / 1.5, 1e-9));
      expect(step.innovationY, closeTo(0.5, 1e-9));
      expect(step.nis, closeTo(0.25 / 1.5, 1e-9));
      expect(step.pPosterior, closeTo((1.0 - 1.1 / 1.5) * 1.1, 1e-9));
    });

    test('rejects non-positive or non-finite Q and R', () {
      final filter = ScalarKalmanFilter();
      expect(
        () => filter.configure(q: 0, r: 0.5),
        throwsArgumentError,
      );
      expect(
        () => filter.configure(q: 0.01, r: -1),
        throwsArgumentError,
      );
      expect(
        () => filter.configure(q: double.nan, r: 0.5),
        throwsArgumentError,
      );
    });
  });

  group('processBpskFrame DSP Parity', () {
    test('recovers constant DC offset and achieves zero BER on clean BPSK', () {
      // Stationary DC offset uses small tracking ratio rho = Q/R = 0.0004 so
      // 8-symbol Rademacher block variance (1/8 = 0.125 V^2) averages < 0.02 V.
      final filter = ScalarKalmanFilter(q: 0.0002, r: 0.5);
      const symbols = 64;
      const sps = 8;
      const dcOffset = 0.65;
      final refBits = Uint8List(8);
      final rng = math.Random(7);
      final samples = <double>[];

      late BpskFrameMetrics lastMetrics;
      for (var frame = 0; frame < 60; frame++) {
        samples.clear();
        for (var i = 0; i < refBits.length; i++) {
          refBits[i] = 0;
        }
        for (var s = 0; s < symbols; s++) {
          final bit = rng.nextBool();
          if (bit) {
            refBits[s ~/ 8] |= 1 << (s % 8);
          }
          final v = (bit ? 1.0 : -1.0) + dcOffset;
          for (var j = 0; j < sps; j++) {
            samples.add(v);
          }
        }
        lastMetrics = processBpskFrame(
          filter: filter,
          samples: samples,
          samplesPerSymbol: sps,
          referenceBits: refBits,
        );
      }

      expect(lastMetrics.dcEstimate, closeTo(dcOffset, 0.05));
      expect(lastMetrics.ber, equals(0.0));
      expect(lastMetrics.comparedBits, equals(symbols));
      expect(lastMetrics.bitErrors, equals(0));
    });
  });

  group('OnDeviceKalmanWorkbench & Endpoint Parsing', () {
    test('produces 25 parameter descriptors across all 4 categories', () {
      final wb = OnDeviceKalmanWorkbench(seed: 99);
      final snap = wb.nextFrame();
      final descriptors = snap.toDescriptors();

      expect(descriptors.length, equals(25));
      for (final cat in ParameterCategory.values) {
        expect(
          descriptors.where((d) => d.category == cat),
          isNotEmpty,
        );
      }
      final json = snap.toJson();
      expect(json['sequence'], equals(1));
      expect(json['kalman'], isA<Map<String, Object?>>());
    });

    test('parses LAN grpc:// and Cloudflare Tunnel grpcs:// URIs', () {
      final lan = ParsedLabConnection.parse(
        'grpc://192.168.1.30:50053?txHost=192.168.1.10&rxHost=192.168.1.20&txPort=50051&rxPort=50052&controllerHttpPort=8080',
      );
      expect(lan.secure, isFalse);
      expect(lan.endpoints.controllerHost, '192.168.1.30');
      expect(lan.endpoints.transmitterHost, '192.168.1.10');
      expect(lan.endpoints.receiverHost, '192.168.1.20');
      expect(lan.controllerHttpUri.toString(), 'http://192.168.1.30:8080');

      final tls = ParsedLabConnection.parse(
        'grpcs://ctrl.example.com?txHost=tx.example.com&rxHost=rx.example.com',
      );
      expect(tls.secure, isTrue);
      expect(tls.endpoints.controllerPort, 443);
      expect(tls.endpoints.transmitterPort, 443);
    });
  });
}
