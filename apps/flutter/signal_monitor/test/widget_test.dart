import 'package:flutter_test/flutter_test.dart';
import 'package:signal_monitor/main.dart';

void main() {
  testWidgets('dashboard renders key signal metrics', (tester) async {
    await tester.pumpWidget(const SignalMonitorApp());
    expect(find.text('STREAMING / LIVE KALMAN'), findsOneWidget);
    expect(find.text('SIGNAL / NOISE'), findsOneWidget);
    expect(find.text('BIT ERROR RATE'), findsOneWidget);
  });
}
