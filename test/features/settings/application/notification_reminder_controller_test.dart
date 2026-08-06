import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subscription_track/features/settings/application/notification_reminder_controller.dart';

void main() {
  test('updates reminder preference', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(notificationReminderProvider), isTrue);
    container
        .read(notificationReminderProvider.notifier)
        .update(enabled: false);
    expect(container.read(notificationReminderProvider), isFalse);
  });
}
