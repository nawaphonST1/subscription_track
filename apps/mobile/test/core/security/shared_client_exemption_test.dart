import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:subscription_track/core/security/pin_provider.dart';
import 'package:subscription_track/features/auth/application/auth_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Shared AuthenticatedHttpClient 401 Exemption Wiring Tests', () {
    test(
      '401 from /users/pin does NOT trigger handleSessionExpired; 401 from non-exempt path DOES trigger it through the real shared client',
      () async {
        SharedPreferences.setMockInitialValues({'auth_token': 'active-jwt-token'});

        final mockInnerClient = MockClient((request) async {
          // Exempt path: /users/pin
          if (request.url.path == '/users/pin' && request.method == 'PATCH') {
            return http.Response(
              jsonEncode({
                'success': false,
                'statusCode': 401,
                'message': 'Current PIN is incorrect',
                'timestamp': '2026-10-06T12:00:00.000Z',
              }),
              401,
              headers: {'content-type': 'application/json'},
            );
          }

          // Initial session restore or non-exempt path: /users/me
          if (request.url.path == '/users/me') {
            if (request.headers['x-simulate-expired'] == 'true') {
              return http.Response(
                jsonEncode({
                  'success': false,
                  'statusCode': 401,
                  'message': 'Token expired',
                  'timestamp': '2026-10-06T12:00:00.000Z',
                }),
                401,
                headers: {'content-type': 'application/json'},
              );
            }

            return http.Response(
              jsonEncode({
                'success': true,
                'statusCode': 200,
                'data': {
                  'id': 'user-active-1',
                  'email': 'active@example.com',
                  'name': 'Active User',
                  'monthly_income': 50000,
                  'pin_configured': true,
                  'created_at': '2026-10-06T12:00:00.000Z',
                },
                'timestamp': '2026-10-06T12:00:00.000Z',
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }

          return http.Response('Not Found', 404);
        });

        final container = ProviderContainer(
          overrides: [
            innerHttpClientProvider.overrideWithValue(mockInnerClient),
          ],
        );
        addTearDown(container.dispose);

        // Keep authProvider alive and wait for initial session restore
        final sub = container.listen(authProvider, (_, __) {});
        addTearDown(sub.close);

        // Wait for session restore to complete with active user
        await Future<void>.delayed(const Duration(milliseconds: 100));
        expect(container.read(authProvider).value, isNotNull);
        expect(container.read(authProvider).value?.email, 'active@example.com');

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('auth_token'), 'active-jwt-token');

        // 1. Call pinRepositoryProvider (uses the shared AuthenticatedHttpClient)
        final pinRepo = container.read(pinRepositoryProvider);
        final pinResult = await pinRepo.changePin(
          currentPin: '000000',
          newPin: '999999',
        );

        // Expect changePin to fail with an error because 401 was returned
        expect(pinResult.isLeft(), isTrue);

        // Exemption MUST ensure handleSessionExpired was NOT called:
        // User remains logged in and token is not cleared!
        expect(container.read(authProvider).value, isNotNull);
        expect(prefs.getString('auth_token'), 'active-jwt-token');

        // 2. Now trigger a 401 on a NON-EXEMPT path through the same shared client
        final sharedClient = container.read(authenticatedHttpClientProvider);
        final nonExemptResponse = await sharedClient.get(
          Uri.parse('http://localhost:3000/users/me'),
          headers: {'x-simulate-expired': 'true'},
        );
        expect(nonExemptResponse.statusCode, 401);

        // handleSessionExpired MUST be triggered through the shared client callback:
        // User session is cleared
        expect(container.read(authProvider).value, isNull);
        expect(prefs.getString('auth_token'), isNull);
      },
    );
  });
}
