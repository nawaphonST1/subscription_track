import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subscription_track/features/auth/application/auth_provider.dart';
import 'package:subscription_track/features/auth/presentation/login_screen.dart';

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
        home: LoginScreen(),
      ),
    );
  }

  group('LoginScreen Widget Tests', () {
    testWidgets('renders all input fields, buttons, and titles properly',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      // Check title and subtitle
      expect(find.text('ยินดีต้อนรับกลับมา'), findsOneWidget);
      expect(
        find.text('เข้าสู่ระบบเพื่อจัดการ Subscription ของคุณ'),
        findsOneWidget,
      );

      // Check input labels
      expect(find.text('อีเมล'), findsOneWidget);
      expect(find.text('รหัสผ่าน'), findsOneWidget);

      // Check buttons
      expect(find.widgetWithText(ElevatedButton, 'เข้าสู่ระบบ'), findsOneWidget);
      expect(find.text('Google'), findsOneWidget);
      expect(find.text('Apple'), findsNothing);
      expect(find.text('สมัครสมาชิก'), findsOneWidget);
    });

    testWidgets('shows validation errors when fields are empty',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      final btn = find.widgetWithText(ElevatedButton, 'เข้าสู่ระบบ');
      await tester.ensureVisible(btn);
      await tester.tap(btn);
      await tester.pumpAndSettle();

      // Expect validation error messages
      expect(find.text('กรุณากรอกอีเมล'), findsOneWidget);
      expect(find.text('กรุณากรอกรหัสผ่าน'), findsOneWidget);
    });

    testWidgets('shows validation error for invalid email and short password',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      final emailField = find.widgetWithText(TextFormField, 'example@email.com');
      final passwordField = find.widgetWithText(TextFormField, 'กรอกรหัสผ่านของคุณ');

      await tester.enterText(emailField, 'invalid-email');
      await tester.enterText(passwordField, '123');

      final btn = find.widgetWithText(ElevatedButton, 'เข้าสู่ระบบ');
      await tester.ensureVisible(btn);
      await tester.tap(btn);
      await tester.pumpAndSettle();

      expect(find.text('รูปแบบอีเมลไม่ถูกต้อง'), findsOneWidget);
      expect(find.text('รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร'), findsOneWidget);
    });
  });
}
