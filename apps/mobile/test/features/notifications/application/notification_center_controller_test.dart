import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subscription_track/features/notifications/application/notification_center_controller.dart';
import 'package:subscription_track/features/notifications/data/in_memory_notification_repository.dart';
import 'package:subscription_track/features/notifications/domain/notification_repository.dart';

void main() {
  late ProviderContainer container;
  late InMemoryNotificationRepository repository;

  setUp(() {
    repository = InMemoryNotificationRepository(ioDelay: Duration.zero);
    container = ProviderContainer(
      overrides: [
        notificationRepositoryProvider.overrideWithValue(repository),
      ],
    );
  });
  tearDown(() => container.dispose());

  Future<NotificationCenterState> currentState() =>
      container.read(notificationCenterProvider.notifier).future;

  test('filters immutable notification state by read status', () async {
    final controller = container.read(notificationCenterProvider.notifier);
    await controller.future;
    controller.selectFilter(NotificationFilter.unread);
    final unread =
        container.read(notificationCenterProvider).value!.visibleItems;

    expect(unread, isNotEmpty);
    expect(unread.every((item) => !item.isRead), isTrue);

    controller.selectFilter(NotificationFilter.read);
    final read =
        container.read(notificationCenterProvider).value!.visibleItems;
    expect(read, isNotEmpty);
    expect(read.every((item) => item.isRead), isTrue);
  });

  test(
      'marks as read (one-way only), marks all read, dismisses, and clears notifications',
      () async {
    final controller = container.read(notificationCenterProvider.notifier);
    final initial = await controller.future;
    final target = initial.items.first;
    expect(target.isRead, isFalse, reason: 'fixture assumption: item 1 starts unread');

    await controller.markAsRead(target.id);
    expect(
      (await currentState()).items
          .firstWhere((item) => item.id == target.id)
          .isRead,
      isTrue,
    );

    // marking an already-read item again is a no-op (no backend call, no crash)
    await controller.markAsRead(target.id);
    expect(
      (await currentState()).items
          .firstWhere((item) => item.id == target.id)
          .isRead,
      isTrue,
    );

    await controller.markAllAsRead();
    expect(
      (await currentState()).items.every((item) => item.isRead),
      isTrue,
    );

    await controller.dismiss(target.id);
    expect(
      (await currentState()).items,
      hasLength(initial.items.length - 1),
    );

    await controller.clearAll();
    expect((await currentState()).items, isEmpty);
  });

  test('rolls back the optimistic update when the repository call fails',
      () async {
    final failingRepository = _FailingNotificationRepository(repository);
    final failingContainer = ProviderContainer(
      overrides: [
        notificationRepositoryProvider.overrideWithValue(failingRepository),
      ],
    );
    addTearDown(failingContainer.dispose);

    final controller =
        failingContainer.read(notificationCenterProvider.notifier);
    final initial = await controller.future;
    final target = initial.items.first;

    await expectLater(
      () => controller.dismiss(target.id),
      throwsException,
    );

    // state rolled back to the pre-dismiss list, not left in the optimistic
    // (already-removed) state
    expect(
      failingContainer.read(notificationCenterProvider).value!.items,
      hasLength(initial.items.length),
    );
  });
}

class _FailingNotificationRepository implements NotificationRepository {
  _FailingNotificationRepository(this._delegate);

  final NotificationRepository _delegate;

  @override
  Future<NotificationFeed> getNotifications() => _delegate.getNotifications();

  @override
  Future<void> markAsRead(String id) => _delegate.markAsRead(id);

  @override
  Future<void> markAllAsRead() => _delegate.markAllAsRead();

  @override
  Future<void> dismiss(String id) =>
      Future<void>.error(Exception('simulated backend failure'));

  @override
  Future<void> clearAll() => _delegate.clearAll();
}
