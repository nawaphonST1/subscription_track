import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:subscription_track/core/errors/failures.dart';
import 'package:subscription_track/core/network/api_config.dart';
import 'package:subscription_track/core/network/authenticated_http_client.dart';
import 'package:subscription_track/core/network/response_envelope.dart';
import 'package:subscription_track/features/auth/data/remote_auth_repository.dart';
import 'package:subscription_track/features/profile/data/in_memory_payment_card_repository.dart';
import 'package:subscription_track/features/profile/domain/payment_card.dart';
import 'package:subscription_track/features/profile/domain/payment_card_repository.dart';

/// backend ไม่มีคอลัมน์สีของบัตรเก็บไว้ (ไม่มี color_hex ใน payment_cards) จึง
/// derive มาจาก `card_brand` (เครือข่ายบัตร เช่น Visa/Mastercard) แทน — ไม่ใช่
/// จาก `bank_name` เพราะ card_brand เป็น enum ค่าจำกัดกว่าและเป็น field ที่
/// backend รับประกันว่ามีเสมอ (ดู payment-cards.service.ts)
///
/// brand ที่ไม่อยู่ในนี้ (หรือไม่มีค่าเลย) ตกไปที่ default ของ
/// [PaymentCardUiExtension.displayColor] อยู่แล้ว จึงไม่ต้องใส่ fallback ซ้ำที่นี่
const Map<String, String> _brandColors = {
  'visa': '#1A1F71',
  'mastercard': '#EB001B',
  'amex': '#006FCF',
  'american express': '#006FCF',
  'jcb': '#0E4C96',
  'unionpay': '#E21836',
};

String _colorHexForBrand(String? cardBrand) {
  if (cardBrand == null) return '';
  return _brandColors[cardBrand.trim().toLowerCase()] ?? '';
}

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
    final result = unwrapEnvelopeList(response, _mapJsonToCard);
    return result.fold(
      (failure) => throw Exception(
          'Failed to load cards (HTTP ${response.statusCode}): ${failure.displayMessage}'),
      (cards) => cards,
    );
  }

  @override
  Future<List<PaymentCard>> getAvailableCards() async {
    final uri = Uri.parse('$_baseUrl/cards/mock');
    final response = await _client.get(uri);
    final result = unwrapEnvelopeList(response, _mapJsonToMockCard);
    return result.fold(
      (failure) => throw Exception(
          'Failed to load mock cards (HTTP ${response.statusCode}): ${failure.displayMessage}'),
      (cards) => cards,
    );
  }

  @override
  Future<PaymentCard> linkCard(String id) async {
    final uri = Uri.parse('$_baseUrl/cards/link');
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      // backend's LinkMockCardDto expects "mock_card_id", not "id"
      body: jsonEncode({'mock_card_id': id}),
    );
    final result = unwrapEnvelope(response, (data) {
      final cardJson = data['card'] as Map<String, dynamic>;
      return _mapJsonToCard(cardJson);
    });
    return result.fold(
      (failure) => throw Exception(
          'Failed to link card (HTTP ${response.statusCode}): ${failure.displayMessage}'),
      (card) => card,
    );
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

  /// map response ของ `GET /cards` และ `POST /cards/link` (คีย์ `card`)
  ///
  /// ไม่มี `credit_limit`/`color_hex` ใน payment_cards เลย: creditLimit ไม่ถูก
  /// render ที่ไหนในแอปตอนนี้ (ยืนยันแล้วก่อนแก้) จึงปล่อยเป็น 0 ไปตรง ๆ ส่วน
  /// colorHex derive จาก card_brand ผ่าน [_colorHexForBrand]
  PaymentCard _mapJsonToCard(Map<String, dynamic> json) {
    return PaymentCard(
      id: json['id'] as String? ?? '',
      bankName: json['bank_name'] as String? ?? '',
      last4Digits: json['last_4_digits'] as String? ?? '',
      creditLimit: 0,
      currentBalance: (json['balance'] as num?)?.toDouble() ?? 0,
      colorHex: _colorHexForBrand(json['card_brand'] as String?),
      detectedSubscriptions: const [],
    );
  }

  /// map response ของ `GET /cards/mock` (MockBankCard — มี `subscriptions`
  /// แนบมาด้วยสำหรับพรีวิวก่อนเชื่อมบัตรจริง)
  PaymentCard _mapJsonToMockCard(Map<String, dynamic> json) {
    final rawSubscriptions = json['subscriptions'];
    final detected = rawSubscriptions is List
        ? rawSubscriptions
            .whereType<Map<String, dynamic>>()
            .map(_mapJsonToDetectedSubscription)
            .toList(growable: false)
        : const <DetectedSubscription>[];

    return PaymentCard(
      id: json['id'] as String? ?? '',
      bankName: json['bank_name'] as String? ?? '',
      last4Digits: json['last_4_digits'] as String? ?? '',
      creditLimit: 0,
      currentBalance: (json['balance'] as num?)?.toDouble() ?? 0,
      colorHex: _colorHexForBrand(json['card_brand'] as String?),
      detectedSubscriptions: detected,
    );
  }

  /// `MockBankCardSubscription` ที่แนบมากับ `GET /cards/mock` เพื่อพรีวิว
  /// ก่อนเชื่อมบัตร — คนละ shape กับ `UserSubscription` ที่ backend
  /// auto-import จริงตอน `POST /cards/link` (ดูหมายเหตุใน
  /// `payment_card_linking_controller.dart`)
  DetectedSubscription _mapJsonToDetectedSubscription(
    Map<String, dynamic> json,
  ) {
    return DetectedSubscription(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      category: json['category'] as String? ?? '',
      usageStatus: 'frequent',
      confidence: 0,
      daysUntilNextBilling: 0,
    );
  }
}
