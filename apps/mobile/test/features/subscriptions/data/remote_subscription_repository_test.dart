import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:subscription_track/core/network/authenticated_http_client.dart';
import 'package:subscription_track/features/subscriptions/data/remote_subscription_repository.dart';
import 'package:subscription_track/features/subscriptions/domain/subscription_repository.dart';

void main() {
  const testBaseUrl = 'http://localhost:3000';
  const testToken = 'valid-jwt-token-for-test';
  const testSubscriptionId = 'sub-test-uuid-123';
  const testPin = '482910';

  group('RemoteSubscriptionRepository.deleteSubscription', () {
    test(
        'constructs DELETE /subscriptions/:id with x-security-pin header and Authorization Bearer',
        () async {
      http.Request? capturedRequest;

      final mockInner = MockClient((request) async {
        capturedRequest = request;
        return http.Response(
          jsonEncode({
            'success': true,
            'statusCode': 200,
            'data': {'message': 'Subscription deleted successfully'},
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final authClient = AuthenticatedHttpClient(
        readToken: () async => testToken,
        inner: mockInner,
      );

      final repository = RemoteSubscriptionRepository(
        client: authClient,
        baseUrl: testBaseUrl,
      );

      await repository.deleteSubscription(testSubscriptionId, pin: testPin);

      expect(capturedRequest, isNotNull);
      final req = capturedRequest!;

      // 1. HTTP Method
      expect(req.method, 'DELETE');

      // 2. Path
      expect(req.url.path, '/subscriptions/$testSubscriptionId');

      // 3. Header x-security-pin
      expect(req.headers['x-security-pin'], testPin);

      // 4. Authorization Bearer header
      expect(req.headers['Authorization'], 'Bearer $testToken');

      // 5. PIN is NOT transmitted in URL or query parameters
      expect(req.url.toString(), isNot(contains(testPin)));
      expect(req.url.queryParameters.values, isNot(contains(testPin)));
      expect(req.url.hasQuery, isFalse);
    });

    test('omits x-security-pin header when pin parameter is null', () async {
      http.Request? capturedRequest;

      final mockInner = MockClient((request) async {
        capturedRequest = request;
        return http.Response(
          jsonEncode({
            'success': true,
            'statusCode': 200,
            'data': {'message': 'deleted'},
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final authClient = AuthenticatedHttpClient(
        readToken: () async => testToken,
        inner: mockInner,
      );

      final repository = RemoteSubscriptionRepository(
        client: authClient,
        baseUrl: testBaseUrl,
      );

      await repository.deleteSubscription(testSubscriptionId);

      expect(capturedRequest, isNotNull);
      expect(capturedRequest!.headers.containsKey('x-security-pin'), isFalse);
    });

    test('throws SubscriptionNotFoundException on HTTP 404', () async {
      final mockInner = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'statusCode': 404,
            'message': 'Subscription not found',
          }),
          404,
          headers: {'content-type': 'application/json'},
        );
      });

      final repository = RemoteSubscriptionRepository(
        client: mockInner,
        baseUrl: testBaseUrl,
      );

      expect(
        () => repository.deleteSubscription('nonexistent-id', pin: testPin),
        throwsA(isA<SubscriptionNotFoundException>()),
      );
    });

    test('throws Exception on HTTP 400 or 403 when PIN is rejected', () async {
      final mockInner = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'statusCode': 403,
            'message': 'Invalid security PIN',
          }),
          403,
          headers: {'content-type': 'application/json'},
        );
      });

      final repository = RemoteSubscriptionRepository(
        client: mockInner,
        baseUrl: testBaseUrl,
      );

      expect(
        () => repository.deleteSubscription(testSubscriptionId, pin: '000000'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
