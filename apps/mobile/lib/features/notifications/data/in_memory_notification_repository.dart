import 'package:subscription_track/features/notifications/data/mock_notification_data.dart';
import 'package:subscription_track/features/notifications/domain/app_notification.dart';
import 'package:subscription_track/features/notifications/domain/notification_repository.dart';

final class InMemoryNotificationRepository implements NotificationRepository {
  InMemoryNotificationRepository({
    this.ioDelay = const Duration(milliseconds: 250),
    List<AppNotification>? initialItems,
  }) : _items = List.of(initialItems ?? createMockNotifications());

  final Duration ioDelay;
  List<AppNotification> _items;

  @override
  Future<NotificationFeed> getNotifications() async {
    await _simulateIo();
    return (
      items: List<AppNotification>.unmodifiable(_items),
      unreadCount: _items.where((item) => !item.isRead).length,
    );
  }

  @override
  Future<void> markAsRead(String id) async {
    await _simulateIo();
    _items = [
      for (final item in _items)
        if (item.id == id) item.copyWith(isRead: true) else item,
    ];
  }

  @override
  Future<void> markAllAsRead() async {
    await _simulateIo();
    _items = [for (final item in _items) item.copyWith(isRead: true)];
  }

  @override
  Future<void> dismiss(String id) async {
    await _simulateIo();
    final existed = _items.any((item) => item.id == id);
    if (!existed) throw NotificationNotFoundException(id);
    _items = _items.where((item) => item.id != id).toList(growable: false);
  }

  @override
  Future<void> clearAll() async {
    await _simulateIo();
    _items = const [];
  }

  Future<void> _simulateIo() => Future<void>.delayed(ioDelay);
}
