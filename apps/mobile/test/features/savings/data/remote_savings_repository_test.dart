import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:subscription_track/core/network/authenticated_http_client.dart';
import 'package:subscription_track/features/savings/data/remote_savings_repository.dart';

void main() {
  const testBaseUrl = 'http://localhost:3000';
  const testToken = 'valid-jwt-token-for-test';

  group('RemoteSavingsRepository.getOptimizerReport', () {
    test('successfully fetches and maps savings optimizer report with cards and projections', () async {
      http.Request? capturedRequest;

      final mockInner = MockClient((request) async {
        capturedRequest = request;
        return http.Response(
          jsonEncode({
            'success': true,
            'statusCode': 200,
            'data': {
              'unused_subscriptions_count': 2,
              'total_monthly_savings': 708.0,
              'total_yearly_savings_projection': 8496.0,
              'recommended_cancellations': [
                {
                  'id': 'sub-1',
                  'name': 'Netflix Premium',
                  'category': 'entertainment',
                  'price': 419.0,
                  'billing_cycle': 'MONTHLY',
                  'normalized_monthly_cost': 419.0,
                  'yearly_savings_projection': 5028.0,
                  'brand_color': '#E50914',
                  'payment_card': {
                    'card_nickname': 'Main Card',
                    'last_4_digits': '1234',
                    'bank_name': 'SCB',
                  },
                },
                {
                  'id': 'sub-2',
                  'name': 'Disney+ Hotstar',
                  'category': 'entertainment',
                  'price': 289.0,
                  'billing_cycle': 'MONTHLY',
                  'normalized_monthly_cost': 289.0,
                  'yearly_savings_projection': 3468.0,
                  'brand_color': null,
                  'payment_card': null,
                },
              ],
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final authClient = AuthenticatedHttpClient(
        readToken: () async => testToken,
        inner: mockInner,
      );

      final repo = RemoteSavingsRepository(
        client: authClient,
        baseUrl: testBaseUrl,
      );

      final report = await repo.getOptimizerReport();

      expect(capturedRequest, isNotNull);
      final req = capturedRequest!;
      expect(req.method, 'GET');
      expect(req.url.path, '/savings/optimizer');
      expect(req.headers['authorization'], 'Bearer $testToken');

      expect(report.unusedSubscriptionsCount, 2);
      expect(report.totalMonthlySavings, 708.0);
      expect(report.totalYearlySavingsProjection, 8496.0);
      expect(report.recommendedCancellations.length, 2);

      final item1 = report.recommendedCancellations[0];
      expect(item1.id, 'sub-1');
      expect(item1.name, 'Netflix Premium');
      expect(item1.billingCycle, 'monthly');
      expect(item1.normalizedMonthlyCost, 419.0);
      expect(item1.yearlySavingsProjection, 5028.0);
      expect(item1.brandColor, '#E50914');
      expect(item1.paymentCard, isNotNull);
      expect(item1.paymentCard!.displayName, 'Main Card (•• 1234)');

      final item2 = report.recommendedCancellations[1];
      expect(item2.id, 'sub-2');
      expect(item2.paymentCard, isNull);
    });

    test('throws SavingsException when server returns error envelope', () async {
      final mockInner = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'statusCode': 500,
            'message': 'Internal Server Error',
          }),
          500,
          headers: {'content-type': 'application/json'},
        );
      });

      final authClient = AuthenticatedHttpClient(
        readToken: () async => testToken,
        inner: mockInner,
      );

      final repo = RemoteSavingsRepository(
        client: authClient,
        baseUrl: testBaseUrl,
      );

      expect(
        () => repo.getOptimizerReport(),
        throwsA(isA<SavingsException>()),
      );
    });
  });

  group('RemoteSavingsRepository.batchCancel', () {
    test('successfully posts batch cancel payload and returns confirmation', () async {
      http.Request? capturedRequest;

      final mockInner = MockClient((request) async {
        capturedRequest = request;
        return http.Response(
          jsonEncode({
            'success': true,
            'statusCode': 200,
            'data': {
              'message': 'Subscriptions successfully cancelled',
              'cancelled_count': 2,
              'total_yearly_savings_unlocked': 8496.0,
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final authClient = AuthenticatedHttpClient(
        readToken: () async => testToken,
        inner: mockInner,
      );

      final repo = RemoteSavingsRepository(
        client: authClient,
        baseUrl: testBaseUrl,
      );

      final result = await repo.batchCancel(
        subscriptionIds: ['sub-1', 'sub-2'],
        pin: '123456',
      );

      expect(capturedRequest, isNotNull);
      final req = capturedRequest!;
      expect(req.method, 'POST');
      expect(req.url.path, '/savings/batch-cancel');
      expect(req.headers['authorization'], 'Bearer $testToken');

      final body = jsonDecode(req.body) as Map<String, dynamic>;
      expect(body['subscription_ids'], ['sub-1', 'sub-2']);
      expect(body['security_pin'], '123456');

      expect(result.cancelledCount, 2);
      expect(result.totalYearlySavingsUnlocked, 8496.0);
    });

    test('throws InvalidPinException on 403 Forbidden with invalid PIN', () async {
      final mockInner = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'statusCode': 403,
            'message': 'Invalid 6-digit security PIN',
          }),
          403,
          headers: {'content-type': 'application/json'},
        );
      });

      final authClient = AuthenticatedHttpClient(
        readToken: () async => testToken,
        inner: mockInner,
      );

      final repo = RemoteSavingsRepository(
        client: authClient,
        baseUrl: testBaseUrl,
      );

      expect(
        () => repo.batchCancel(subscriptionIds: ['sub-1'], pin: '999999'),
        throwsA(
          isA<InvalidPinException>().having(
            (e) => e.message,
            'message',
            'Invalid 6-digit security PIN',
          ),
        ),
      );
    });

    test('throws PinLockoutException on 429 Too Many Requests with wait message', () async {
      final mockInner = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'statusCode': 429,
            'message': 'Too many failed PIN attempts. Please wait 45 seconds before retrying.',
          }),
          429,
          headers: {'content-type': 'application/json'},
        );
      });

      final authClient = AuthenticatedHttpClient(
        readToken: () async => testToken,
        inner: mockInner,
      );

      final repo = RemoteSavingsRepository(
        client: authClient,
        baseUrl: testBaseUrl,
      );

      expect(
        () => repo.batchCancel(subscriptionIds: ['sub-1'], pin: '000000'),
        throwsA(
          isA<PinLockoutException>().having(
            (e) => e.message,
            'message',
            contains('Too many failed PIN attempts. Please wait 45 seconds'),
          ),
        ),
      );
    });
  });
}
