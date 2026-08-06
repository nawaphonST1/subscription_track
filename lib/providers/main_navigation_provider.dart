import 'package:flutter_riverpod/flutter_riverpod.dart';

final currentTabProvider = NotifierProvider<CurrentTabController, int>(
  CurrentTabController.new,
);

final notificationReminderProvider =
    NotifierProvider<NotificationReminderController, bool>(
      NotificationReminderController.new,
    );

final class CurrentTabController extends Notifier<int> {
  @override
  int build() => 0;

  void select(int index) {
    if (index >= 0 && index < 5) state = index;
  }
}

final class NotificationReminderController extends Notifier<bool> {
  @override
  bool build() => true;

  void update({required bool enabled}) => state = enabled;
}
