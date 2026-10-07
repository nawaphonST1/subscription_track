import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:subscription_track/core/errors/failures.dart';
import 'package:subscription_track/core/network/api_config.dart';
import 'package:subscription_track/core/network/authenticated_http_client.dart';
import 'package:subscription_track/core/network/response_envelope.dart';
import 'package:subscription_track/features/auth/data/remote_auth_repository.dart';
import 'package:subscription_track/features/subscriptions/domain/subscription.dart';
import 'package:subscription_track/features/subscriptions/domain/subscription_enum_mapper.dart';
import 'package:subscription_track/features/subscriptions/domain/subscription_repository.dart';

class RemoteSubscriptionRepository implements SubscriptionRepository {
  RemoteSubscriptionRepository({
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
  Future<List<Subscription>> getSubscriptions() async {
    final uri = Uri.parse('$_baseUrl/subscriptions');
    final response = await _client.get(uri);
    final result = unwrapEnvelopeList(response, _mapJsonToSubscription);
    return result.fold(
      (failure) => throw Exception(
          'Failed to load subscriptions (HTTP ${response.statusCode}): ${failure.displayMessage}'),
      (items) => items,
    );
  }

  @override
  Future<Subscription> getSubscriptionById(String id) async {
    final uri = Uri.parse('$_baseUrl/subscriptions/$id');
    final response = await _client.get(uri);
    if (response.statusCode == 404) {
      throw SubscriptionNotFoundException(id);
    }
    final result = unwrapEnvelope(response, _mapJsonToSubscription);
    return result.fold(
      (failure) => throw Exception(
          'Failed to get subscription (HTTP ${response.statusCode}): ${failure.displayMessage}'),
      (subscription) => subscription,
    );
  }

  @override
  Future<void> addSubscription(Subscription subscription) async {
    final uri = Uri.parse('$_baseUrl/subscriptions');
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(_buildCreatePayload(subscription)),
    );
    final result = unwrapEnvelope(response, (_) => null);
    result.fold(
      (failure) => throw Exception(
          'Failed to add subscription (HTTP ${response.statusCode}): ${failure.displayMessage}'),
      (_) => null,
    );
  }

  @override
  Future<void> updateSubscription(Subscription subscription) async {
    final uri = Uri.parse('$_baseUrl/subscriptions/${subscription.id}');
    final response = await _client.patch(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(_buildUpdatePayload(subscription)),
    );
    if (response.statusCode == 404) {
      throw SubscriptionNotFoundException(subscription.id);
    }
    final result = unwrapEnvelope(response, (_) => null);
    result.fold(
      (failure) => throw Exception(
          'Failed to update subscription (HTTP ${response.statusCode}): ${failure.displayMessage}'),
      (_) => null,
    );
  }

  @override
  Future<void> deleteSubscription(String id, {String? pin}) async {
    final uri = Uri.parse('$_baseUrl/subscriptions/$id');
    final headers = <String, String>{
      if (pin != null) 'x-security-pin': pin,
    };
    final response = await _client.delete(uri, headers: headers);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    if (response.statusCode == 404) {
      throw SubscriptionNotFoundException(id);
    }
    throw Exception(
        'Failed to delete subscription (HTTP ${response.statusCode})');
  }

  @override
  Future<void> toggleSelection(String id) async {
    // Selection state is client-side only (no backend column) — see
    // the note on `isSelected`/`customFields`/`reminderEnabled` below.
  }

  /// `POST /subscriptions` ของ backend ใช้ `whitelist: true,
  /// forbidNonWhitelisted: true` (ดู `main.ts`) — ส่งฟิลด์ที่ DTO ไม่รู้จัก
  /// (เช่น isSelected, customFields, reminderEnabled, confidence ที่เป็น
  /// local-only state ไม่มีคอลัมน์ backend) จะโดน 400 ทันที จึงต้อง build
  /// payload เองแบบ whitelist แทนการส่ง `subscription.toJson()` ทั้งก้อน
  Map<String, dynamic> _buildCreatePayload(Subscription subscription) {
    if (subscription.paymentCardId == null ||
        subscription.paymentCardId!.isEmpty) {
      // ควรถูกกันไว้ที่ UI (AddSubscriptionScreen) ก่อนเรียกมาถึงนี่แล้ว —
      // แต่ throw ตรงนี้กันพลาดซ้ำแทนที่จะปล่อยให้ backend ตอบ 400 แบบงง ๆ
      throw ArgumentError(
        'Cannot create a subscription without a linked payment card id',
      );
    }
    return {
      'payment_card_id': subscription.paymentCardId,
      'card_id': subscription.paymentCardId,
      if (subscription.presetId != null) 'preset_id': subscription.presetId,
      'name': subscription.name,
      'category': subscription.category,
      'price': subscription.price,
      'billing_cycle': billingCycleToBackend(subscription.billingPeriod),
      if (subscription.nextBillingDate != null)
        'next_renewal_date': subscription.nextBillingDate!.toIso8601String(),
      'usage_status': usageStatusToBackend(subscription.usageStatus),
      if (subscription.planTier != null) 'plan_tier': subscription.planTier,
      'shared_members': subscription.sharedMembers,
    };
  }

  /// เหมือน [_buildCreatePayload] แต่ทุกฟิลด์ optional ตาม
  /// `UpdateSubscriptionDto` — ส่งเฉพาะที่มีค่า ไม่ส่ง `payment_card_id` ถ้า
  /// ไม่ได้ตั้งใจเปลี่ยนบัตร
  Map<String, dynamic> _buildUpdatePayload(Subscription subscription) {
    return {
      if (subscription.paymentCardId != null) ...{
        'payment_card_id': subscription.paymentCardId,
        'card_id': subscription.paymentCardId,
      },
      'name': subscription.name,
      'category': subscription.category,
      'price': subscription.price,
      'billing_cycle': billingCycleToBackend(subscription.billingPeriod),
      if (subscription.nextBillingDate != null)
        'next_renewal_date': subscription.nextBillingDate!.toIso8601String(),
      'usage_status': usageStatusToBackend(subscription.usageStatus),
    };
  }

  /// map response ของ `GET /subscriptions`/`GET /subscriptions/:id`
  ///
  /// `payment_card_id` ไม่มีเป็น key แยกใน response (ดู
  /// subscriptions.service.ts) — ซ้อนอยู่ใน `payment_card.id` แทน
  ///
  /// `isSelected`/`customFields`/`reminderEnabled`/`confidence` ไม่มีคอลัมน์
  /// backend เลย เป็น local-only UI state ล้วน ๆ จึงไม่ parse จาก response
  /// (ปล่อยให้เป็นค่า default ของ model เสมอตอนโหลดจาก backend)
  Subscription _mapJsonToSubscription(Map<String, dynamic> json) {
    final paymentCard = json['payment_card'];
    final paymentCardId = paymentCard is Map<String, dynamic>
        ? paymentCard['id'] as String?
        : json['payment_card_id'] as String?;
    final preset = json['preset'];
    final presetId = preset is Map<String, dynamic>
        ? preset['id'] as String?
        : json['preset_id'] as String?;

    return Subscription(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      billingPeriod: billingCycleFromBackend(
        json['billing_cycle'] as String? ?? 'MONTHLY',
      ),
      category: json['category'] as String? ?? 'other',
      nextBillingDate: json['next_renewal_date'] != null
          ? DateTime.tryParse(json['next_renewal_date'].toString())
          : null,
      usageStatus: usageStatusFromBackend(
        json['usage_status'] as String? ?? 'FREQUENT',
      ),
      paymentCardId: paymentCardId,
      presetId: presetId,
      planTier: json['plan_tier'] as String?,
      sharedMembers: (json['shared_members'] as num?)?.toInt() ?? 1,
      pricePerSlot: (json['price_per_slot'] as num?)?.toDouble(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }
}
