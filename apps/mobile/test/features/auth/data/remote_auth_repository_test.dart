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
              'success': true,
              'statusCode': 201,
              'data': {
                'token': 'jwt-mock-token-xyz',
                'user': {
                  'id': 'user-db-123',
                  'email': 'newuser@example.com',
                  'name': 'New User',
                  'monthly_income': 45000,
                  'created_at': '2026-10-05T12:00:00.000Z',
                },
              },
              'timestamp': '2026-10-05T12:00:00.000Z',
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

    test('registerWithEmail sends security_pin in request body when provided',
        () async {
      const customPin = '654321';
      final mockClient = MockClient((request) async {
        if (request.url.path == '/auth/register' && request.method == 'POST') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['email'], 'pinuser@example.com');
          expect(body['password'], 'securePass123');
          expect(body['name'], 'Pin User');
          expect(body['security_pin'], customPin);

          return http.Response(
            jsonEncode({
              'success': true,
              'statusCode': 201,
              'data': {
                'token': 'jwt-mock-token-xyz',
                'user': {
                  'id': 'user-db-pin',
                  'email': 'pinuser@example.com',
                  'name': 'Pin User',
                  'monthly_income': 50000,
                  'created_at': '2026-10-05T12:00:00.000Z',
                },
              },
              'timestamp': '2026-10-05T12:00:00.000Z',
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
        email: 'pinuser@example.com',
        password: 'securePass123',
        name: 'Pin User',
        securityPin: customPin,
      );

      expect(result.isRight(), isTrue);
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
              'success': true,
              'statusCode': 200,
              'data': {
                'token': 'jwt-login-token-abc',
                'user': {
                  'id': 'user-logged-in',
                  'email': 'user@example.com',
                  'name': 'John Doe',
                  'monthly_income': 50000,
                },
              },
              'timestamp': '2026-10-05T12:00:00.000Z',
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
              'success': true,
              'statusCode': 200,
              'data': {
                'token': 'apple-jwt-token',
                'user': {
                  'id': 'apple-user-id',
                  'email': 'user@icloud.com',
                  'name': 'Jane Doe (Apple User)',
                },
              },
              'timestamp': '2026-10-05T12:00:00.000Z',
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

    // ---------------------------------------------------------------------
    // XC-2 regression: เดิม repository อ่าน data['token'] / data['user'] จาก
    // ระดับบนสุดของ response ทั้งที่ของจริงซ้อนอยู่ใน `data` ของ envelope ผลคือ
    // token = null (ไม่เคยถูกเซฟ) แต่ยังคืน User ปลอมที่ id = 'user-<timestamp>'
    // ทำให้ UI แสดงว่า "เข้าสู่ระบบสำเร็จ" ทั้งที่ไม่มี token อยู่ในมือเลย
    // ---------------------------------------------------------------------
    group('XC-2 envelope regression', () {
      test('login ด้วย envelope จริง: ได้ User จริงและ token ถูกเซฟลง storage',
          () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({
              'success': true,
              'statusCode': 200,
              'data': {
                'token': 'real-jwt-from-envelope',
                'user': {
                  'id': 'real-user-uuid',
                  'email': 'user@example.com',
                  'name': 'Real User',
                  'monthly_income': 35000,
                  'created_at': '2026-10-05T12:00:00.000Z',
                },
              },
              'timestamp': '2026-10-05T12:00:00.000Z',
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
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
          (failure) => fail('Expected Right but got Left: $failure'),
          (user) {
            // id ของจริงจาก backend ไม่ใช่ 'user-<timestamp>' ที่ fallback สร้างขึ้น
            expect(user.id, 'real-user-uuid');
            expect(
              user.id,
              isNot(startsWith('user-1')),
              reason: 'id แบบ user-<timestamp> คือสัญญาณว่า fallback ทำงาน '
                  'แปลว่า envelope ไม่ถูกแกะ',
            );
            expect(user.email, 'user@example.com');
            expect(user.income, 35000.0);
          },
        );

        final prefs = await SharedPreferences.getInstance();
        expect(
          prefs.getString('auth_token'),
          'real-jwt-from-envelope',
          reason: 'token ต้องถูกเซฟจริง ไม่ใช่เงียบหายไปเพราะอ่านผิดชั้น',
        );
      });

      test('shape แบนแบบเก่า (ไม่มี envelope) ต้องล้มเหลว ไม่ใช่สร้าง User ปลอม',
          () async {
        final mockClient = MockClient((request) async {
          // นี่คือ shape ที่โค้ดเดิมยอมรับ
          return http.Response(
            jsonEncode({
              'token': 'legacy-flat-token',
              'user': {'id': 'legacy-user', 'email': 'user@example.com'},
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        });

        final repository = RemoteAuthRepository(
          client: mockClient,
          baseUrl: testBaseUrl,
        );

        final result = await repository.loginWithEmail(
          email: 'user@example.com',
          password: 'password123',
        );

        expect(
          result.isLeft(),
          isTrue,
          reason: '200 ที่ไม่มี success:true ต้องไม่ถูกนับว่าสำเร็จ',
        );

        final prefs = await SharedPreferences.getInstance();
        expect(
          prefs.getString('auth_token'),
          isNull,
          reason: 'ห้ามเซฟ token จาก response ที่ไม่ผ่าน envelope',
        );
      });

      test('envelope ถูกต้องแต่ไม่มี token → ล้มเหลว และไม่เซฟอะไร', () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({
              'success': true,
              'statusCode': 200,
              'data': {
                'user': {'id': 'u-1', 'email': 'user@example.com'},
              },
              'timestamp': '2026-10-05T12:00:00.000Z',
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        });

        final repository = RemoteAuthRepository(
          client: mockClient,
          baseUrl: testBaseUrl,
        );

        final result = await repository.loginWithEmail(
          email: 'user@example.com',
          password: 'password123',
        );

        expect(result.isLeft(), isTrue);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('auth_token'), isNull);
      });

      test('400 ที่มี message เป็น list → ได้ข้อความครบทุกข้อ', () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({
              'success': false,
              'statusCode': 400,
              'timestamp': '2026-10-05T12:00:00.000Z',
              'path': '/auth/register',
              'message': [
                'email must be an email',
                'password must be longer than or equal to 6 characters',
              ],
              'error': 'Bad Request',
            }),
            400,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        });

        final repository = RemoteAuthRepository(
          client: mockClient,
          baseUrl: testBaseUrl,
        );

        final result = await repository.registerWithEmail(
          email: 'not-an-email',
          password: '123',
        );

        result.fold(
          (failure) {
            expect(failure.displayMessage, contains('must be an email'));
            expect(failure.displayMessage, contains('longer than or equal'));
          },
          (user) => fail('Expected Left but got Right: $user'),
        );
      });
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
