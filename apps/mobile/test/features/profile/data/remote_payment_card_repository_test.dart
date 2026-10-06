import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:subscription_track/core/network/authenticated_http_client.dart';
import 'package:subscription_track/features/profile/data/in_memory_payment_card_repository.dart';
import 'package:subscription_track/features/profile/data/remote_payment_card_repository.dart';

void main() {
  const testBaseUrl = 'http://localhost:3000';
  const testToken = 'valid-jwt-token-for-test';
  const testCardId = 'card-test-uuid-456';
  const testPin = '482910';

  group('RemotePaymentCardRepository.deleteCard', () {
    test(
        'constructs DELETE /cards/:id with x-security-pin header and Authorization Bearer',
        () async {
      http.Request? capturedRequest;

      final mockInner = MockClient((request) async {
        capturedRequest = request;
        return http.Response(
          jsonEncode({
            'success': true,
            'statusCode': 200,
            'data': {'message': 'Payment card deactivated successfully'},
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final authClient = AuthenticatedHttpClient(
        readToken: () async => testToken,
        inner: mockInner,
      );

      final repository = RemotePaymentCardRepository(
        client: authClient,
        baseUrl: testBaseUrl,
      );

      await repository.deleteCard(testCardId, pin: testPin);

      expect(capturedRequest, isNotNull);
      final req = capturedRequest!;

      // 1. HTTP Method
      expect(req.method, 'DELETE');

      // 2. Path
      expect(req.url.path, '/cards/$testCardId');

      // 3. Header x-security-pin
      expect(req.headers['x-security-pin'], isNotNull);
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
            'data': {'message': 'deactivated'},
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final authClient = AuthenticatedHttpClient(
        readToken: () async => testToken,
        inner: mockInner,
      );

      final repository = RemotePaymentCardRepository(
        client: authClient,
        baseUrl: testBaseUrl,
      );

      await repository.deleteCard(testCardId);

      expect(capturedRequest, isNotNull);
      expect(capturedRequest!.headers.containsKey('x-security-pin'), isFalse);
    });

    test('throws PaymentCardNotFoundException on HTTP 404', () async {
      final mockInner = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'statusCode': 404,
            'message': 'Payment card not found',
          }),
          404,
          headers: {'content-type': 'application/json'},
        );
      });

      final repository = RemotePaymentCardRepository(
        client: mockInner,
        baseUrl: testBaseUrl,
      );

      expect(
        () => repository.deleteCard('nonexistent-card-id', pin: testPin),
        throwsA(isA<PaymentCardNotFoundException>()),
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

      final repository = RemotePaymentCardRepository(
        client: mockInner,
        baseUrl: testBaseUrl,
      );

      expect(
        () => repository.deleteCard(testCardId, pin: '000000'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('RemotePaymentCardRepository.linkCard', () {
    test('POSTs mock_card_id (not id) to /cards/link', () async {
      http.Request? capturedRequest;
      Map<String, dynamic>? capturedBody;

      final mockInner = MockClient((request) async {
        capturedRequest = request;
        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({
            'success': true,
            'statusCode': 201,
            'data': {
              'card': {
                'id': 'card-new-uuid',
                'card_nickname': 'KBank',
                'card_brand': 'Visa',
                'last_4_digits': '4242',
                'bank_name': 'Kasikornbank',
                'balance': 12500,
                'currency': 'THB',
                'is_default': false,
              },
              'imported_subscriptions_count': 2,
              'imported_subscriptions': [],
            },
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
      });

      final repository = RemotePaymentCardRepository(
        client: mockInner,
        baseUrl: testBaseUrl,
      );

      final card = await repository.linkCard('mock-card-uuid-123');

      expect(capturedRequest!.url.path, '/cards/link');
      expect(capturedBody!['mock_card_id'], 'mock-card-uuid-123');
      expect(capturedBody!.containsKey('id'), isFalse);
      expect(card.id, 'card-new-uuid');
      expect(card.bankName, 'Kasikornbank');
      expect(card.last4Digits, '4242');
      expect(card.currentBalance, 12500);
      expect(card.colorHex, '#1A1F71'); // Visa brand color
    });

    test('throws Exception when link fails', () async {
      final mockInner = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'statusCode': 404,
            'message': 'No simulated mock bank card found matching criteria',
          }),
          404,
          headers: {'content-type': 'application/json'},
        );
      });

      final repository = RemotePaymentCardRepository(
        client: mockInner,
        baseUrl: testBaseUrl,
      );

      expect(
        () => repository.linkCard('nonexistent'),
        throwsA(isA<Exception>()),
      );
    });

    test('throws Exception with specific message on HTTP 403 Forbidden', () async {
      final mockInner = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'statusCode': 403,
            'message': 'This card does not belong to your account.',
            'error': 'Forbidden',
          }),
          403,
          headers: {'content-type': 'application/json'},
        );
      });

      final repository = RemotePaymentCardRepository(
        client: mockInner,
        baseUrl: testBaseUrl,
      );

      expect(
        () => repository.linkCard('student01-card-id'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('This card does not belong to your account.'),
          ),
        ),
      );
    });
  });

  group('RemotePaymentCardRepository.getLinkedCards field mapping', () {
    test('maps snake_case backend fields to PaymentCard correctly', () async {
      final mockInner = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'statusCode': 200,
            'data': [
              {
                'id': 'card-1',
                'card_nickname': 'My SCB Card',
                'card_brand': 'Mastercard',
                'last_4_digits': '8888',
                'bank_name': 'Siam Commercial Bank',
                'balance': 4500.5,
                'currency': 'THB',
                'is_default': true,
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final repository = RemotePaymentCardRepository(
        client: mockInner,
        baseUrl: testBaseUrl,
      );

      final cards = await repository.getLinkedCards();

      expect(cards, hasLength(1));
      expect(cards[0].id, 'card-1');
      expect(cards[0].bankName, 'Siam Commercial Bank');
      expect(cards[0].last4Digits, '8888');
      expect(cards[0].currentBalance, 4500.5);
      expect(cards[0].colorHex, '#EB001B'); // Mastercard brand color
      expect(cards[0].creditLimit, 0); // no backend column, documented default
    });

    test('empty list from backend maps to empty list, not an error', () async {
      final mockInner = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'statusCode': 200,
            'data': <Map<String, dynamic>>[],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final repository = RemotePaymentCardRepository(
        client: mockInner,
        baseUrl: testBaseUrl,
      );

      expect(await repository.getLinkedCards(), isEmpty);
    });

    test('unknown card_brand falls back to extension default color, not a crash',
        () async {
      final mockInner = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'statusCode': 200,
            'data': [
              {
                'id': 'card-1',
                'card_brand': 'SomeObscureNetwork',
                'last_4_digits': '0000',
                'bank_name': 'Test Bank',
                'balance': 0,
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final repository = RemotePaymentCardRepository(
        client: mockInner,
        baseUrl: testBaseUrl,
      );

      final cards = await repository.getLinkedCards();
      expect(cards[0].colorHex, ''); // extension falls back to default blue
    });
  });
}
