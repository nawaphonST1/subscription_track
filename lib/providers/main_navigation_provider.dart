import 'package:flutter_riverpod/flutter_riverpod.dart';

final currentTabProvider = NotifierProvider<CurrentTabController, int>(
  CurrentTabController.new,
);

final userIncomeProvider = NotifierProvider<UserIncomeController, double>(
  UserIncomeController.new,
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

final class UserIncomeController extends Notifier<double> {
  @override
  double build() => 35000;

  bool update(double income) {
    if (!income.isFinite || income <= 0) return false;
    state = income;
    return true;
  }
}

final class NotificationReminderController extends Notifier<bool> {
  @override
  bool build() => true;

  void update({required bool enabled}) => state = enabled;
}
