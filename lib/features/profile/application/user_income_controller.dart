import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subscription_track/features/auth/application/auth_provider.dart';

final userIncomeProvider = NotifierProvider<UserIncomeController, double>(
  UserIncomeController.new,
);

final class UserIncomeController extends Notifier<double> {
  @override
  double build() {
    final user = ref.watch(authProvider).value;
    if (user != null && user.creditCards.isNotEmpty) {
      final totalBalance = user.creditCards.fold<double>(
        0,
        (sum, card) => sum + card.currentBalance,
      );
      if (totalBalance > 0) return totalBalance;
    }
    return 35000;
  }

  bool update(double income) {
    if (!income.isFinite || income <= 0) return false;
    state = income;
    return true;
  }
}
