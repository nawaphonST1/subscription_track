import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:subscription_track/app/routing/route_constants.dart';
import 'package:subscription_track/core/errors/failures.dart';
import 'package:subscription_track/features/auth/application/auth_provider.dart';
import 'package:subscription_track/features/auth/domain/auth_repository.dart';
import 'package:subscription_track/features/auth/domain/user.dart';
import 'package:subscription_track/features/auth/presentation/register_screen.dart';

import '../../../support/stub_auth_repository.dart';

class _TrackingAuthRepository extends StubAuthRepository {
  String? capturedEmail;
  String? capturedPassword;
  String? capturedName;
  String? capturedSecurityPin;
  int registerCallCount = 0;
  double? capturedMonthlyIncome;

  @override
  Future<Either<Failure, User>> registerWithEmail({
    required String email,
    required String password,
    String? name,
    double? monthlyIncome,
    String? securityPin,
  }) async {
    registerCallCount++;
    capturedEmail = email;
    capturedPassword = password;
    capturedName = name;
    capturedMonthlyIncome = monthlyIncome;
    capturedSecurityPin = securityPin;
    return right(User(id: 'new-user', email: email, name: name ?? '', income: monthlyIncome ?? 0.0));
  }
}

void main() {
  const testPin = '234567';
  const testMismatchPin = '765432';

  Widget createWidgetUnderTest({AuthRepository? repo}) {
    final router = GoRouter(
      initialLocation: '/register',
      routes: [
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: RouteConstants.dashboard,
          builder: (context, state) => const Scaffold(body: Text('Dashboard')),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(repo ?? StubAuthRepository()),
      ],
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );
  }

  group('RegisterScreen 2-Step Wizard Tests', () {
    testWidgets('renders all Step 1 input fields, buttons and titles properly',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      // Check title and subtitle
      expect(find.text('สร้างบัญชีใหม่'), findsOneWidget);
      expect(
        find.text('ขั้นตอนที่ 1 จาก 2: ข้อมูลส่วนตัวและรหัสผ่าน'),
        findsOneWidget,
      );

      // Check input labels
      expect(find.text('ชื่อ-นามสกุล'), findsOneWidget);
      expect(find.text('รายได้ต่อเดือน (บาท)'), findsNothing);
      expect(find.text('เบอร์โทรศัพท์ (ถ้ามี)'), findsOneWidget);
      expect(find.text('อีเมล'), findsOneWidget);
      expect(find.text('รหัสผ่าน'), findsOneWidget);
      expect(find.text('ยืนยันรหัสผ่าน'), findsOneWidget);

      // Check buttons
      expect(find.byKey(const Key('register_next_button')), findsOneWidget);
      expect(find.text('Google'), findsOneWidget);
      expect(find.text('Apple'), findsNothing);
      expect(find.text('เข้าสู่ระบบ'), findsOneWidget);
    });

    testWidgets('shows validation errors when Step 1 fields are empty',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      final nextBtn = find.byKey(const Key('register_next_button'));
      await tester.ensureVisible(nextBtn);
      await tester.tap(nextBtn);
      await tester.pumpAndSettle();

      // Expect validation error messages
      expect(find.text('กรุณากรอกชื่อของคุณ'), findsOneWidget);
      expect(find.text('กรุณากรอกอีเมล'), findsOneWidget);
      expect(find.text('กรุณากรอกรหัสผ่าน'), findsOneWidget);
    });

    testWidgets('shows validation error when password is less than 6 characters',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      await tester.enterText(
          find.byKey(const Key('register_name_field')), 'สมชาย ใจดี');
      await tester.enterText(
          find.byKey(const Key('register_email_field')), 'somchai@example.com');
      await tester.enterText(
          find.byKey(const Key('register_password_field')), '12345');
      await tester.enterText(
          find.byKey(const Key('register_confirm_password_field')), '12345');

      final nextBtn = find.byKey(const Key('register_next_button'));
      await tester.ensureVisible(nextBtn);
      await tester.tap(nextBtn);
      await tester.pumpAndSettle();

      expect(find.text('รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร'), findsOneWidget);
    });

    testWidgets('shows validation error when passwords do not match',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      await tester.enterText(
          find.byKey(const Key('register_name_field')), 'สมชาย ใจดี');
      await tester.enterText(
          find.byKey(const Key('register_email_field')), 'somchai@example.com');
      await tester.enterText(
          find.byKey(const Key('register_password_field')), 'Password123');
      await tester.enterText(
          find.byKey(const Key('register_confirm_password_field')),
          'DifferentPassword');

      final nextBtn = find.byKey(const Key('register_next_button'));
      await tester.ensureVisible(nextBtn);
      await tester.tap(nextBtn);
      await tester.pumpAndSettle();

      expect(find.text('รหัสผ่านไม่ตรงกัน'), findsOneWidget);
    });

    testWidgets('step navigation: advances to Step 2 and can return to Step 1',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      // Fill valid Step 1
      await tester.enterText(
          find.byKey(const Key('register_name_field')), 'สมชาย ใจดี');
      await tester.enterText(
          find.byKey(const Key('register_email_field')), 'somchai@example.com');
      await tester.enterText(
          find.byKey(const Key('register_password_field')), 'Password123');
      await tester.enterText(
          find.byKey(const Key('register_confirm_password_field')), 'Password123');

      final nextBtn = find.byKey(const Key('register_next_button'));
      await tester.ensureVisible(nextBtn);
      await tester.tap(nextBtn);
      await tester.pumpAndSettle();

      // In Step 2
      expect(find.text('ตั้งรหัส PIN ความปลอดภัย'), findsOneWidget);
      expect(
        find.text('ขั้นตอนที่ 2 จาก 2: รหัส PIN 6 หลักสำหรับยืนยันการทำรายการสำคัญ'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('register_pin_field')), findsOneWidget);
      expect(find.byKey(const Key('register_confirm_pin_field')), findsOneWidget);
      expect(find.byKey(const Key('register_submit_button')), findsOneWidget);

      // Tap back button
      final backBtn = find.byKey(const Key('register_back_button'));
      await tester.ensureVisible(backBtn);
      await tester.tap(backBtn);
      await tester.pumpAndSettle();

      // Back to Step 1 with preserved values
      expect(find.text('สร้างบัญชีใหม่'), findsOneWidget);
      expect(find.text('somchai@example.com'), findsOneWidget);
    });

    testWidgets('shows validation error when PIN confirmation does not match',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      // Fill Step 1
      await tester.enterText(
          find.byKey(const Key('register_name_field')), 'สมชาย ใจดี');
      await tester.enterText(
          find.byKey(const Key('register_email_field')), 'somchai@example.com');
      await tester.enterText(
          find.byKey(const Key('register_password_field')), 'Password123');
      await tester.enterText(
          find.byKey(const Key('register_confirm_password_field')), 'Password123');

      await tester.tap(find.byKey(const Key('register_next_button')));
      await tester.pumpAndSettle();

      // Fill Step 2 with mismatching PINs
      await tester.enterText(
          find.byKey(const Key('register_pin_field')), testPin);
      await tester.enterText(
          find.byKey(const Key('register_confirm_pin_field')), testMismatchPin);

      final submitBtn = find.byKey(const Key('register_submit_button'));
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(find.text('รหัส PIN ยืนยันไม่ตรงกัน'), findsOneWidget);
    });

    testWidgets('submits custom security PIN reaching backend request body',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final trackingRepo = _TrackingAuthRepository();
      await tester.pumpWidget(createWidgetUnderTest(repo: trackingRepo));
      await tester.pump();

      // Fill Step 1
      await tester.enterText(
          find.byKey(const Key('register_name_field')), 'สมชาย ใจดี');
      await tester.enterText(
          find.byKey(const Key('register_email_field')), 'somchai@example.com');
      await tester.enterText(
          find.byKey(const Key('register_password_field')), 'Password123');
      await tester.enterText(
          find.byKey(const Key('register_confirm_password_field')), 'Password123');

      await tester.tap(find.byKey(const Key('register_next_button')));
      await tester.pumpAndSettle();

      // Fill Step 2 with valid matching PIN
      await tester.enterText(
          find.byKey(const Key('register_pin_field')), testPin);
      await tester.enterText(
          find.byKey(const Key('register_confirm_pin_field')), testPin);

      final submitBtn = find.byKey(const Key('register_submit_button'));
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(trackingRepo.registerCallCount, 1);
      expect(trackingRepo.capturedEmail, 'somchai@example.com');
      expect(trackingRepo.capturedName, 'สมชาย ใจดี');
      expect(trackingRepo.capturedMonthlyIncome, isNull);
      expect(trackingRepo.capturedPassword, 'Password123');
      expect(trackingRepo.capturedSecurityPin, testPin);
    });
  });
}
