import 'package:subscription_track/features/notifications/domain/app_notification.dart';

/// ผลลัพธ์ของ `GET /notifications`: รายการ + จำนวนที่ยังไม่อ่าน (ฝั่งแอปคำนวณ
/// unread count เองจาก items อยู่แล้วตอนนี้ จึงยังไม่ได้ใช้ unreadCount แต่เก็บ
/// ไว้เผื่อใช้ทำ badge ในอนาคตโดยไม่ต้องแก้ signature ซ้ำ)
typedef NotificationFeed = ({List<AppNotification> items, int unreadCount});

abstract interface class NotificationRepository {
  Future<NotificationFeed> getNotifications();

  /// ทำได้ทางเดียว: unread -> read เท่านั้น backend ไม่มี endpoint
  /// "mark unread" จึงไม่มี toggle กลับได้จริง
  Future<void> markAsRead(String id);

  Future<void> markAllAsRead();

  Future<void> dismiss(String id);

  Future<void> clearAll();
}

final class NotificationNotFoundException implements Exception {
  const NotificationNotFoundException(this.id);

  final String id;
}
