import 'package:flutter_riverpod/flutter_riverpod.dart';

final currentTabProvider = NotifierProvider<CurrentTabController, int>(
  CurrentTabController.new,
);

final class CurrentTabController extends Notifier<int> {
  @override
  int build() => 0;

  void select(int index) {
    if (index >= 0 && index < 5) state = index;
  }
}
