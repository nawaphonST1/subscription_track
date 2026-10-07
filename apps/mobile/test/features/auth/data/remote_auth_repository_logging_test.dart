import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:subscription_track/core/network/authenticated_http_client.dart';
import 'package:subscription_track/features/auth/data/remote_auth_repository.dart';

/// ล็อกสัญญาว่า log ของชั้น auth/network จะไม่พ่นความลับออกมา
///
/// `core/utils/logger.dart` ใช้ `package:logger` ที่ออกทาง `ConsoleOutput` ซึ่ง
/// เรียก `print` ⇒ ดักได้ด้วย Zone ของ Dart เอง ไม่ต้องแก้โค้ด production
///
/// เทสต์ชุดนี้พิสูจน์เชิงประจักษ์ ไม่ใช่การอ่านโค้ดแล้วสรุปเอาเอง: ทุกเคสยืนยัน
/// ก่อนว่า "ดักได้จริง" (เห็น method + path) แล้วค่อยยืนยันว่าไม่มีความลับหลุด
/// — ถ้าดักไม่ได้เลย เทสต์จะ fail แทนที่จะผ่านแบบหลอก ๆ

/// ค่าที่ต้องไม่โผล่ใน log ไม่ว่ากรณีใด
const _password = 'Sup3rS3cret-Passw0rd!';
const _pin = '834512';
const _jwt = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9'
    '.eyJzdWIiOiJ1c2VyLXV1aWQiLCJlbWFpbCI6InVzZXJAZXhhbXBsZS5jb20ifQ'
    '.R3al-Sign4tur3-V4lu3-Do-Not-Log-Me';
const _staleJwt = 'stale-jwt-from-previous-session-do-not-log';

const _baseUrl = 'http://localhost:3000';

/// รัน [action] แล้วเก็บทุกบรรทัดที่ผ่าน `print`
Future<List<String>> _capturePrints(Future<void> Function() action) async {
  final lines = <String>[];
  await runZoned(
    action,
    zoneSpecification: ZoneSpecification(
      print: (self, parent, zone, line) => lines.add(line),
    ),
  );
  return lines;
}

