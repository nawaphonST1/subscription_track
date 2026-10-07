import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:subscription_track/core/network/authenticated_http_client.dart';
import 'package:subscription_track/features/dashboard/data/remote_creep_score_repository.dart';

void main() {
  const testBaseUrl = 'http://localhost:3000';
  const testToken = 'valid-jwt-token-for-test';

  group('RemoteCreepScoreRepository.getCreepScore', () {
    test('successfully fetches and maps creep score report from backend', () async {
      http.Request? capturedRequest;

      final mockInner = MockClient((request) async {
        capturedRequest = request;
        return http.Response(
          jsonEncode({
            'success': true,
            'statusCode': 200,
            'data': {
              'monthly_total': 1250.0,
              'creep_score': 15.5,
              'risk_level': 'CAUTION',
              'monthly_income': 50000.0,
              'total_card_funds': 20000.0,
              'denominator_used': 'monthly_income',
              'active_subscriptions_count': 3,
              'category_breakdown': [
                {
                  'category': 'entertainment',
                  'amount': 700.0,
                  'percentage': 56.0,
                },
                {
                  'category': 'work',
                  'amount': 550.0,
                  'percentage': 44.0,
                },
              ],
              'upcoming_renewals': [
                {
                  'id': 'sub-1',
                  'name': 'Netflix',
                  'category': 'entertainment',
                  'price': 419.0,
                  'billing_cycle': 'MONTHLY',
                  'next_renewal_date': '2026-10-15T00:00:00.000Z',
                  'days_until_renewal': 8,
                  'card_nickname': 'Main Card',
                  'last_4_digits': '1234',
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

      final repository = RemoteCreepScoreRepository(
        client: authClient,
        baseUrl: testBaseUrl,
      );

      final report = await repository.getCreepScore();

      expect(capturedRequest, isNotNull);
      final req = capturedRequest!;
      expect(req.method, 'GET');
      expect(req.url.path, '/creep-score');
      expect(req.headers['authorization'], 'Bearer $testToken');

      expect(report.monthlyTotal, 1250.0);
      expect(report.creepScore, 15.5);
      expect(report.riskLevel, 'CAUTION');
      expect(report.monthlyIncome, 50000.0);
      expect(report.totalCardFunds, 20000.0);
      expect(report.denominatorUsed, 'monthly_income');
      expect(report.activeSubscriptionsCount, 3);

      expect(report.categoryBreakdown.length, 2);
      expect(report.categoryBreakdown[0].category, 'entertainment');
      expect(report.categoryBreakdown[0].amount, 700.0);
      expect(report.categoryBreakdown[0].percentage, 56.0);

      expect(report.upcomingRenewals.length, 1);
      final renewal = report.upcomingRenewals[0];
      expect(renewal.id, 'sub-1');
      expect(renewal.name, 'Netflix');
      expect(renewal.price, 419.0);
      expect(renewal.daysUntilRenewal, 8);
      expect(renewal.cardNickname, 'Main Card');
      expect(renewal.last4Digits, '1234');
      expect(renewal.nextBillingDate, isNotNull);
    });

    test('throws exception when backend returns error envelope', () async {
      final mockInner = MockClient((request) async {
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

      final authClient = AuthenticatedHttpClient(
        readToken: () async => testToken,
        inner: mockInner,
      );

      final repository = RemoteCreepScoreRepository(
        client: authClient,
        baseUrl: testBaseUrl,
      );

      expect(
        () => repository.getCreepScore(),
        throwsA(isA<Exception>()),
      );
    });
  });
}
