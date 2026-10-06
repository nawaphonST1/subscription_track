import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subscription_track/features/auth/application/auth_provider.dart';
import 'package:subscription_track/features/auth/presentation/register_screen.dart';

import '../../../support/stub_auth_repository.dart';

void main() {
  Widget createWidgetUnderTest() {
    return ProviderScope(
      // กัน AuthNotifier.build() ไปกู้ session ผ่าน repository ตัวจริง
      // ซึ่งจะเปิด http.Client และแตะ SharedPreferences ที่ไม่มี plugin ในเทสต์
      overrides: [
        authRepositoryProvider.overrideWithValue(StubAuthRepository()),
      ],
      child: const MaterialApp(
        home: RegisterScreen(),
      ),
    );
  }

  group('RegisterScreen Widget Tests', () {
    testWidgets('renders all input fields, buttons and titles properly',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      // Check title and subtitle
      expect(find.text('สร้างบัญชีใหม่'), findsOneWidget);
      expect(
        find.text('เริ่มต้นจัดการค่าใช้จ่ายและการติดตาม Subscription'),
        findsOneWidget,
      );

      // Check input labels
      expect(find.text('ชื่อ-นามสกุล'), findsOneWidget);
      expect(find.text('อีเมล'), findsOneWidget);
      expect(find.text('รหัสผ่าน'), findsOneWidget);
      expect(find.text('ยืนยันรหัสผ่าน'), findsOneWidget);

      // Check buttons
      expect(find.widgetWithText(ElevatedButton, 'สมัครสมาชิก'), findsOneWidget);
      expect(find.text('Google'), findsOneWidget);
      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('เข้าสู่ระบบ'), findsOneWidget);
    });

    testWidgets('shows validation errors when fields are empty',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      final btn = find.widgetWithText(ElevatedButton, 'สมัครสมาชิก');
      await tester.ensureVisible(btn);
      await tester.tap(btn);
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

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'สมชาย ใจดี');
      await tester.enterText(textFields.at(1), 'somchai@example.com');
      await tester.enterText(textFields.at(2), '12345'); // only 5 characters
      await tester.enterText(textFields.at(3), '12345');

      final btn = find.widgetWithText(ElevatedButton, 'สมัครสมาชิก');
      await tester.ensureVisible(btn);
      await tester.tap(btn);
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

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'สมชาย ใจดี');
      await tester.enterText(textFields.at(1), 'somchai@example.com');
      await tester.enterText(textFields.at(2), 'Password123');
      await tester.enterText(textFields.at(3), 'DifferentPassword');

      final btn = find.widgetWithText(ElevatedButton, 'สมัครสมาชิก');
      await tester.ensureVisible(btn);
      await tester.tap(btn);
      await tester.pumpAndSettle();

      expect(find.text('รหัสผ่านไม่ตรงกัน'), findsOneWidget);
    });
  });
}
