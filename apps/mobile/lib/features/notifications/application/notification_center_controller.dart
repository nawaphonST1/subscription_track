import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subscription_track/features/notifications/data/remote_notification_repository.dart';
import 'package:subscription_track/features/notifications/domain/app_notification.dart';
import 'package:subscription_track/features/notifications/domain/notification_repository.dart';

/// จุดสลับ data source ของ feature นี้ และ override เป็น fake/mock ได้ใน test
final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => RemoteNotificationRepository(),
);

final notificationCenterProvider = AsyncNotifierProvider<
    NotificationCenterController, NotificationCenterState>(
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

/// Controller ของหน้าศูนย์การแจ้งเตือน: โหลดจาก [NotificationRepository] แล้ว
/// ทำ optimistic update สำหรับ command ทุกตัว (rollback หาก backend ล้มเหลว)
/// เหมือน SubscriptionListController/PaymentCardLinkingController
final class NotificationCenterController
    extends AsyncNotifier<NotificationCenterState> {
  NotificationRepository get _repository =>
      ref.read(notificationRepositoryProvider);

  @override
  Future<NotificationCenterState> build() async {
    final feed = await _repository.getNotifications();
    return NotificationCenterState(items: feed.items);
  }

  void selectFilter(NotificationFilter filter) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(filter: filter));
  }

  Future<void> refresh() async {
    state = const AsyncLoading<NotificationCenterState>();
    final previousFilter = state.value?.filter ?? NotificationFilter.all;
    state = await AsyncValue.guard(() async {
      final feed = await _repository.getNotifications();
      return NotificationCenterState(items: feed.items, filter: previousFilter);
    });
  }

  /// ทางเดียว unread -> read เท่านั้น (ดูเหตุผลใน NotificationRepository)
  /// ถ้า item อ่านแล้วอยู่ก่อน tap จะไม่ทำอะไรเลย ไม่มีการเรียก backend ทิ้งเปล่า ๆ
  Future<void> markAsRead(String id) async {
    final current = await future;
    final target = current.items.where((item) => item.id == id).firstOrNull;
    if (target == null || target.isRead) return;

    final previousItems = current.items;
    state = AsyncData(current.copyWith(items: [
      for (final item in previousItems)
        if (item.id == id) item.copyWith(isRead: true) else item,
    ]));

    try {
      await _repository.markAsRead(id);
    } catch (error, stackTrace) {
      state = AsyncData(current.copyWith(items: previousItems));
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> markAllAsRead() async {
    final current = await future;
    final previousItems = current.items;
    state = AsyncData(current.copyWith(
      items: [for (final item in previousItems) item.copyWith(isRead: true)],
    ));

    try {
      await _repository.markAllAsRead();
    } catch (error, stackTrace) {
      state = AsyncData(current.copyWith(items: previousItems));
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> dismiss(String id) async {
    final current = await future;
    final previousItems = current.items;
    state = AsyncData(current.copyWith(
      items: previousItems.where((item) => item.id != id).toList(growable: false),
    ));

    try {
      await _repository.dismiss(id);
    } catch (error, stackTrace) {
      state = AsyncData(current.copyWith(items: previousItems));
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> clearAll() async {
    final current = await future;
    final previousItems = current.items;
    state = AsyncData(current.copyWith(items: const []));

    try {
      await _repository.clearAll();
    } catch (error, stackTrace) {
      state = AsyncData(current.copyWith(items: previousItems));
      Error.throwWithStackTrace(error, stackTrace);
    }
  }
}
