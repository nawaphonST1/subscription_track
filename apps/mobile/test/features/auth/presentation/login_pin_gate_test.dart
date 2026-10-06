import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:subscription_track/app/app.dart';
import 'package:subscription_track/features/auth/application/auth_provider.dart';
import 'package:subscription_track/features/auth/data/remote_auth_repository.dart';
import 'package:subscription_track/features/auth/presentation/setup_pin_screen.dart';
import 'package:subscription_track/features/onboarding/application/onboarding_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget createTestApp(http.Client client) {
    return ProviderScope(
      overrides: [
        onboardingProvider.overrideWithBuild((ref, _) => true),
        authRepositoryProvider.overrideWithValue(
          RemoteAuthRepository(
            client: client,
            baseUrl: 'http://localhost:3000',
          ),
        ),
      ],
      child: const App(),
    );
  }

  group('F1 Adversarial Login PIN Gate Regression Tests', () {
    testWidgets(
      'login with verbatim server response having pin_configured: false lands on SetupPinScreen, NOT dashboard',
      (tester) async {
        final mockClient = MockClient((request) async {
          if (request.url.path == '/auth/login') {
            return http.Response(
              jsonEncode({
                'success': true,
                'statusCode': 200,
                'data': {
                  'token': 'jwt-unrotated-account',
                  'user': {
                    'id': 'user-db-unrotated',
                    'email': 'unrotated@example.com',
                    'name': 'Unrotated User',
                    'monthly_income': 0,
                    'pin_configured': false,
                    'created_at': '2026-10-06T12:00:00.000Z',
                  },
                },
                'timestamp': '2026-10-06T12:00:00.000Z',
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response('Not Found', 404);
        });

        await tester.pumpWidget(createTestApp(mockClient));
        await tester.pumpAndSettle();

        // Initially on Login screen
        expect(find.text('ยินดีต้อนรับกลับมา'), findsOneWidget);

        // Enter email and password
        await tester.enterText(
          find.byType(TextFormField).first,
          'unrotated@example.com',
        );
        await tester.enterText(
          find.byType(TextFormField).last,
          'password123',
        );

        // Tap Login
        final loginButton1 = find.widgetWithText(ElevatedButton, 'เข้าสู่ระบบ');
        await tester.ensureVisible(loginButton1);
        await tester.tap(loginButton1);
        await tester.pump();
        await tester.pumpAndSettle();

        // MUST land on SetupPinScreen
        expect(find.byType(SetupPinScreen), findsOneWidget);
        expect(find.text('ตั้งค่ารหัสความปลอดภัย (PIN)'), findsOneWidget);

        // MUST NOT land on Dashboard
        expect(find.byKey(const Key('hero-payout-card')), findsNothing);
      },
    );

    testWidgets(
      'login with unpatched server response omitting pin_configured key fails closed to SetupPinScreen',
      (tester) async {
        final mockClient = MockClient((request) async {
          if (request.url.path == '/auth/login') {
            return http.Response(
              jsonEncode({
                'success': true,
                'statusCode': 200,
                'data': {
                  'token': 'jwt-legacy-account',
                  'user': {
                    'id': 'user-db-legacy',
                    'email': 'legacy@example.com',
                    'name': 'Legacy User',
                    'monthly_income': 0,
                    // pin_configured omitted by unpatched server
                    'created_at': '2026-10-06T12:00:00.000Z',
                  },
                },
                'timestamp': '2026-10-06T12:00:00.000Z',
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response('Not Found', 404);
        });

        await tester.pumpWidget(createTestApp(mockClient));
        await tester.pumpAndSettle();

        expect(find.text('ยินดีต้อนรับกลับมา'), findsOneWidget);

        await tester.enterText(
          find.byType(TextFormField).first,
          'legacy@example.com',
        );
        await tester.enterText(
          find.byType(TextFormField).last,
          'password123',
        );

        final loginButton2 = find.widgetWithText(ElevatedButton, 'เข้าสู่ระบบ');
        await tester.ensureVisible(loginButton2);
        await tester.tap(loginButton2);
        await tester.pump();
        await tester.pumpAndSettle();

        // Fail-closed fallback MUST land on SetupPinScreen
        expect(find.byType(SetupPinScreen), findsOneWidget);
        expect(find.text('ตั้งค่ารหัสความปลอดภัย (PIN)'), findsOneWidget);
        expect(find.byKey(const Key('hero-payout-card')), findsNothing);
      },
    );

    testWidgets(
      'login with configured account (pin_configured: true) lands directly on Dashboard',
      (tester) async {
        final mockClient = MockClient((request) async {
          if (request.url.path == '/auth/login') {
            return http.Response(
              jsonEncode({
                'success': true,
                'statusCode': 200,
                'data': {
                  'token': 'jwt-configured-account',
                  'user': {
                    'id': 'user-db-configured',
                    'email': 'configured@example.com',
                    'name': 'Configured User',
                    'monthly_income': 0,
                    'pin_configured': true,
                    'created_at': '2026-10-06T12:00:00.000Z',
                  },
                },
                'timestamp': '2026-10-06T12:00:00.000Z',
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response('Not Found', 404);
        });

        await tester.pumpWidget(createTestApp(mockClient));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byType(TextFormField).first,
          'configured@example.com',
        );
        await tester.enterText(
          find.byType(TextFormField).last,
          'password123',
        );

        final loginButton3 = find.widgetWithText(ElevatedButton, 'เข้าสู่ระบบ');
        await tester.ensureVisible(loginButton3);
        await tester.tap(loginButton3);
        await tester.pump();
        await tester.pumpAndSettle();

        // MUST land on Dashboard directly
        expect(find.byKey(const Key('hero-payout-card')), findsOneWidget);
        expect(find.byType(SetupPinScreen), findsNothing);
      },
    );
  });
}
