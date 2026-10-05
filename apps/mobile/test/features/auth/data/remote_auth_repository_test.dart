import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:subscription_track/core/errors/failures.dart';
import 'package:subscription_track/features/auth/data/remote_auth_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('RemoteAuthRepository', () {
    const testBaseUrl = 'http://localhost:3000';

    test('registerWithEmail succeeds with 201 and persists token', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/auth/register' && request.method == 'POST') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['email'], 'newuser@example.com');
          expect(body['password'], 'securePass123');
          expect(body['name'], 'New User');

          return http.Response(
            jsonEncode({
              'token': 'jwt-mock-token-xyz',
              'user': {
                'id': 'user-db-123',
                'email': 'newuser@example.com',
                'name': 'New User',
                'monthly_income': 45000,
                'created_at': '2026-10-05T12:00:00.000Z',
              },
            }),
            201,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final repository = RemoteAuthRepository(
        client: mockClient,
        baseUrl: testBaseUrl,
      );

      final result = await repository.registerWithEmail(
        email: 'newuser@example.com',
        password: 'securePass123',
        name: 'New User',
      );

      expect(result.isRight(), isTrue);
      result.fold(
        (l) => fail('Expected Right but got Left: $l'),
        (user) {
          expect(user.id, 'user-db-123');
          expect(user.email, 'newuser@example.com');
          expect(user.name, 'New User');
          expect(user.income, 45000.0);
        },
      );

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('auth_token'), 'jwt-mock-token-xyz');
    });

    test('registerWithEmail returns Failure on 409 Conflict', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'statusCode': 409,
            'message': 'An account with this email already exists',
            'error': 'Conflict',
          }),
          409,
          headers: {'content-type': 'application/json'},
        );
      });

      final repository = RemoteAuthRepository(
        client: mockClient,
        baseUrl: testBaseUrl,
      );

      final result = await repository.registerWithEmail(
        email: 'existing@example.com',
        password: 'password123',
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) {
          expect(failure, isA<Failure>());
          expect(failure.displayMessage, contains('ลงทะเบียนไว้แล้ว'));
        },
        (r) => fail('Expected Left'),
      );
    });

    test('loginWithEmail succeeds with 200 and persists token', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/auth/login' && request.method == 'POST') {
          return http.Response(
            jsonEncode({
              'token': 'jwt-login-token-abc',
              'user': {
                'id': 'user-logged-in',
                'email': 'user@example.com',
                'name': 'John Doe',
                'monthly_income': 50000,
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Unauthorized', 401);
      });

      final repository = RemoteAuthRepository(
        client: mockClient,
        baseUrl: testBaseUrl,
      );

      final result = await repository.loginWithEmail(
        email: 'user@example.com',
        password: 'password123',
      );

      expect(result.isRight(), isTrue);
      result.fold(
        (l) => fail('Expected Right'),
        (user) {
          expect(user.email, 'user@example.com');
          expect(user.name, 'John Doe');
        },
      );

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('auth_token'), 'jwt-login-token-abc');
    });

    test('loginWithEmail returns unauthorized Failure on 401', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'statusCode': 401,
            'message': 'Invalid email or password',
          }),
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      final repository = RemoteAuthRepository(
        client: mockClient,
        baseUrl: testBaseUrl,
      );

      final result = await repository.loginWithEmail(
        email: 'wrong@example.com',
        password: 'wrongpassword',
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) {
          expect(failure.displayMessage, contains('อีเมลหรือรหัสผ่านไม่ถูกต้อง'));
        },
        (r) => fail('Expected Left'),
      );
    });

    test('loginWithApple uses mock social login flow', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/auth/social' && request.method == 'POST') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['provider'], 'apple');
          expect(body['email'], 'user@icloud.com');

          return http.Response(
            jsonEncode({
              'token': 'apple-jwt-token',
              'user': {
                'id': 'apple-user-id',
                'email': 'user@icloud.com',
                'name': 'Jane Doe (Apple User)',
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final repository = RemoteAuthRepository(
        client: mockClient,
        baseUrl: testBaseUrl,
      );

      final result = await repository.loginWithApple();
      expect(result.isRight(), isTrue);
      result.fold(
        (l) => fail('Expected Right'),
        (user) {
          expect(user.email, 'user@icloud.com');
          expect(user.authProvider, 'apple');
        },
      );
    });

    test('logout clears stored auth token', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', 'token-to-delete');

      final repository = RemoteAuthRepository(
        client: MockClient((_) async => http.Response('', 200)),
        baseUrl: testBaseUrl,
      );

      final result = await repository.logout();
      expect(result.isRight(), isTrue);
      expect(prefs.getString('auth_token'), isNull);
    });
  });
}
