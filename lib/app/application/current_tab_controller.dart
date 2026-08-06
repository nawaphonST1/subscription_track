import 'package:flutter_riverpod/flutter_riverpod.dart';

const mainTabCount = 5;

final currentTabProvider = NotifierProvider<CurrentTabController, int>(
  CurrentTabController.new,
);

final class CurrentTabController extends Notifier<int> {
  @override
  int build() => 0;

  void select(int index) {
    if (index >= 0 && index < mainTabCount) state = index;
  }
}
