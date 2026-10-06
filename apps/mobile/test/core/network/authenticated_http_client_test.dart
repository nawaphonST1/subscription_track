import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:subscription_track/core/network/authenticated_http_client.dart';

/// เก็บ header ของ request ที่หลุดออกไปจริง เพื่อ assert ว่าแนบ/ไม่แนบถูกต้อง
class _Capture {
  Map<String, String>? headers;
  Uri? url;
  int callCount = 0;
}

MockClient _mockReturning(int statusCode, _Capture capture) {
  return MockClient((request) async {
    capture.headers = Map<String, String>.from(request.headers);
    capture.url = request.url;
    capture.callCount++;
    return http.Response('{}', statusCode);
  });
}

String? _authHeaderOf(_Capture capture) {
  final headers = capture.headers;
  if (headers == null) return null;
  for (final entry in headers.entries) {
    if (entry.key.toLowerCase() == 'authorization') return entry.value;
  }
  return null;
}

void main() {
  group('การแนบ Bearer token', () {
    test('แนบ token เมื่อมี token และไม่ใช่ public path', () async {
      final capture = _Capture();
      final client = AuthenticatedHttpClient(
        readToken: () async => 'jwt-abc',
        inner: _mockReturning(200, capture),
      );

      await client.get(Uri.parse('http://localhost:3000/subscriptions'));

      expect(_authHeaderOf(capture), 'Bearer jwt-abc');
    });

    test('ไม่ส่ง header เลยเมื่อไม่มี token (null)', () async {
      final capture = _Capture();
      final client = AuthenticatedHttpClient(
        readToken: () async => null,
        inner: _mockReturning(200, capture),
      );

      await client.get(Uri.parse('http://localhost:3000/subscriptions'));

      expect(_authHeaderOf(capture), isNull);
    });

    test('ไม่ส่ง header เมื่อ token เป็นสตริงว่าง', () async {
      final capture = _Capture();
      final client = AuthenticatedHttpClient(
        readToken: () async => '',
        inner: _mockReturning(200, capture),
      );

      await client.get(Uri.parse('http://localhost:3000/users/me'));

      expect(
        _authHeaderOf(capture),
        isNull,
        reason: 'ส่ง "Bearer " เปล่า ๆ จะได้ 401 ที่แยกสาเหตุไม่ออก',
      );
    });

    test('ไม่เขียนทับ Authorization ที่ caller ตั้งมาเอง', () async {
      final capture = _Capture();
      final client = AuthenticatedHttpClient(
        readToken: () async => 'jwt-from-storage',
        inner: _mockReturning(200, capture),
      );

      await client.get(
        Uri.parse('http://localhost:3000/users/me'),
        headers: {'Authorization': 'Bearer caller-supplied'},
      );

      expect(_authHeaderOf(capture), 'Bearer caller-supplied');
    });

    test('อ่าน token ใหม่ทุก request ไม่ cache ค่าเก่า', () async {
      final capture = _Capture();
      var current = 'first';
      final client = AuthenticatedHttpClient(
        readToken: () async => current,
        inner: _mockReturning(200, capture),
      );

      await client.get(Uri.parse('http://localhost:3000/users/me'));
      expect(_authHeaderOf(capture), 'Bearer first');

      current = 'second';
      await client.get(Uri.parse('http://localhost:3000/users/me'));
      expect(_authHeaderOf(capture), 'Bearer second');
    });
  });

  group('public path ข้ามการแนบ token', () {
    for (final path in kPublicAuthPaths) {
      test('$path ไม่แนบ token แม้จะมี token ค้างอยู่', () async {
        final capture = _Capture();
        final client = AuthenticatedHttpClient(
          readToken: () async => 'stale-jwt',
          inner: _mockReturning(200, capture),
        );

        await client.post(Uri.parse('http://localhost:3000$path'));

        expect(_authHeaderOf(capture), isNull);
      });
    }

    test('path ที่ไม่ได้อยู่ในรายการ public ยังแนบตามปกติ', () async {
      final capture = _Capture();
      final client = AuthenticatedHttpClient(
        readToken: () async => 'jwt-abc',
        inner: _mockReturning(200, capture),
      );

      await client.get(Uri.parse('http://localhost:3000/notifications'));

      expect(_authHeaderOf(capture), 'Bearer jwt-abc');
    });

    test('เทียบ path แบบตรงตัว ไม่ใช่ prefix', () async {
      final capture = _Capture();
      final client = AuthenticatedHttpClient(
        readToken: () async => 'jwt-abc',
        inner: _mockReturning(200, capture),
      );

      // ไม่ใช่ /auth/login จึงต้องแนบ token
      await client.get(Uri.parse('http://localhost:3000/auth/login/extra'));

      expect(_authHeaderOf(capture), 'Bearer jwt-abc');
    });

    test('inject ชุด publicPaths เองได้', () async {
      final capture = _Capture();
      final client = AuthenticatedHttpClient(
        readToken: () async => 'jwt-abc',
        inner: _mockReturning(200, capture),
        publicPaths: const {'/packages'},
      );

      await client.get(Uri.parse('http://localhost:3000/packages'));

      expect(_authHeaderOf(capture), isNull);
    });

    test('readToken ไม่ถูกเรียกเลยสำหรับ public path', () async {
      final capture = _Capture();
      var readCount = 0;
      final client = AuthenticatedHttpClient(
        readToken: () async {
          readCount++;
          return 'jwt-abc';
        },
        inner: _mockReturning(200, capture),
      );

      await client.post(Uri.parse('http://localhost:3000/auth/login'));

      expect(readCount, 0);
    });
  });

  group('สัญญาณ 401', () {
    test('ยิงเมื่อได้ 401 จาก path ที่ต้อง auth', () async {
      final capture = _Capture();
      var signals = 0;
      final client = AuthenticatedHttpClient(
        readToken: () async => 'expired-jwt',
        inner: _mockReturning(401, capture),
        onUnauthorized: () => signals++,
      );

      await client.get(Uri.parse('http://localhost:3000/subscriptions'));

      expect(signals, 1);
    });

    test('ไม่ยิงเมื่อ 401 มาจาก /auth/login (รหัสผ่านผิด ไม่ใช่ session หมดอายุ)',
        () async {
      final capture = _Capture();
      var signals = 0;
      final client = AuthenticatedHttpClient(
        readToken: () async => null,
        inner: _mockReturning(401, capture),
        onUnauthorized: () => signals++,
      );

      await client.post(Uri.parse('http://localhost:3000/auth/login'));

      expect(signals, 0);
    });

    test('ไม่ยิงสำหรับสถานะอื่น', () async {
      for (final status in [200, 201, 400, 403, 404, 409, 500]) {
        final capture = _Capture();
        var signals = 0;
        final client = AuthenticatedHttpClient(
          readToken: () async => 'jwt-abc',
          inner: _mockReturning(status, capture),
          onUnauthorized: () => signals++,
        );

        await client.get(Uri.parse('http://localhost:3000/subscriptions'));

        expect(signals, 0, reason: 'HTTP $status ไม่ควรยิงสัญญาณ 401');
      }
    });

    test('ยิงทุกครั้งที่เจอ 401 ไม่ใช่ครั้งเดียว', () async {
      final capture = _Capture();
      var signals = 0;
      final client = AuthenticatedHttpClient(
        readToken: () async => 'expired-jwt',
        inner: _mockReturning(401, capture),
        onUnauthorized: () => signals++,
      );

      await client.get(Uri.parse('http://localhost:3000/subscriptions'));
      await client.get(Uri.parse('http://localhost:3000/notifications'));

      expect(signals, 2);
    });

    test('ไม่ตั้ง onUnauthorized ก็ไม่พัง', () async {
      final capture = _Capture();
      final client = AuthenticatedHttpClient(
        readToken: () async => 'expired-jwt',
        inner: _mockReturning(401, capture),
      );

      final response =
          await client.get(Uri.parse('http://localhost:3000/subscriptions'));

      expect(response.statusCode, 401);
    });
  });

  group('ส่งต่อ request ตามเดิม', () {
    test('ไม่เปลี่ยน URL และยิง inner client ครั้งเดียว', () async {
      final capture = _Capture();
      final client = AuthenticatedHttpClient(
        readToken: () async => 'jwt-abc',
        inner: _mockReturning(200, capture),
      );

      await client.get(Uri.parse('http://localhost:3000/cards?limit=5'));

      expect(capture.url.toString(), 'http://localhost:3000/cards?limit=5');
      expect(capture.callCount, 1);
    });

    test('ส่ง body และ header อื่นผ่านไปครบ', () async {
      final capture = _Capture();
      String? seenBody;
      final client = AuthenticatedHttpClient(
        readToken: () async => 'jwt-abc',
        inner: MockClient((request) async {
          capture.headers = Map<String, String>.from(request.headers);
          seenBody = request.body;
          return http.Response('{}', 200);
        }),
      );

      await client.post(
        Uri.parse('http://localhost:3000/subscriptions'),
        headers: {'Content-Type': 'application/json'},
        body: '{"name":"Netflix"}',
      );

      expect(seenBody, '{"name":"Netflix"}');
      expect(_authHeaderOf(capture), 'Bearer jwt-abc');
    });
  });
}
