import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subscription_track/app.dart';
import 'package:subscription_track/providers/app_flow_provider.dart';

ProviderScope _buildTestApp(AppFlowState initialState) {
  return ProviderScope(
    overrides: [
      // Test เลือก startup destination ได้โดยไม่แก้ mock state ใน production
      appFlowProvider.overrideWithValue(initialState),
    ],
    child: const App(),
  );
}

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
    expect(find.text('Subscription Creep'), findsNothing);
  });

  testWidgets('authenticated mock state redirects to Dashboard', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_buildTestApp(AppFlowState.mockDashboard));
    await tester.pumpAndSettle();

    expect(find.text('Subscription Creep'), findsOneWidget);
    expect(find.text('Spark Cluster: IDLE'), findsOneWidget);
    expect(find.text('ภาพรวมระบบป้องกันค่าบริการซ้ำซ้อน'), findsOneWidget);
  });

  testWidgets('Filter chips update the visible subscription list', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_buildTestApp(AppFlowState.mockDashboard));
    await tester.pumpAndSettle();

    expect(find.text('NETFLIX.COM BANGKOK'), findsOneWidget);
    expect(find.text('Google One Cloud'), findsOneWidget);

    await tester.tap(find.text('คลาวด์'));
    await tester.pumpAndSettle();

    expect(find.text('Google One Cloud'), findsOneWidget);
    expect(find.text('NETFLIX.COM BANGKOK'), findsNothing);
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

    expect(find.text('Sign in to continue'), findsOneWidget);
    expect(find.text('Subscription Creep'), findsNothing);
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

    expect(find.text('Sign in to continue'), findsOneWidget);

    await tester.tap(find.text('Sign in with Google'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('Subscription Creep'), findsOneWidget);
    expect(find.text('Sign in to continue'), findsNothing);
  });
}
