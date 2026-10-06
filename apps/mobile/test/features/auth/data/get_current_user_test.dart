import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:subscription_track/core/errors/failures.dart';
import 'package:subscription_track/features/auth/data/in_memory_auth_repository.dart';
import 'package:subscription_track/features/auth/data/remote_auth_repository.dart';

const _baseUrl = 'http://localhost:3000';
const _token = 'stored-jwt-token';

/// shape จริงของ `GET /users/me` — user object อยู่ที่ `data` ตรง ๆ
/// ไม่ได้ซ้อนใต้คีย์ `user` แบบ 3 endpoint ของ auth
http.Response _meEnvelope() => http.Response(
      jsonEncode({
        'success': true,
        'statusCode': 200,
        'data': {
          'id': 'user-uuid',
          'email': 'user@example.com',
          'name': 'Restored User',
          'monthly_income': 42000,
          'pin_configured': true,
          'active_cards_count': 2,
          'active_subscriptions_count': 5,
          'created_at': '2026-09-01T10:00:00.000Z',
          'updated_at': '2026-10-01T10:00:00.000Z',
        },
        'timestamp': '2026-10-06T07:00:00.000Z',
      }),
      200,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RemoteAuthRepository.getCurrentUser', () {
    test('มี token + 200 → คืน User และยิงไป /users/me พร้อม Bearer', () async {
      SharedPreferences.setMockInitialValues({'auth_token': _token});

      Uri? calledUri;
      String? authHeader;
      final repository = RemoteAuthRepository(
        baseUrl: _baseUrl,
        client: MockClient((request) async {
          calledUri = request.url;
          authHeader = request.headers['Authorization'];
          return _meEnvelope();
        }),
      );

      final result = await repository.getCurrentUser();

      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('คาดว่า Right แต่ได้ Left: $failure'),
        (user) {
          expect(user.id, 'user-uuid');
          expect(user.email, 'user@example.com');
          expect(user.name, 'Restored User');
          expect(user.income, 42000.0);
          expect(user.createdAt, isNotNull);
        },
      );

      expect(calledUri.toString(), '$_baseUrl/users/me');
      expect(
        authHeader,
        'Bearer $_token',
        reason: '/users/me ไม่ใช่ public path จึงต้องแนบ Bearer อัตโนมัติ',
      );
    });

    test('ไม่มี token → unauthorized ทันที โดยไม่ยิง network', () async {
      SharedPreferences.setMockInitialValues({});

      var requestCount = 0;
      final repository = RemoteAuthRepository(
        baseUrl: _baseUrl,
        client: MockClient((_) async {
          requestCount++;
          return _meEnvelope();
        }),
      );

      final result = await repository.getCurrentUser();

      result.fold(
        (failure) => expect(failure, const Failure.unauthorized()),
        (user) => fail('คาดว่า Left แต่ได้ Right: $user'),
      );
      expect(
        requestCount,
        0,
        reason: 'รู้อยู่แล้วว่าไม่มี session ไม่ต้องเสียเวลารอเน็ตตอนเปิดแอป',
      );
    });

    test('token เป็นสตริงว่าง ก็ถือว่าไม่มี session', () async {
      SharedPreferences.setMockInitialValues({'auth_token': ''});

      var requestCount = 0;
      final repository = RemoteAuthRepository(
        baseUrl: _baseUrl,
        client: MockClient((_) async {
          requestCount++;
          return _meEnvelope();
        }),
      );

      final result = await repository.getCurrentUser();

      result.fold(
        (failure) => expect(failure, const Failure.unauthorized()),
        (user) => fail('คาดว่า Left แต่ได้ Right: $user'),
      );
      expect(requestCount, 0);
    });

    test('token หมดอายุ (401) → unauthorized ไม่ใช่ networkError', () async {
      SharedPreferences.setMockInitialValues({'auth_token': 'expired-jwt'});

      final repository = RemoteAuthRepository(
        baseUrl: _baseUrl,
        client: MockClient((_) async => http.Response(
              jsonEncode({
                'success': false,
                'statusCode': 401,
                'timestamp': '2026-10-06T07:00:00.000Z',
                'path': '/users/me',
                'message': 'Unauthorized',
                'error': 'Unauthorized',
              }),
              401,
              headers: {'content-type': 'application/json; charset=utf-8'},
            )),
      );

      final result = await repository.getCurrentUser();

      result.fold(
        (failure) => expect(
          failure,
          const Failure.unauthorized(),
          reason: 'ผู้เรียกใช้ค่านี้ตัดสินใจล้าง token — ห้ามสับสนกับ networkError',
        ),
        (user) => fail('คาดว่า Left แต่ได้ Right: $user'),
      );
    });

    test('ต่อเน็ตไม่ติด → networkError (แยกจาก unauthorized ชัดเจน)', () async {
      SharedPreferences.setMockInitialValues({'auth_token': _token});

      final repository = RemoteAuthRepository(
        baseUrl: _baseUrl,
        client: MockClient((_) async {
          throw const _ConnectionRefused();
        }),
      );

      final result = await repository.getCurrentUser();

      result.fold(
        (failure) => expect(
          failure,
          const Failure.networkError(),
          reason: 'token อาจยังดีอยู่ แค่เน็ตมีปัญหา ⇒ ห้ามล้าง token',
        ),
        (user) => fail('คาดว่า Left แต่ได้ Right: $user'),
      );
    });

    test('500 → serverError (ไม่ใช่ unauthorized จึงไม่ล้าง token)', () async {
      SharedPreferences.setMockInitialValues({'auth_token': _token});

      final repository = RemoteAuthRepository(
        baseUrl: _baseUrl,
        client: MockClient((_) async => http.Response(
              jsonEncode({
                'success': false,
                'statusCode': 500,
                'message': 'Internal server error',
                'error': 'InternalServerError',
              }),
              500,
              headers: {'content-type': 'application/json; charset=utf-8'},
            )),
      );

      final result = await repository.getCurrentUser();

      result.fold(
        (failure) {
          expect(failure, isNot(const Failure.unauthorized()));
          expect(failure, isNot(const Failure.networkError()));
          expect(failure.displayMessage, contains('Internal server error'));
        },
        (user) => fail('คาดว่า Left แต่ได้ Right: $user'),
      );
    });

    test('body ที่ไม่มี envelope ก็ไม่ถูกนับว่าสำเร็จ', () async {
      SharedPreferences.setMockInitialValues({'auth_token': _token});

      final repository = RemoteAuthRepository(
        baseUrl: _baseUrl,
        client: MockClient((_) async => http.Response(
              jsonEncode({'id': 'user-uuid', 'email': 'user@example.com'}),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            )),
      );

      expect((await repository.getCurrentUser()).isLeft(), isTrue);
    });
  });

  group('InMemoryAuthRepository.getCurrentUser', () {
    test('ยังไม่ login → unauthorized', () async {
      final repository = InMemoryAuthRepository();

      final result = await repository.getCurrentUser();

      result.fold(
        (failure) => expect(failure, const Failure.unauthorized()),
        (user) => fail('คาดว่า Left แต่ได้ Right: $user'),
      );
    });

    test('login แล้ว → คืน user คนเดิม', () async {
      final repository = InMemoryAuthRepository();
      await repository.loginWithGoogle();

      final result = await repository.getCurrentUser();

      result.fold(
        (failure) => fail('คาดว่า Right แต่ได้ Left: $failure'),
        (user) => expect(user.id, 'mock-user-123'),
      );
    });

    test('logout แล้ว → กลับไป unauthorized', () async {
      final repository = InMemoryAuthRepository();
      await repository.loginWithGoogle();
      await repository.logout();

      expect((await repository.getCurrentUser()).isLeft(), isTrue);
    });
  });
}

class _ConnectionRefused implements Exception {
  const _ConnectionRefused();

  @override
  String toString() => 'SocketException: Connection refused';
}
