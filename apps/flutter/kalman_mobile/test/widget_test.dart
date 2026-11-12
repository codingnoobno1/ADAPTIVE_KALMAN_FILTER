import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalman_mobile/main.dart';

void main() {
  testWidgets('mobile phone viewport renders Parameter Matrix and formula sheet', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const KalmanMobileApp(autoPlay: false));
    await tester.pumpAndSettle();

    expect(find.text('Kalman Parameter Lab'), findsOneWidget);
    expect(find.byKey(const Key('mobile-bottom-nav')), findsOneWidget);
    expect(find.byKey(const Key('param-tile-state_x')), findsOneWidget);

    // Tap state_x tile to inspect its mathematical formula bottom sheet
    await tester.tap(find.byKey(const Key('param-tile-state_x')));
    await tester.pumpAndSettle();
    expect(
      find.text('x_k = x_{k-1} + K_k (z_k - x_{k-1})'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('navigates across Charts, Lab, and Live Link on compact phone', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const KalmanMobileApp(autoPlay: false));
    await tester.pumpAndSettle();

    // Switch to Charts tab
    await tester.tap(find.text('Charts'));
    await tester.pumpAndSettle();
    expect(
      find.text('STATE TRACKING (x_k vs z_k vs TRUE OFFSET)'),
      findsOneWidget,
    );

    // Switch to On-Device Lab tab and inject a step impulse
    await tester.tap(find.text('Lab'));
    await tester.pumpAndSettle();
    expect(find.text('SIGNAL & SENSOR STREAM PROFILE'), findsOneWidget);
    await tester.tap(find.byKey(const Key('inject-step-btn')));
    await tester.pumpAndSettle();

    // Switch to Live Link tab
    await tester.tap(find.text('Live Link'));
    await tester.pumpAndSettle();
    expect(
      find.text('TELEMETRY SOURCE & 3-NODE ENDPOINT'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('live-endpoint-input')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tablet viewport uses NavigationRail and multi-column grid', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1024, 768));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const KalmanMobileApp(autoPlay: false));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byKey(const Key('mobile-bottom-nav')), findsNothing);

    // Filter parameter matrix by search query
    await tester.enterText(
      find.byKey(const Key('parameter-search-field')),
      'NIS',
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('param-tile-nis')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
