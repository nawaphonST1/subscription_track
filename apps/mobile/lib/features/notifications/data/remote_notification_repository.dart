import 'package:http/http.dart' as http;
import 'package:subscription_track/core/errors/failures.dart';
import 'package:subscription_track/core/network/api_config.dart';
import 'package:subscription_track/core/network/authenticated_http_client.dart';
import 'package:subscription_track/core/network/response_envelope.dart';
import 'package:subscription_track/features/auth/data/remote_auth_repository.dart';
import 'package:subscription_track/features/notifications/domain/app_notification.dart';
import 'package:subscription_track/features/notifications/domain/notification_repository.dart';

/// `NotificationType` ฝั่ง backend (RENEWAL_ALERT / UNUSED_SUBSCRIPTION_WARNING
/// / SECURITY_ALERT) ไม่ตรงชื่อกับ type string ฝั่งแอป (ใช้แสดงไอคอน/สีใน
/// notification_ui_extensions.dart) จึง map ให้ชัดเจนที่เดียวตรงนี้ — ค่าที่
/// ไม่รู้จักตกไปที่ default ของฝั่ง UI เอง (ไอคอนกระดิ่งเฉย ๆ) ไม่ throw เพราะ
/// นี่เป็นแค่ metadata ตกแต่งหน้าจอ ไม่ใช่ค่าที่กระทบความถูกต้องของข้อมูล
String _typeFromBackend(String? backendType) {
  return switch (backendType) {
    'RENEWAL_ALERT' => 'upcoming_bill',
    'UNUSED_SUBSCRIPTION_WARNING' => 'unused_warning',
    'SECURITY_ALERT' => 'security_alert',
    _ => 'system',
  };
}

class RemoteNotificationRepository implements NotificationRepository {
  RemoteNotificationRepository({
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
  Future<NotificationFeed> getNotifications() async {
    final uri = Uri.parse('$_baseUrl/notifications');
    final response = await _client.get(uri);
    final result = unwrapEnvelope(response, _mapJsonToFeed);
    return result.fold(
      (failure) => throw Exception(
          'Failed to load notifications (HTTP ${response.statusCode}): ${failure.displayMessage}'),
      (feed) => feed,
    );
  }

  @override
  Future<void> markAsRead(String id) async {
    final uri = Uri.parse('$_baseUrl/notifications/$id/read');
    final response = await _client.patch(uri);
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    if (response.statusCode == 404) {
      throw NotificationNotFoundException(id);
    }
    throw Exception(
        'Failed to mark notification as read (HTTP ${response.statusCode})');
  }

  @override
  Future<void> markAllAsRead() async {
    final uri = Uri.parse('$_baseUrl/notifications/read-all');
    final response = await _client.patch(uri);
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw Exception(
        'Failed to mark all notifications as read (HTTP ${response.statusCode})');
  }

  @override
  Future<void> dismiss(String id) async {
    final uri = Uri.parse('$_baseUrl/notifications/$id');
    final response = await _client.delete(uri);
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    if (response.statusCode == 404) {
      throw NotificationNotFoundException(id);
    }
    throw Exception(
        'Failed to delete notification (HTTP ${response.statusCode})');
  }

  @override
  Future<void> clearAll() async {
    final uri = Uri.parse('$_baseUrl/notifications');
    final response = await _client.delete(uri);
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw Exception(
        'Failed to clear notifications (HTTP ${response.statusCode})');
  }

  NotificationFeed _mapJsonToFeed(Map<String, dynamic> data) {
    final rawList = data['notifications'];
    final items = rawList is List
        ? rawList
            .whereType<Map<String, dynamic>>()
            .map(_mapJsonToNotification)
            .toList(growable: false)
        : const <AppNotification>[];
    final unreadCount = (data['unread_count'] as num?)?.toInt() ?? 0;
    return (items: items, unreadCount: unreadCount);
  }

  AppNotification _mapJsonToNotification(Map<String, dynamic> json) {
    final createdAt = json['created_at'] != null
        ? DateTime.tryParse(json['created_at'].toString())
        : null;

    return AppNotification(
      id: json['id'] as String? ?? '',
      type: _typeFromBackend(json['type'] as String?),
      title: json['title'] as String? ?? '',
      // backend คอลัมน์ชื่อ message ไม่ใช่ body
      body: json['message'] as String? ?? '',
      isRead: json['is_read'] as bool? ?? false,
      createdAt: createdAt,
      // backend ไม่มีแนวคิด "เวลาที่ตั้งไว้ล่วงหน้า" แยกจาก created_at เลย —
      // ใช้ created_at แทนเพื่อให้ formatNotificationDate ยังมีเวลาแสดงผล
      scheduledAt: createdAt,
    );
  }
}
