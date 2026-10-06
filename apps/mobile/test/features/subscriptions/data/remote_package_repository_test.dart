import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:subscription_track/core/network/authenticated_http_client.dart';
import 'package:subscription_track/features/subscriptions/data/remote_package_repository.dart';
import 'package:subscription_track/features/subscriptions/domain/preset_package.dart';

void main() {
  const testBaseUrl = 'http://localhost:3000';
  const testToken = 'valid-jwt-token-for-test';

  group('RemotePackageRepository.getPackages', () {
    test('successfully fetches and maps preset packages list with query params', () async {
      http.Request? capturedRequest;

      final mockInner = MockClient((request) async {
        capturedRequest = request;
        return http.Response(
          jsonEncode({
            'success': true,
            'statusCode': 200,
            'data': [
              {
                'id': 'pkg-1',
                'name': 'Netflix Premium',
                'category': 'entertainment',
                'default_price': 419,
                'billing_cycle': 'MONTHLY',
                'brand_color': '#E50914',
                'icon_url': 'https://example.com/netflix.png',
                'description': 'Watch in 4K UHD',
              },
              {
                'id': 'pkg-2',
                'name': 'Disney+ Hotstar',
                'category': 'ENTERTAINMENT',
                'default_price': 289,
                'billing_cycle': 'YEARLY',
                'brand_color': '#0063E5',
                'icon_url': null,
                'description': null,
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final authClient = AuthenticatedHttpClient(
        readToken: () async => testToken,
        inner: mockInner,
      );

      final repository = RemotePackageRepository(
        client: authClient,
        baseUrl: testBaseUrl,
      );

      final packages = await repository.getPackages(
        category: 'entertainment',
        search: 'net',
      );

      expect(capturedRequest, isNotNull);
      final req = capturedRequest!;
      expect(req.method, 'GET');
      expect(req.url.path, '/packages');
      expect(req.url.queryParameters['category'], 'entertainment');
      expect(req.url.queryParameters['search'], 'net');
      expect(req.headers['authorization'], 'Bearer $testToken');

      expect(packages.length, 2);

      final p1 = packages[0];
      expect(p1.id, 'pkg-1');
      expect(p1.name, 'Netflix Premium');
      expect(p1.category, 'entertainment');
      expect(p1.price, 419.0);
      expect(p1.billingPeriod, 'Monthly');
      expect(p1.brandColor, '#E50914');
      expect(p1.iconUrl, 'https://example.com/netflix.png');
      expect(p1.description, 'Watch in 4K UHD');

      final p2 = packages[1];
      expect(p2.id, 'pkg-2');
      expect(p2.price, 289.0);
      expect(p2.billingPeriod, 'Yearly');
      expect(p2.brandColor, '#0063E5');
      expect(p2.iconUrl, isNull);
    });

    test('throws exception when server returns error envelope', () async {
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

      final repository = RemotePackageRepository(
        client: authClient,
        baseUrl: testBaseUrl,
      );

      expect(
        () => repository.getPackages(),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('PresetPackage.fromJson', () {
    test('normalizes known billing cycles and logs warning on fallback for unknown', () {
      final monthly = PresetPackage.fromJson({'name': 'Test', 'billing_cycle': 'monthly'});
      expect(monthly.billingPeriod, 'Monthly');

      final yearly = PresetPackage.fromJson({'name': 'Test', 'billing_cycle': 'YEARLY'});
      expect(yearly.billingPeriod, 'Yearly');

      final weekly = PresetPackage.fromJson({'name': 'Test', 'billing_cycle': 'weekly'});
      expect(weekly.billingPeriod, 'Weekly');

      final unknown = PresetPackage.fromJson({'name': 'Test', 'billing_cycle': 'BIWEEKLY_UNKNOWN'});
      expect(unknown.billingPeriod, 'Monthly');

      final nullCycle = PresetPackage.fromJson({'name': 'Test', 'billing_cycle': null});
      expect(nullCycle.billingPeriod, 'Monthly');
    });
  });
}

