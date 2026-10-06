import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:subscription_track/core/network/api_config.dart';
import 'package:subscription_track/core/network/authenticated_http_client.dart';
import 'package:subscription_track/features/auth/data/remote_auth_repository.dart';
import 'package:subscription_track/features/profile/data/in_memory_payment_card_repository.dart';
import 'package:subscription_track/features/profile/domain/payment_card.dart';
import 'package:subscription_track/features/profile/domain/payment_card_repository.dart';

class RemotePaymentCardRepository implements PaymentCardRepository {
  RemotePaymentCardRepository({
    http.Client? client,
    String? baseUrl,
  })  : _client = client is AuthenticatedHttpClient
            ? client
            : AuthenticatedHttpClient(
                readToken: RemoteAuthRepository.readStoredAuthToken,
                inner: client,
              ),
        _baseUrl = baseUrl ?? ApiConfig.baseUrl;

  final http.Client _client;
  final String _baseUrl;

  @override
  Future<List<PaymentCard>> getLinkedCards() async {
    final uri = Uri.parse('$_baseUrl/cards');
    final response = await _client.get(uri);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      final dynamic rawList =
          decoded is Map<String, dynamic> ? decoded['data'] : decoded;
      if (rawList is List) {
        return rawList.map((item) {
          final map = item as Map<String, dynamic>;
          return PaymentCard(
            id: map['id']?.toString() ?? '',
            bankName: map['bank_name']?.toString() ??
                map['card_nickname']?.toString() ??
                '',
            last4Digits: map['last_4_digits']?.toString() ?? '',
            creditLimit: 0,
            currentBalance: (map['balance'] as num?)?.toDouble() ?? 0,
            colorHex: '#00A859',
            detectedSubscriptions: const [],
          );
        }).toList();
      }
      return const [];
    }
    throw Exception('Failed to load cards (HTTP ${response.statusCode})');
  }

  @override
  Future<List<PaymentCard>> getAvailableCards() async {
    final uri = Uri.parse('$_baseUrl/cards/mock');
    final response = await _client.get(uri);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      final dynamic rawList =
          decoded is Map<String, dynamic> ? decoded['data'] : decoded;
      if (rawList is List) {
        return rawList.map((item) {
          final map = item as Map<String, dynamic>;
          return PaymentCard(
            id: map['id']?.toString() ?? '',
            bankName: map['bank_name']?.toString() ?? '',
            last4Digits: map['last_4_digits']?.toString() ?? '',
            creditLimit: 0,
            currentBalance: (map['balance'] as num?)?.toDouble() ?? 0,
            colorHex: '#00A859',
            detectedSubscriptions: const [],
          );
        }).toList();
      }
      return const [];
    }
    throw Exception('Failed to load mock cards (HTTP ${response.statusCode})');
  }

  @override
  Future<PaymentCard> linkCard(String id) async {
    final uri = Uri.parse('$_baseUrl/cards/link');
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'id': id}),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return PaymentCard(
        id: id,
        bankName: 'Linked Card',
        last4Digits: '0000',
        creditLimit: 0,
        currentBalance: 0,
        colorHex: '#00A859',
        detectedSubscriptions: const [],
      );
    }
    throw Exception('Failed to link card (HTTP ${response.statusCode})');
  }

  @override
  Future<void> deleteCard(String id, {String? pin}) async {
    final uri = Uri.parse('$_baseUrl/cards/$id');
    final headers = <String, String>{
      if (pin != null) 'x-security-pin': pin,
    };
    final response = await _client.delete(uri, headers: headers);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    if (response.statusCode == 404) {
      throw PaymentCardNotFoundException(id);
    }
    throw Exception('Failed to delete card (HTTP ${response.statusCode})');
  }
}
