import 'package:flutter_riverpod/flutter_riverpod.dart';

final userIncomeProvider = NotifierProvider<UserIncomeController, double>(
  UserIncomeController.new,
);

final class UserIncomeController extends Notifier<double> {
  @override
  double build() => 35000;

  bool update(double income) {
    if (!income.isFinite || income <= 0) return false;
    state = income;
    return true;
  }
}
