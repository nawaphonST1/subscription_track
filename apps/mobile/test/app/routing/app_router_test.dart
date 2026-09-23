import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subscription_track/app/app.dart';
import 'package:subscription_track/app/application/app_flow_provider.dart';
import 'package:subscription_track/features/onboarding/application/onboarding_controller.dart';

ProviderScope _buildTestApp(AppFlowState initialState) {
  return ProviderScope(
    overrides: [
      // Test เลือก startup destination ได้โดยไม่แก้ mock state ใน production
      appFlowProvider.overrideWithValue(initialState),
    ],
    child: const App(),
  );
}

// ignore: unused_element
ProviderScope _buildStateDrivenTestApp({
  required bool isMockAuthEnabled,
  required bool isOnboardingCompleted,
}) {
  return ProviderScope(
    overrides: [
      mockAuthBypassProvider.overrideWithBuild(
        (ref, controller) => isMockAuthEnabled,
      ),
      onboardingProvider.overrideWithBuild(
        (ref, controller) => isOnboardingCompleted,
      ),
    ],
    child: const App(),
  );
}

void main() {
  testWidgets('renders Dashboard tab by default', (WidgetTester tester) async {
    await tester.pumpWidget(_buildTestApp(AppFlowState.mockDashboard));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('hero-payout-card')), findsOneWidget);
    expect(find.text('รายจ่ายค่าสมาชิกรวม'), findsOneWidget);
    expect(find.byKey(const Key('main-bottom-navigation')), findsOneWidget);
  });

  testWidgets('keeps navigation visible on nested dashboard routes', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_buildTestApp(AppFlowState.mockDashboard));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('notification-button')));
    await tester.pumpAndSettle();

    expect(find.text('การแจ้งเตือน'), findsOneWidget);
    expect(find.byKey(const Key('main-bottom-navigation')), findsOneWidget);
    expect(find.byKey(const Key('header-profile-button')), findsNothing);
  });

  testWidgets('Filter chips update the visible subscription list', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_buildTestApp(AppFlowState.mockDashboard));
    await tester.pumpAndSettle();

    await tester.tap(find.text('รายการ'));
    await tester.pumpAndSettle();

    expect(find.text('Netflix Premium'), findsOneWidget);
    expect(find.text('Google One Cloud'), findsOneWidget);

    await tester.tap(find.text('คลาวด์'));
    await tester.pumpAndSettle();

    expect(find.text('Google One Cloud'), findsOneWidget);
    expect(find.text('Netflix Premium'), findsNothing);
  });

  /*
  // --- Production Strict Auth & Onboarding Redirect Guard Tests (Preserved in Comments) ---

  testWidgets('initializing state stays on Splash', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _buildTestApp(
        const AppFlowState(
          isInitializing: true,
          isOnboardingCompleted: false,
          isAuthenticated: false,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('ระบบติดตามการสมัครสมาชิก'), findsOneWidget);
    expect(find.byKey(const Key('hero-payout-card')), findsNothing);
  });

  testWidgets('unauthenticated state redirects to Login', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _buildTestApp(
        const AppFlowState(
          isInitializing: false,
          isOnboardingCompleted: true,
          isAuthenticated: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ยินดีต้อนรับกลับมา'), findsOneWidget);
    expect(find.byKey(const Key('hero-payout-card')), findsNothing);
  });

  testWidgets('first-time flow goes Onboarding to Login to Dashboard', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _buildStateDrivenTestApp(
        isMockAuthEnabled: false,
        isOnboardingCompleted: false,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ติดตามสมาชิก'), findsOneWidget);
    expect(find.text('ข้าม'), findsOneWidget);

    await tester.tap(find.text('ข้าม'));
    await tester.pumpAndSettle();

    expect(find.text('ยินดีต้อนรับกลับมา'), findsOneWidget);

    await tester.tap(find.text('ดำเนินการต่อด้วย Google'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('hero-payout-card')), findsOneWidget);
    expect(find.text('ยินดีต้อนรับกลับมา'), findsNothing);
  });
  */
}
