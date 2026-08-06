import 'package:flutter_riverpod/flutter_riverpod.dart';

final notificationReminderProvider =
    NotifierProvider<NotificationReminderController, bool>(
      NotificationReminderController.new,
    );

final class NotificationReminderController extends Notifier<bool> {
  @override
  bool build() => true;

  void update({required bool enabled}) => state = enabled;
}
