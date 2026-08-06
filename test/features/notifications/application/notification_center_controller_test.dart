import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subscription_track/features/notifications/application/notification_center_controller.dart';

void main() {
  late ProviderContainer container;

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  test('filters immutable notification state by read status', () {
    final controller = container.read(notificationCenterProvider.notifier);
    controller.selectFilter(NotificationFilter.unread);
    final unread = container.read(notificationCenterProvider).visibleItems;

    expect(unread, isNotEmpty);
    expect(unread.every((item) => !item.isRead), isTrue);

    controller.selectFilter(NotificationFilter.read);
    final read = container.read(notificationCenterProvider).visibleItems;
    expect(read, isNotEmpty);
    expect(read.every((item) => item.isRead), isTrue);
  });

  test('toggles, marks, dismisses, and clears notifications', () {
    final controller = container.read(notificationCenterProvider.notifier);
    final initial = container.read(notificationCenterProvider);
    final target = initial.items.first;

    controller.toggleRead(target.id);
    expect(
      container
          .read(notificationCenterProvider)
          .items
          .firstWhere((item) => item.id == target.id)
          .isRead,
      isNot(target.isRead),
    );

    controller.markAllAsRead();
    expect(
      container
          .read(notificationCenterProvider)
          .items
          .every((item) => item.isRead),
      isTrue,
    );

    controller.dismiss(target.id);
    expect(
      container.read(notificationCenterProvider).items,
      hasLength(initial.items.length - 1),
    );

    controller.clearAll();
    expect(container.read(notificationCenterProvider).items, isEmpty);
  });
}