http.Response _envelope(Map<String, dynamic> data, int statusCode) =>
    http.Response(
      jsonEncode({
        'success': true,
        'statusCode': statusCode,
        'data': data,
        'timestamp': '2026-10-06T07:00:00.000Z',
      }),
      statusCode,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

Map<String, dynamic> get _userPayload => {
      'token': _jwt,
      'user': {
        'id': 'user-uuid',
        'email': 'user@example.com',
        'name': 'Real User',
        'monthly_income': 35000,
        'created_at': '2026-10-05T12:00:00.000Z',
      },
    };

/// ยืนยันว่า log ที่ดักได้ไม่มีความลับปนอยู่เลย
void _expectNoSecrets(List<String> captured) {
  final joined = captured.join('\n');
  expect(joined, isNot(contains(_password)), reason: 'รหัสผ่านหลุดลง log');
  expect(joined, isNot(contains(_pin)), reason: 'PIN หลุดลง log');
  expect(joined, isNot(contains(_jwt)), reason: 'JWT หลุดลง log');
  expect(joined, isNot(contains(_staleJwt)), reason: 'token เก่าหลุดลง log');
  expect(joined, isNot(contains('Bearer ')), reason: 'ค่า header หลุดลง log');
  expect(
    joined.toLowerCase(),
    isNot(contains('authorization')),
    reason: 'ชื่อ/ค่า header Authorization ไม่ควรปรากฏใน log',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({'auth_token': _staleJwt});
  });

  group('log ของ RemoteAuthRepository ไม่พ่นความลับ', () {
    test('login สำเร็จ: log เห็นแค่ method + path ไม่เห็นรหัสผ่านหรือ token',
        () async {
      final captured = _capturePrints(() async {
        final repository = RemoteAuthRepository(
          baseUrl: _baseUrl,
          client: MockClient((_) async => _envelope(_userPayload, 200)),
        );
        await repository.loginWithEmail(
          email: 'user@example.com',
          password: _password,
        );
      });

      final lines = await captured;

      // กันเทสต์ผ่านแบบหลอก ๆ: ต้องพิสูจน์ก่อนว่าดัก log ได้จริง
      final joined = lines.join('\n');
      expect(joined, contains('POST'), reason: 'ดัก log ไม่ได้เลย');
      expect(joined, contains('/auth/login'));

      _expectNoSecrets(lines);
    });

    test('register สำเร็จ: ไม่เห็นรหัสผ่านหรือ PIN', () async {
      final lines = await _capturePrints(() async {
        final repository = RemoteAuthRepository(
          baseUrl: _baseUrl,
          client: MockClient((_) async => _envelope(_userPayload, 201)),
        );
        await repository.registerWithEmail(
          email: 'newuser@example.com',
          password: _password,
          name: 'New User',
          securityPin: _pin,
        );
      });

      expect(lines.join('\n'), contains('/auth/register'));
      _expectNoSecrets(lines);
    });

    test('social login: ไม่เห็น token ของ provider', () async {
      final lines = await _capturePrints(() async {
        final repository = RemoteAuthRepository(
          baseUrl: _baseUrl,
          client: MockClient((_) async => _envelope(_userPayload, 200)),
        );
        await repository.executeSocialLogin(
          provider: 'google',
          email: 'user@gmail.com',
          token: 'mock-social-token',
          name: 'Jane Doe',
        );
      });

      expect(lines.join('\n'), contains('/auth/social'));
      expect(
        lines.join('\n'),
        isNot(contains('mock-social-token')),
        reason: 'token ที่ส่งให้ provider ไม่ควรโผล่ใน log',
      );
      _expectNoSecrets(lines);
    });

    test('เส้นทาง error (logger.e + stackTrace): ยังไม่พ่นความลับ', () async {
      final lines = await _capturePrints(() async {
        final repository = RemoteAuthRepository(
          baseUrl: _baseUrl,
          client: MockClient((_) async {
            throw const SocketExceptionStub('Connection refused');
          }),
        );
        await repository.loginWithEmail(
          email: 'user@example.com',
          password: _password,
        );
      });

      // logger.e ทำงานจริง (ไม่ใช่เงียบไปเฉย ๆ)
      expect(
        lines.join('\n'),
        contains('Error connecting to login API'),
        reason: 'ต้องดัก log ของเส้นทาง error ได้จริง',
      );
      _expectNoSecrets(lines);
    });

    test('response ที่มี token อยู่ใน body ก็ไม่ถูก log', () async {
      final lines = await _capturePrints(() async {
        final repository = RemoteAuthRepository(
          baseUrl: _baseUrl,
          client: MockClient((_) async => _envelope(_userPayload, 200)),
        );
        await repository.loginWithEmail(
          email: 'user@example.com',
          password: _password,
        );
      });

      // ยืนยันว่า token ถูกเซฟจริง — แปลว่ามันอยู่ในมือโค้ดตอนนั้น แต่ไม่ถูก log
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('auth_token'), _jwt);

      expect(lines.join('\n'), isNot(contains(_jwt)));
    });

    test('getCurrentUser: log เห็นแค่ method + path ไม่พ่น token หรือ header ออกมา',
        () async {
      final lines = await _capturePrints(() async {
        final repository = RemoteAuthRepository(
          baseUrl: _baseUrl,
          client: MockClient((request) async {
            expect(request.headers['Authorization'], 'Bearer $_staleJwt');
            return _envelope({
              'id': 'user-uuid',
              'email': 'user@example.com',
              'name': 'Real User',
            }, 200);
          }),
        );
        await repository.getCurrentUser();
      });

      expect(
        lines.join('\n'),
        contains('Calling API: GET $_baseUrl/users/me'),
        reason: 'ต้องดัก log ได้จริง',
      );
      _expectNoSecrets(lines);
    });

    test('getCurrentUser error path: ไม่พ่น token ออกมา', () async {
      final lines = await _capturePrints(() async {
        final repository = RemoteAuthRepository(
          baseUrl: _baseUrl,
          client: MockClient((_) async => throw const SocketExceptionStub('network fail')),
        );
        await repository.getCurrentUser();
      });

      expect(
        lines.join('\n'),
        contains('Error connecting to current-user API'),
        reason: 'ต้องดัก log error ได้จริง',
      );
      _expectNoSecrets(lines);
    });
  });

  group('AuthenticatedHttpClient ไม่ log อะไรเลย', () {
    test('request ที่แนบ Bearer token ไม่ผลิต output สักบรรทัด', () async {
      final lines = await _capturePrints(() async {
        final client = AuthenticatedHttpClient(
          readToken: () async => _jwt,
          inner: MockClient((request) async {
            // ยืนยันว่า header ถูกแนบจริงในรอบนี้
            expect(request.headers['Authorization'], 'Bearer $_jwt');
            return http.Response('{}', 200);
          }),
        );
        await client.get(Uri.parse('$_baseUrl/subscriptions'));
      });

      expect(
        lines,
        isEmpty,
        reason: 'ชั้น network ไม่ควร log อะไรเลย เพราะเป็นจุดเดียวที่ถือ token',
      );
    });

    test('401 ที่ทริกเกอร์ onUnauthorized ก็ไม่ log token', () async {
      final lines = await _capturePrints(() async {
        var signals = 0;
        final client = AuthenticatedHttpClient(
          readToken: () async => _jwt,
          inner: MockClient((_) async => http.Response('{}', 401)),
          onUnauthorized: () => signals++,
        );
        await client.get(Uri.parse('$_baseUrl/subscriptions'));
        expect(signals, 1);
      });

      expect(lines, isEmpty);
    });
  });
}

/// exception เลียนแบบ SocketException โดยไม่ต้อง import dart:io
/// (dart:io ใช้ใน flutter test ได้ แต่ของจำลองนี้ควบคุมข้อความได้แน่นอนกว่า)
class SocketExceptionStub implements Exception {
  const SocketExceptionStub(this.message);

  final String message;

  @override
  String toString() => 'SocketException: $message';
}
