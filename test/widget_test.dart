import 'package:flutter_test/flutter_test.dart';
import 'package:subscription_track/main.dart';

void main() {
  testWidgets('Dashboard smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Verify that the dashboard titles and logo headers are found on the screen.
    expect(find.text('Subscription Creep'), findsOneWidget);
    expect(find.text('Spark Cluster: IDLE'), findsOneWidget);
    expect(find.text('ภาพรวมระบบป้องกันค่าบริการซ้ำซ้อน'), findsOneWidget);
  });

  testWidgets('Filter chips update the visible subscription list', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('NETFLIX.COM BANGKOK'), findsOneWidget);
    expect(find.text('Google One Cloud'), findsOneWidget);

    await tester.tap(find.text('คลาวด์'));
    await tester.pumpAndSettle();

    expect(find.text('Google One Cloud'), findsOneWidget);
    expect(find.text('NETFLIX.COM BANGKOK'), findsNothing);
  });
}
