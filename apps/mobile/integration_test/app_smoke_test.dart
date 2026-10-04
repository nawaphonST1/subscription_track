import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:subscription_track/app/app.dart';
import 'package:subscription_track/app/application/app_flow_provider.dart';

ProviderScope _buildTestApp(AppFlowState initialState) {
  return ProviderScope(
    overrides: [
      // Test เลือก startup destination ได้โดยไม่แก้ mock state ใน production
      // (bootstrap pattern reused from test/app/routing/app_router_test.dart)
      appFlowProvider.overrideWithValue(initialState),
    ],
    child: const App(),
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'smoke: launches, lands on Dashboard, and visits every primary tab',
    (tester) async {
      await tester.pumpWidget(_buildTestApp(AppFlowState.mockDashboard));
      await tester.pumpAndSettle();

      // Launch → Dashboard
      expect(find.byKey(const Key('hero-payout-card')), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'Dashboard');

      // Dashboard → Subscriptions (รายการ)
      await tester.tap(find.text('รายการ'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('subscription-search-field')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull, reason: 'Subscriptions');

      // Subscriptions → Savings (ประหยัด)
      await tester.tap(find.text('ประหยัด'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('savings-goal-banner')), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'Savings');

      // Savings → Settings (ตั้งค่า)
      await tester.tap(find.text('ตั้งค่า'));
      await tester.pumpAndSettle();
      expect(find.text('แจ้งเตือนก่อนตัดเงิน'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'Settings');

      // Settings → Profile (โปรไฟล์)
      await tester.tap(find.text('โปรไฟล์'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('profile-income-setting')), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'Profile');

      // Profile → back to Dashboard (หน้าแรก)
      await tester.tap(find.text('หน้าแรก'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('hero-payout-card')), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'Dashboard round-trip');
    },
  );
}
