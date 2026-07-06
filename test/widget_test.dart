import 'package:flutter_test/flutter_test.dart';
import 'package:subscription_track/main.dart';

void main() {
  testWidgets('Dashboard smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Verify that the dashboard titles and logo headers are found on the screen.
    expect(find.text('Subscription Track'), findsOneWidget);
    expect(find.text('Spark Cluster: IDLE'), findsOneWidget);
    expect(find.text('ภาพรวมระบบป้องกันค่าบริการซ้ำซ้อน'), findsOneWidget);
  });
}
