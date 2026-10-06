import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:subscription_track/app/app.dart';
import 'package:subscription_track/app/application/app_flow_provider.dart';
import 'package:subscription_track/app/routing/app_router.dart';
import 'package:subscription_track/app/routing/route_constants.dart';
import 'package:subscription_track/core/errors/failures.dart';
import 'package:subscription_track/features/auth/application/auth_provider.dart';
import 'package:subscription_track/features/auth/data/in_memory_auth_repository.dart';
import 'package:subscription_track/features/auth/domain/auth_repository.dart';
import 'package:subscription_track/features/auth/domain/user.dart';
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

ProviderScope _buildStateDrivenTestApp({
  required bool isMockAuthEnabled,
  required bool isOnboardingCompleted,
  AuthRepository? authRepository,
}) {
  return ProviderScope(
    overrides: [
      mockAuthBypassProvider.overrideWithBuild(
        (ref, controller) => isMockAuthEnabled,
      ),
      onboardingProvider.overrideWithBuild(
        (ref, controller) => isOnboardingCompleted,
      ),
      authRepositoryProvider.overrideWithValue(
        authRepository ?? InMemoryAuthRepository(),
      ),
    ],
    child: const App(),
  );
}

class _FakeRestoreAuthRepository implements AuthRepository {
  _FakeRestoreAuthRepository({
    this.initialToken,
    required this.userResult,
    this.delay = const Duration(milliseconds: 60),
  });

  String? initialToken;
  final Either<Failure, User> userResult;
  final Duration delay;
  int logoutCalls = 0;

  @override
  Future<Either<Failure, User>> getCurrentUser() async {
    if (initialToken == null || initialToken!.isEmpty) {
      return left(const Failure.unauthorized());
    }
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    return userResult;
  }

  @override
  Future<Either<Failure, Unit>> logout() async {
    logoutCalls++;
    initialToken = null;
    return right(unit);
  }

  @override
  Future<Either<Failure, User>> loginWithEmail({
    required String email,
    required String password,
  }) async =>
      right(User(id: 'login-user', email: email));

  @override
  Future<Either<Failure, User>> registerWithEmail({
    required String email,
    required String password,
    String? name,
  }) async =>
      right(User(id: 'new-user', email: email));

  @override
  Future<Either<Failure, User>> loginWithGoogle() async =>
      right(const User(id: 'g', email: 'g@example.com'));

  @override
  Future<Either<Failure, User>> loginWithApple() async =>
      right(const User(id: 'a', email: 'a@example.com'));
}

ProviderScope _buildRestoreApp({
  required AuthRepository repository,
  required bool isOnboardingCompleted,
}) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(repository),
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

  group('Production Strict Auth & Onboarding Redirect Guards', () {
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

      final googleBtn = find.text('Google');
      await tester.ensureVisible(googleBtn);
      await tester.tap(googleBtn);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('hero-payout-card')), findsOneWidget);
      expect(find.text('ยินดีต้อนรับกลับมา'), findsNothing);
    });

    testWidgets(
        'with mockAuthBypassProvider true, direct URL navigation works without auth check',
        (WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          mockAuthBypassProvider.overrideWithBuild((ref, _) => true),
          onboardingProvider.overrideWithBuild((ref, _) => false),
          authRepositoryProvider.overrideWithValue(InMemoryAuthRepository()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const App(),
        ),
      );
      await tester.pumpAndSettle();

      // เมื่อเข้าหน้า root / ในโหมด bypass จะเข้า Dashboard เป็นค่าเริ่มต้น
      expect(find.byKey(const Key('hero-payout-card')), findsOneWidget);

      // Direct deep link ไปที่ /login ทำงานได้โดยไม่ถูกสกัดกั้นหรือเด้งกลับ
      container.read(appRouterProvider).go(RouteConstants.login);
      await tester.pumpAndSettle();
      expect(find.text('ยินดีต้อนรับกลับมา'), findsOneWidget);

      // Direct deep link ไปที่ /onboarding ทำงานได้เช่นกัน
      container.read(appRouterProvider).go(RouteConstants.onboarding);
      await tester.pumpAndSettle();
      expect(find.text('ติดตามสมาชิก'), findsOneWidget);
    });
  });

  group('End-to-End Session Restore Flow through Router', () {
    testWidgets('app starts with valid stored token: splash -> dashboard (no login screen)', (
      WidgetTester tester,
    ) async {
      final repository = _FakeRestoreAuthRepository(
        initialToken: 'valid-stored-jwt',
        userResult: right(const User(
          id: 'restored-user',
          email: 'restored@example.com',
          name: 'Restored User',
        )),
        delay: const Duration(milliseconds: 60),
      );

      await tester.pumpWidget(_buildRestoreApp(
        repository: repository,
        isOnboardingCompleted: true,
      ));

      // จังหวะแรกที่กู้ session: ยังเป็น loading -> อยู่หน้า Splash
      await tester.pump();
      expect(find.text('ระบบติดตามการสมัครสมาชิก'), findsOneWidget);
      expect(find.byKey(const Key('hero-payout-card')), findsNothing);
      expect(find.text('ยินดีต้อนรับกลับมา'), findsNothing);

      // รอกู้ session เสร็จสิ้น
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // ผลลัพธ์: ตรงไปหน้า Dashboard เลย โดยไม่เคยแสดงหน้า Login
      expect(find.byKey(const Key('hero-payout-card')), findsOneWidget);
      expect(find.text('ยินดีต้อนรับกลับมา'), findsNothing);
      expect(repository.logoutCalls, 0);
    });

    testWidgets('app starts with no token: splash -> login screen', (
      WidgetTester tester,
    ) async {
      final repository = _FakeRestoreAuthRepository(
        initialToken: null,
        userResult: left(const Failure.unauthorized()),
        delay: Duration.zero,
      );

      await tester.pumpWidget(_buildRestoreApp(
        repository: repository,
        isOnboardingCompleted: true,
      ));
      await tester.pumpAndSettle();

      // ผลลัพธ์: ไม่มี token กู้ไม่สำเร็จ -> ส่งไปหน้า Login
      expect(find.text('ยินดีต้อนรับกลับมา'), findsOneWidget);
      expect(find.byKey(const Key('hero-payout-card')), findsNothing);
    });

    testWidgets(
        'app starts with expired/invalid token: splash -> login screen and token is cleared', (
      WidgetTester tester,
    ) async {
      final repository = _FakeRestoreAuthRepository(
        initialToken: 'expired-jwt',
        userResult: left(const Failure.unauthorized()),
        delay: const Duration(milliseconds: 60),
      );

      await tester.pumpWidget(_buildRestoreApp(
        repository: repository,
        isOnboardingCompleted: true,
      ));

      // ระหว่างกู้ session อยู่หน้า Splash
      await tester.pump();
      expect(find.text('ระบบติดตามการสมัครสมาชิก'), findsOneWidget);

      // กู้แล้วเจอ 401
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // ผลลัพธ์: token ถูกล้าง และนำทางไปหน้า Login
      expect(find.text('ยินดีต้อนรับกลับมา'), findsOneWidget);
      expect(find.byKey(const Key('hero-payout-card')), findsNothing);
      expect(repository.logoutCalls, greaterThanOrEqualTo(1));
      expect(repository.initialToken, isNull);
    });
  });
}
