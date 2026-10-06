import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:subscription_track/core/network/authenticated_http_client.dart';
import 'package:subscription_track/features/subscriptions/data/remote_subscription_repository.dart';
import 'package:subscription_track/features/subscriptions/domain/subscription.dart';
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

  group('RemoteSubscriptionRepository.addSubscription', () {
    test(
        'sends snake_case payload with uppercase enums and payment_card_id, '
        'not the raw generated toJson() shape', () async {
      Map<String, dynamic>? capturedBody;

      final mockInner = MockClient((request) async {
        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({
            'success': true,
            'statusCode': 201,
            'data': {'id': 'new-sub-id'},
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
      });

      final repository = RemoteSubscriptionRepository(
        client: mockInner,
        baseUrl: testBaseUrl,
      );

      await repository.addSubscription(const Subscription(
        id: 'local-temp-id',
        name: 'Netflix Premium',
        price: 419,
        category: 'Streaming',
        billingPeriod: 'monthly',
        usageStatus: 'moderate',
        paymentCardId: 'card-uuid-1',
        // local-only fields that must NOT be sent (backend rejects unknown
        // properties via forbidNonWhitelisted: true)
        isSelected: true,
        confidence: 77,
        reminderEnabled: false,
      ));

      expect(capturedBody!['payment_card_id'], 'card-uuid-1');
      expect(capturedBody!['name'], 'Netflix Premium');
      expect(capturedBody!['category'], 'Streaming');
      expect(capturedBody!['billing_cycle'], 'MONTHLY');
      expect(capturedBody!['usage_status'], 'OCCASIONAL');
      // local-only / client-side fields must never reach the wire
      for (final key in [
        'isSelected',
        'confidence',
        'reminderEnabled',
        'customFields',
        'id',
      ]) {
        expect(capturedBody!.containsKey(key), isFalse,
            reason: '"$key" has no backend column and must be stripped');
      }
    });

    test('throws ArgumentError when paymentCardId is missing, before even '
        'calling the backend', () async {
      var called = false;
      final mockInner = MockClient((request) async {
        called = true;
        return http.Response('{}', 200);
      });

      final repository = RemoteSubscriptionRepository(
        client: mockInner,
        baseUrl: testBaseUrl,
      );

      expect(
        () => repository.addSubscription(const Subscription(
          id: 'x',
          name: 'No Card',
          price: 1,
        )),
        throwsArgumentError,
      );
      expect(called, isFalse);
    });
  });

  group('RemoteSubscriptionRepository field mapping (GET)', () {
    test('maps snake_case + nested payment_card.id + uppercase enums back to '
        'the Dart model', () async {
      final mockInner = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'statusCode': 200,
            'data': [
              {
                'id': 'sub-1',
                'name': 'Spotify Premium',
                'category': 'Music',
                'price': 139,
                'billing_cycle': 'YEARLY',
                'next_renewal_date': '2026-11-06T19:07:17.944Z',
                'usage_status': 'OCCASIONAL',
                'status': 'ACTIVE',
                'payment_card': {
                  'id': 'card-uuid-1',
                  'bank_name': 'Kasikornbank',
                },
                'created_at': '2026-10-06T19:07:17.948Z',
                'updated_at': '2026-10-06T19:07:17.948Z',
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final repository = RemoteSubscriptionRepository(
        client: mockInner,
        baseUrl: testBaseUrl,
      );

      final subscriptions = await repository.getSubscriptions();

      expect(subscriptions, hasLength(1));
      final sub = subscriptions[0];
      expect(sub.id, 'sub-1');
      expect(sub.billingPeriod, 'yearly');
      expect(sub.usageStatus, 'moderate'); // OCCASIONAL -> moderate
      expect(sub.paymentCardId, 'card-uuid-1'); // pulled from nested object
      expect(sub.createdAt, isNotNull);
    });

    test(
        'a WEEKLY subscription (no UI entry point yet, but a real backend '
        'BillingCycle value) parses fine and does not fail the whole list — '
        'e.g. seeded data, an admin action, or a future UI change', () async {
      final mockInner = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'statusCode': 200,
            'data': [
              {
                'id': 'sub-monthly',
                'name': 'Netflix',
                'category': 'Streaming',
                'price': 419,
                'billing_cycle': 'MONTHLY',
                'usage_status': 'FREQUENT',
                'status': 'ACTIVE',
              },
              {
                'id': 'sub-weekly',
                'name': 'Weekly Meal Kit',
                'category': 'Food',
                'price': 350,
                'billing_cycle': 'WEEKLY',
                'usage_status': 'FREQUENT',
                'status': 'ACTIVE',
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final repository = RemoteSubscriptionRepository(
        client: mockInner,
        baseUrl: testBaseUrl,
      );

      final subscriptions = await repository.getSubscriptions();

      expect(subscriptions, hasLength(2));
      expect(
        subscriptions.firstWhere((s) => s.id == 'sub-weekly').billingPeriod,
        'weekly',
      );
    });

    test(
        'a genuinely corrupt/unmappable billing_cycle (not in the backend '
        "enum at all) fails the WHOLE list, not just that one item — that's "
        'the correct, intentional behavior for truly invalid data', () async {
      final mockInner = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'statusCode': 200,
            'data': [
              {
                'id': 'sub-ok',
                'name': 'Netflix',
                'category': 'Streaming',
                'price': 419,
                'billing_cycle': 'MONTHLY',
                'usage_status': 'FREQUENT',
                'status': 'ACTIVE',
              },
              {
                'id': 'sub-corrupt',
                'name': 'Corrupted Row',
                'category': 'Other',
                'price': 1,
                'billing_cycle': 'DAILY', // not a real backend enum value
                'usage_status': 'FREQUENT',
                'status': 'ACTIVE',
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final repository = RemoteSubscriptionRepository(
        client: mockInner,
        baseUrl: testBaseUrl,
      );

      // The valid 'sub-ok' item does NOT come back as a partial 1-item list —
      // the whole call throws, surfacing the corruption loudly instead of
      // silently hiding one user's subscription.
      expect(() => repository.getSubscriptions(), throwsException);
    });
  });
}
