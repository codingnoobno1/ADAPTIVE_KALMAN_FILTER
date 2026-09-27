import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:signal_monitor/main.dart';

void main() {
  test('command-line role supports both argument forms', () {
    expect(AppRole.fromArguments(['--role', 'sender']), AppRole.sender);
    expect(AppRole.fromArguments(['--role=receiver']), AppRole.receiver);
    expect(AppRole.fromArguments(['--role', 'controller']), AppRole.controller);
    expect(AppRole.fromArguments(['--role', 'unknown']), isNull);
    expect(
      endpointFromArguments(['--endpoint', 'grpc://10.0.0.3:55053']),
      'grpc://10.0.0.3:55053',
    );
    expect(
      endpointFromArguments(['--endpoint=http://lab:8080']),
      'http://lab:8080',
    );
    expect(
      endpointFromArguments(['--api=grpc://lab:55053']),
      'grpc://lab:55053',
    );
  });

  test('sender transfer API is derived from the lab endpoint', () {
    expect(
      senderTransferUri(
        'grpc://10.0.0.30:55053?txHost=10.0.0.10&txHttpPort=9081',
      ).toString(),
      'http://10.0.0.10:9081/api/v1/transfers',
    );
  });

  testWidgets('first run asks which role this device should use', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const SignalMonitorApp());
    expect(find.text('CHOOSE THIS DEVICE ROLE'), findsOneWidget);
    expect(find.text('RUN AS SENDER'), findsOneWidget);
    expect(find.text('RUN AS RECEIVER'), findsOneWidget);
    expect(find.text('RUN AS CONTROLLER'), findsOneWidget);
    await tester.tap(find.text('RUN AS RECEIVER'));
    await tester.pump();
    expect(find.text('SERVER API / LAB ENDPOINT'), findsOneWidget);
    expect(find.byKey(const Key('setup-endpoint')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('complete-setup')));
    await tester.tap(find.byKey(const Key('complete-setup')));
    await tester.pumpAndSettle();
    expect(find.text('Adaptive Kalman Receiver'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sender role renders configuration and signal previews', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const SignalMonitorApp(initialRole: AppRole.sender),
    );
    expect(find.text('BPSK Signal Generator'), findsOneWidget);
    expect(find.text('SIGNAL CONFIGURATION'), findsOneWidget);
    expect(find.text('BPSK CONSTELLATION / PREVIEW'), findsOneWidget);
    expect(find.text('TRANSMISSION STATUS'), findsOneWidget);
    expect(find.text('FILE TRANSMISSION / BPSK QUEUE'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('receiver role renders DSP metrics and media', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const SignalMonitorApp(initialRole: AppRole.receiver),
    );
    expect(find.text('Adaptive Kalman Receiver'), findsOneWidget);
    expect(find.text('SIGNAL / NOISE'), findsOneWidget);
    expect(find.text('BIT ERROR RATE'), findsOneWidget);
    expect(find.text('RECEIVER MEDIA'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('controller role renders topology and adaptation console', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 2200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const SignalMonitorApp(initialRole: AppRole.controller),
    );
    expect(find.text('Adaptive Experiment Control'), findsOneWidget);
    expect(find.text('Sender'), findsOneWidget);
    expect(find.text('Receiver'), findsOneWidget);
    expect(find.text('Controller'), findsOneWidget);
    expect(find.text('ADAPTATION EVENT LOG'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('role selector fits a narrow mobile viewport', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const SignalMonitorApp());
    expect(find.text('CHOOSE THIS DEVICE ROLE'), findsOneWidget);
    expect(find.text('RUN AS SENDER'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sender workspace adapts to a narrow mobile viewport', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const SignalMonitorApp(initialRole: AppRole.sender),
    );
    expect(find.text('BPSK Signal Generator'), findsOneWidget);
    expect(find.text('SIGNAL CONFIGURATION'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
