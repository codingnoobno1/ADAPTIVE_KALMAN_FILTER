import 'dart:io';
import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:livekalman_sdk/livekalman_sdk.dart' as lk;
import 'package:signal_monitor/live_lab.dart';
import 'package:signal_monitor/live_panels.dart';

// A LiveLab that is never started: tests inject the same messages the nodes
// would stream, so every rendered value is traceable to an input.
LiveLab idleLab() => LiveLab(
  lk.LiveKalmanClient.insecure(
    const lk.LabEndpoints(
      transmitterHost: '127.0.0.1',
      receiverHost: '127.0.0.1',
      controllerHost: '127.0.0.1',
      transmitterPort: 1,
      receiverPort: 1,
      controllerPort: 1,
    ),
  ),
);

Widget host(Widget child) => MaterialApp(
  home: Scaffold(
    body: SingleChildScrollView(child: SizedBox(width: 1300, child: child)),
  ),
);

lk.ChannelAssessment assessment(int first, String measured, String predicted) =>
    lk.ChannelAssessment(
      windowFirstSequence: Int64(first),
      windowLastSequence: Int64(first + 11),
      measuredClass: measured,
      predictedClass: predicted,
      confidence: .8,
      classProbabilities: [.1, .05, .8, .05],
      features: [5, 1, 0, .3, .01, .02, .01, 1, .05, .04],
      featureNames: [
        'snr_db_mean',
        'snr_db_std',
        'snr_db_trend',
        'noise_var_mean',
        'noise_var_std',
        'ber_mean',
        'ber_std',
        'ber_available',
        'frame_mean_std',
        'frame_mean_step',
      ],
      modelVersion: 'quality-test',
      horizonFrames: 12,
    );

void main() {
  testWidgets('signal probe says so when no frames exist (no invented data)', (
    tester,
  ) async {
    final lab = idleLab();
    await tester.pumpWidget(host(SignalProbePanel(lab: lab)));
    expect(find.byKey(const Key('probe-empty')), findsOneWidget);
  });

  testWidgets('signal probe pairs TX and RX traces by sequence', (
    tester,
  ) async {
    final lab = idleLab();
    lab.txFrames.add(
      Timed(
        lk.TxFrameTrace(
          sequence: Int64(7),
          cleanSymbols: [1, -1, 1],
          noisySamples: [.9, -1.1],
        ),
        DateTime.now(),
      ),
    );
    lab.rxFrames.add(
      Timed(
        lk.RxFrameTrace(
          sequence: Int64(7),
          noisySamples: [.8, -1.2, 1.1],
          dcEstimate: .1,
          demodulatedBits: '1011',
          comparedBits: Int64(64),
          bitErrors: Int64(1),
          ber: 1 / 64,
        ),
        DateTime.now(),
      ),
    );
    lab.latestMetrics = lk.ReceiverMetrics(
      snrDb: 6.5,
      noiseVariance: .21,
      comparedBits: Int64(64),
      ber: 1 / 64,
      latencyMs: 1.25,
      sequenceGaps: Int64(2),
    );
    await tester.pumpWidget(host(SignalProbePanel(lab: lab)));
    expect(find.textContaining('same frame (sequence 7)'), findsOneWidget);
    expect(find.text('6.50 dB'), findsOneWidget);
    expect(find.text('1.56e-2'), findsOneWidget);
    expect(find.text('64 / 1'), findsOneWidget);
    expect(find.text('not available'), findsOneWidget); // phase error
  });

  testWidgets(
    'ML panel separates measured, predicted, recommended and applied',
    (tester) async {
      final lab = idleLab();
      lab.latestMetrics = lk.ReceiverMetrics(
        activeKalmanQ: .0134,
        activeKalmanR: .5,
        activeConfigVersion: Int64(4),
      );
      lab.decisions.add(
        DecisionRecord(
          lk.PolicyDecision(
            policy: 'onnx',
            proposedKalmanQ: .02,
            proposedKalmanR: .5,
            proposedVersion: Int64(5),
            sentToReceiver: false,
          ),
          DateTime.now(),
        ),
      );
      final first = AssessmentRecord(
        assessment(1, 'good', 'poor'),
        DateTime.now(),
      )..actualNext = 'poor';
      final second = AssessmentRecord(
        assessment(13, 'poor', 'poor'),
        DateTime.now(),
      );
      lab.assessments.addAll([first, second]);
      await tester.pumpWidget(host(MlPanel(lab: lab)));
      expect(
        find.descendant(
          of: find.byKey(const Key('ml-measured')),
          matching: find.text('POOR'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('ml-predicted')),
          matching: find.text('POOR'),
        ),
        findsOneWidget,
      );
      expect(find.textContaining('NOT sent (recommend-only)'), findsOneWidget);
      expect(find.textContaining('config v4'), findsOneWidget);
      expect(find.textContaining('1/1 predictions matched'), findsOneWidget);
    },
  );

  testWidgets('image quality uses real BMP pairs only', (tester) async {
    final file = File('../../../examples/media/kalman.bmp');
    if (!file.existsSync()) return;
    final orig = file.readAsBytesSync();
    final recon = Uint8List.fromList(orig)..[orig.length - 1] ^= 0x20;
    final lab = idleLab();
    final x = ImageTransfer('t1', 'kalman.bmp');
    x.addOriginalChunk(0, orig, orig.length);
    x.addReconstructedChunk(0, recon.sublist(0, 4000), orig.length, false);
    x.addReconstructedChunk(4000, recon.sublist(4000), orig.length, true);
    lab.transfers['t1'] = x;
    final expected = lk.compareBmp(orig, recon);
    x.metrics = expected;
    await tester.pumpWidget(host(ImageQualityPanel(lab: lab)));
    expect(
      find.textContaining('PSNR ${expected.psnr.toStringAsFixed(2)} dB'),
      findsOneWidget,
    );
    expect(
      find.textContaining('SSIM ${expected.ssim.toStringAsFixed(4)}'),
      findsOneWidget,
    );

    final missing = ImageTransfer('t2', 'other.bmp')
      ..addOriginalChunk(0, orig, orig.length);
    lab.transfers['t2'] = missing;
    await tester.pumpWidget(host(ImageQualityPanel(lab: lab)));
    expect(find.textContaining('Waiting for the receiver'), findsOneWidget);
  });

  test('chunked reconstruction is assembled by offset', () {
    final x = ImageTransfer('t', 'f');
    x.addReconstructedChunk(3, [4, 5], 5, false);
    x.addReconstructedChunk(0, [1, 2, 3], 5, true);
    expect(x.reconstructedComplete, isTrue);
    expect(x.reconstructed, [1, 2, 3, 4, 5]);
  });

  testWidgets('idle media stream is shown as open, not as a fault', (
    tester,
  ) async {
    final lab = idleLab();
    lab.streams['receiver media']!.status = streamWaiting;
    lab.streams['sender traces']!.status = streamStreaming;
    await tester.pumpWidget(host(ConnectionHealthPanel(lab: lab)));
    expect(
      find.text(
        'receiver media: open, waiting for first message (media is only sent during file transfers)',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('connecting'), findsNothing);
  });

  testWidgets('controller view includes the signal probe', (tester) async {
    final lab = idleLab();
    await tester.pumpWidget(host(LiveMonitorSection(lab: lab, roleIndex: 2)));
    expect(find.byType(MlPanel), findsOneWidget);
    expect(find.byType(SignalProbePanel), findsOneWidget);
  });
}
