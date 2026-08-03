import 'package:subscription_track/models/subscription.dart';

/// Contract กลางสำหรับแหล่งข้อมูล subscription
///
/// หน้าจอและ controller จะพึ่งพา interface นี้เท่านั้น ทำให้เปลี่ยนจาก
/// in-memory ไปเป็น Hive หรือ REST API ได้โดยไม่ต้องแก้ presentation layer
abstract interface class SubscriptionRepository {
  Future<List<Subscription>> getSubscriptions();

  Future<Subscription> getSubscriptionById(String id);

  Future<void> addSubscription(Subscription subscription);

  Future<void> updateSubscription(Subscription subscription);

  Future<void> deleteSubscription(String id);

  Future<void> toggleSelection(String id);
}

final class SubscriptionNotFoundException implements Exception {
  const SubscriptionNotFoundException(this.id);

  final String id;

  @override
  String toString() => 'Subscription with id "$id" was not found.';
}

final class DuplicateSubscriptionException implements Exception {
  const DuplicateSubscriptionException(this.id);

  final String id;

  @override
  String toString() => 'Subscription with id "$id" already exists.';
}
