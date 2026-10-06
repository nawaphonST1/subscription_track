import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:subscription_track/app/routing/route_constants.dart';
import 'package:subscription_track/core/errors/failures.dart';
import 'package:subscription_track/core/security/pin_provider.dart';
import 'package:subscription_track/features/auth/application/auth_provider.dart';
import 'package:subscription_track/features/auth/domain/user.dart';
import 'package:subscription_track/features/auth/presentation/setup_pin_screen.dart';

import '../../../support/in_memory_pin_repository.dart';
import '../../../support/stub_auth_repository.dart';

void main() {
  const testCurrentPin = '111111'; // Local test constant for unrotated default PIN
  const testNewPin = '654321';
  const testMismatchPin = '999999';

  Widget createWidgetUnderTest({
    required InMemoryPinRepository pinRepo,
    User? initialUser,
  }) {
    final router = GoRouter(
      initialLocation: RouteConstants.setupPin,
      routes: [
        GoRoute(
          path: RouteConstants.setupPin,
          builder: (context, state) => const SetupPinScreen(),
        ),
        GoRoute(
          path: RouteConstants.dashboard,
          builder: (context, state) => const Scaffold(
            body: Text('Dashboard View'),
          ),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        pinRepositoryProvider.overrideWithValue(pinRepo),
        authRepositoryProvider.overrideWithValue(StubAuthRepository()),
        authProvider.overrideWith(
          () => _TestAuthNotifier(
            initialUser ??
                const User(
                  id: 'user-default-pin',
                  email: 'social@example.com',
                  pinConfigured: false,
                ),
          ),
        ),
      ],
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );
  }

  group('SetupPinScreen Widget Tests', () {
    testWidgets('renders all fields, headers, and submit button properly',
        (tester) async {
      final pinRepo = InMemoryPinRepository(currentPin: testCurrentPin);

      await tester.pumpWidget(createWidgetUnderTest(pinRepo: pinRepo));
      await tester.pumpAndSettle();

      expect(find.text('ตั้งค่ารหัสความปลอดภัย (PIN)'), findsOneWidget);
      expect(find.byKey(const Key('setup_current_pin_field')), findsOneWidget);
      expect(find.byKey(const Key('setup_new_pin_field')), findsOneWidget);
      expect(find.byKey(const Key('setup_confirm_pin_field')), findsOneWidget);
      expect(find.byKey(const Key('setup_pin_submit_button')), findsOneWidget);
    });

    testWidgets('shows validation error when fields are empty', (tester) async {
      final pinRepo = InMemoryPinRepository(currentPin: testCurrentPin);

      await tester.pumpWidget(createWidgetUnderTest(pinRepo: pinRepo));
      await tester.pumpAndSettle();

      final submitBtn = find.byKey(const Key('setup_pin_submit_button'));
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(find.text('กรุณากรอกรหัส PIN เดิมหรือรหัสเริ่มต้น'), findsOneWidget);
      expect(find.text('กรุณากรอกรหัส PIN ใหม่'), findsOneWidget);
      expect(pinRepo.changeCallCount, 0);
    });

    testWidgets('shows validation error when new PIN equals current PIN',
        (tester) async {
      final pinRepo = InMemoryPinRepository(currentPin: testCurrentPin);

      await tester.pumpWidget(createWidgetUnderTest(pinRepo: pinRepo));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('setup_current_pin_field')), testCurrentPin);
      await tester.enterText(
          find.byKey(const Key('setup_new_pin_field')), testCurrentPin);
      await tester.enterText(
          find.byKey(const Key('setup_confirm_pin_field')), testCurrentPin);

      final submitBtn = find.byKey(const Key('setup_pin_submit_button'));
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(find.text('รหัส PIN ใหม่ต้องไม่ซ้ำกับรหัสเดิม'), findsOneWidget);
      expect(pinRepo.changeCallCount, 0);
    });

    testWidgets('shows validation error when confirm PIN does not match',
        (tester) async {
      final pinRepo = InMemoryPinRepository(currentPin: testCurrentPin);

      await tester.pumpWidget(createWidgetUnderTest(pinRepo: pinRepo));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('setup_current_pin_field')), testCurrentPin);
      await tester.enterText(
          find.byKey(const Key('setup_new_pin_field')), testNewPin);
      await tester.enterText(
          find.byKey(const Key('setup_confirm_pin_field')), testMismatchPin);

      final submitBtn = find.byKey(const Key('setup_pin_submit_button'));
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(find.text('รหัส PIN ยืนยันไม่ตรงกัน'), findsOneWidget);
      expect(pinRepo.changeCallCount, 0);
    });

    testWidgets(
        'completes PIN setup via changePin and unlocks navigation to dashboard',
        (tester) async {
      final pinRepo = InMemoryPinRepository(currentPin: testCurrentPin);

      await tester.pumpWidget(createWidgetUnderTest(pinRepo: pinRepo));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('setup_current_pin_field')), testCurrentPin);
      await tester.enterText(
          find.byKey(const Key('setup_new_pin_field')), testNewPin);
      await tester.enterText(
          find.byKey(const Key('setup_confirm_pin_field')), testNewPin);

      final submitBtn = find.byKey(const Key('setup_pin_submit_button'));
      await tester.tap(submitBtn);
      await tester.pump();
      await tester.pumpAndSettle();

      expect(pinRepo.changeCallCount, 1);
      expect(pinRepo.lastChangedCurrentPin, testCurrentPin);
      expect(pinRepo.lastChangedNewPin, testNewPin);

      expect(find.text('ตั้งค่ารหัส PIN สำเร็จแล้ว'), findsOneWidget);
      expect(find.text('Dashboard View'), findsOneWidget);
    });

    testWidgets('displays server error on changePin failure without navigating',
        (tester) async {
      final pinRepo = InMemoryPinRepository(
        currentPin: testCurrentPin,
        changeResult: left(const Failure.serverError('Server error updating PIN')),
      );

      await tester.pumpWidget(createWidgetUnderTest(pinRepo: pinRepo));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('setup_current_pin_field')), testCurrentPin);
      await tester.enterText(
          find.byKey(const Key('setup_new_pin_field')), testNewPin);
      await tester.enterText(
          find.byKey(const Key('setup_confirm_pin_field')), testNewPin);

      final submitBtn = find.byKey(const Key('setup_pin_submit_button'));
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(pinRepo.changeCallCount, 1);
      expect(find.text('Server error updating PIN'), findsOneWidget);
      expect(find.text('Dashboard View'), findsNothing);
    });
  });
}

class _TestAuthNotifier extends AuthNotifier {
  _TestAuthNotifier(this._initialUser);
  final User _initialUser;

  @override
  AsyncValue<User?> build() {
    return AsyncValue.data(_initialUser);
  }
}
