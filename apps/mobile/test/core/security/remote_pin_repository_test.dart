import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:subscription_track/core/errors/failures.dart';
import 'package:subscription_track/core/network/authenticated_http_client.dart';
import 'package:subscription_track/core/security/remote_pin_repository.dart';

void main() {
  const testBaseUrl = 'http://localhost:3000';
  const testValidPin = '123456';
  const testInvalidPin = '999999';
  const testOldPin = '234567';
  const testNewPin = '345678';

  group('RemotePinRepository.verifyPin', () {
    test('returns Right(true) when server confirms PIN is valid', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/users/verify-pin');
        expect(request.method, 'POST');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['pin'], testValidPin);

        return http.Response(
          jsonEncode({
            'success': true,
            'statusCode': 200,
            'data': {'valid': true},
            'timestamp': '2026-10-06T12:00:00.000Z',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final repository = RemotePinRepository(
        client: mockClient,
        baseUrl: testBaseUrl,
      );

      final result = await repository.verifyPin(testValidPin);

      expect(result.isRight(), isTrue);
      result.match(
        (failure) => fail('Expected Right but got Left($failure)'),
        (isValid) => expect(isValid, isTrue),
      );
    });

    test('returns Right(false) when server indicates PIN is incorrect', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/users/verify-pin');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['pin'], testInvalidPin);

        return http.Response(
          jsonEncode({
            'success': true,
            'statusCode': 200,
            'data': {'valid': false},
            'timestamp': '2026-10-06T12:00:00.000Z',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final repository = RemotePinRepository(
        client: mockClient,
        baseUrl: testBaseUrl,
      );

      final result = await repository.verifyPin(testInvalidPin);

      expect(result.isRight(), isTrue);
      result.match(
        (failure) => fail('Expected Right but got Left($failure)'),
        (isValid) => expect(isValid, isFalse),
      );
    });

    test('returns Left(Failure.networkError) on network exception', () async {
      final mockClient = MockClient((request) async {
        throw http.ClientException('Connection failed');
      });

      final repository = RemotePinRepository(
        client: mockClient,
        baseUrl: testBaseUrl,
      );

      final result = await repository.verifyPin(testValidPin);

      expect(result.isLeft(), isTrue);
      result.match(
        (failure) => expect(failure, const Failure.networkError()),
        (_) => fail('Expected Left but got Right'),
      );
    });

    test('returns Left(Failure.serverError) on HTTP 500 error', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'statusCode': 500,
            'message': 'Internal server error',
          }),
          500,
          headers: {'content-type': 'application/json'},
        );
      });

      final repository = RemotePinRepository(
        client: mockClient,
        baseUrl: testBaseUrl,
      );

      final result = await repository.verifyPin(testValidPin);

      expect(result.isLeft(), isTrue);
      result.match(
        (failure) => expect(
          failure,
          isA<Failure>().having(
            (f) => f.displayMessage,
            'displayMessage',
            contains('Internal server error'),
          ),
        ),
        (_) => fail('Expected Left but got Right'),
      );
    });
    test('returns Left(Failure.serverError("รหัส PIN ไม่ถูกต้อง")) on HTTP 401 unauthorized', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'statusCode': 401,
            'message': 'Unauthorized',
          }),
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      final repository = RemotePinRepository(
        client: mockClient,
        baseUrl: testBaseUrl,
      );

      final result = await repository.verifyPin(testValidPin);

      expect(result.isLeft(), isTrue);
      result.match(
        (failure) {
          expect(failure, const Failure.serverError('รหัส PIN ไม่ถูกต้อง'));
          expect(failure.displayMessage, 'รหัส PIN ไม่ถูกต้อง');
          expect(failure.displayMessage, isNot(contains('อีเมลหรือรหัสผ่าน')));
        },
        (_) => fail('Expected Left but got Right'),
      );
    });
  });

  group('RemotePinRepository.changePin', () {
    test('returns Right(unit) on HTTP 200 success', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/users/pin');
        expect(request.method, 'PATCH');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['current_pin'], testOldPin);
        expect(body['new_pin'], testNewPin);

        return http.Response(
          jsonEncode({
            'success': true,
            'statusCode': 200,
            'data': {'message': 'Security PIN changed successfully'},
            'timestamp': '2026-10-06T12:00:00.000Z',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final repository = RemotePinRepository(
        client: mockClient,
        baseUrl: testBaseUrl,
      );

      final result = await repository.changePin(
        currentPin: testOldPin,
        newPin: testNewPin,
      );

      expect(result.isRight(), isTrue);
      result.match(
        (failure) => fail('Expected Right but got Left($failure)'),
        (val) => expect(val, unit),
      );
    });

    test('wrong-PIN-as-401 does NOT trigger onUnauthorized logout callback and returns PIN error', () async {
      var unauthorizedCallCount = 0;
      final authClient = AuthenticatedHttpClient(
        readToken: () async => 'jwt-test-token',
        inner: MockClient((request) async {
          expect(request.url.path, '/users/pin');
          return http.Response(
            jsonEncode({
              'success': false,
              'statusCode': 401,
              'message': 'Current security PIN is incorrect',
              'error': 'Unauthorized',
            }),
            401,
            headers: {'content-type': 'application/json'},
          );
        }),
        onUnauthorized: () => unauthorizedCallCount++,
      );

      final repository = RemotePinRepository(
        client: authClient,
        baseUrl: testBaseUrl,
      );

      final result = await repository.changePin(
        currentPin: testOldPin,
        newPin: testNewPin,
      );

      expect(result.isLeft(), isTrue);
      result.match(
        (failure) {
          expect(failure, const Failure.serverError('รหัส PIN ไม่ถูกต้อง'));
          expect(failure.displayMessage, 'รหัส PIN ไม่ถูกต้อง');
          expect(failure.displayMessage, isNot(contains('อีเมลหรือรหัสผ่าน')));
        },
        (_) => fail('Expected Left but got Right'),
      );
      expect(
        unauthorizedCallCount,
        0,
        reason: 'Wrong PIN on /users/pin must be exempt from logging out the user',
      );
    });

    test('returns Left(Failure.networkError) on network exception', () async {
      final mockClient = MockClient((request) async {
        throw http.ClientException('Network down');
      });

      final repository = RemotePinRepository(
        client: mockClient,
        baseUrl: testBaseUrl,
      );

      final result = await repository.changePin(
        currentPin: testOldPin,
        newPin: testNewPin,
      );

      expect(result.isLeft(), isTrue);
      result.match(
        (failure) => expect(failure, const Failure.networkError()),
        (_) => fail('Expected Left but got Right'),
      );
    });

    test('returns Left(Failure.serverError) on HTTP 500 error', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'statusCode': 500,
            'message': 'Database failure',
          }),
          500,
          headers: {'content-type': 'application/json'},
        );
      });

      final repository = RemotePinRepository(
        client: mockClient,
        baseUrl: testBaseUrl,
      );

      final result = await repository.changePin(
        currentPin: testOldPin,
        newPin: testNewPin,
      );

      expect(result.isLeft(), isTrue);
      result.match(
        (failure) => expect(
          failure,
          isA<Failure>().having(
            (f) => f.displayMessage,
            'displayMessage',
            contains('Database failure'),
          ),
        ),
        (_) => fail('Expected Left but got Right'),
      );
    });
  });
}
