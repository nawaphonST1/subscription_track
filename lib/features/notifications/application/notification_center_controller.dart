import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subscription_track/features/notifications/data/mock_notification_data.dart';
import 'package:subscription_track/features/notifications/domain/app_notification.dart';

final notificationCenterProvider =
    NotifierProvider<NotificationCenterController, NotificationCenterState>(
      NotificationCenterController.new,
    );

enum NotificationFilter { all, unread, read }

class NotificationCenterState {
  const NotificationCenterState({
    required this.items,
    this.filter = NotificationFilter.all,
  });

  final List<AppNotification> items;
  final NotificationFilter filter;

  List<AppNotification> get visibleItems {
    return switch (filter) {
      NotificationFilter.all => items,
      NotificationFilter.unread =>
        items.where((item) => !item.isRead).toList(growable: false),
      NotificationFilter.read =>
        items.where((item) => item.isRead).toList(growable: false),
    };
  }

  NotificationCenterState copyWith({
    List<AppNotification>? items,
    NotificationFilter? filter,
  }) {
    return NotificationCenterState(
      items: items ?? this.items,
      filter: filter ?? this.filter,
    );
  }
}

final class NotificationCenterController
    extends Notifier<NotificationCenterState> {
  @override
  NotificationCenterState build() {
    return NotificationCenterState(items: createMockNotifications());
  }

  void selectFilter(NotificationFilter filter) {
    state = state.copyWith(filter: filter);
  }

  void markAllAsRead() {
    state = state.copyWith(
      items: [for (final item in state.items) item.copyWith(isRead: true)],
    );
  }

  void clearAll() {
    state = state.copyWith(items: const []);
  }

  void dismiss(String id) {
    state = state.copyWith(
      items: state.items.where((item) => item.id != id).toList(growable: false),
    );
  }

  void toggleRead(String id) {
    state = state.copyWith(
      items: [
        for (final item in state.items)
          if (item.id == id) item.copyWith(isRead: !item.isRead) else item,
      ],
    );
  }
}
