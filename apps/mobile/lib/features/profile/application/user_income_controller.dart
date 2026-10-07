import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subscription_track/features/auth/application/auth_provider.dart';
import 'package:subscription_track/features/profile/application/payment_card_linking_controller.dart';
import 'package:subscription_track/features/profile/domain/payment_card.dart';

final userIncomeProvider = NotifierProvider<UserIncomeController, double>(
  UserIncomeController.new,
);

/// รายได้หรือยอดเงินที่ใช้แสดงผลจริงในแอป:
/// 1. หากผู้ใช้ระบุ monthly_income (หรือแก้ผ่าน Controller) ให้ใช้ค่านั้น
/// 2. หากยังไม่มีรายได้ ให้คำนวณอัตโนมัติจากผลรวมยอดเงินคงเหลือในบัตรที่ผูกไว้ (linkedPaymentCardsProvider)
/// 3. หากยังไม่มีบัตร ให้ fallback เป็น 0.0
final effectiveIncomeProvider = Provider<double>((ref) {
  final baseIncome = ref.watch(userIncomeProvider);
  if (baseIncome > 0) return baseIncome;

  final cardsAsync = ref.watch(linkedPaymentCardsProvider);
  return cardsAsync.maybeWhen(
    data: (cards) {
      if (cards.isNotEmpty) {
        return cards.fold<double>(
          0,
          (sum, card) => sum + card.currentBalance,
        );
      }
      return 0.0;
    },
    orElse: () {
      final user = ref.watch(authProvider).value;
      if (user != null && user.creditCards.isNotEmpty) {
        final totalBalance = user.creditCards.fold<double>(
          0,
          (sum, card) => sum + card.currentBalance,
        );
        if (totalBalance > 0) return totalBalance;
      }
      return 0.0;
    },
  );
});

final class UserIncomeController extends Notifier<double> {
  static const double fallbackIncome = 0.0;

  @override
  double build() {
    // 1. ดึงข้อมูลผู้ใช้จาก authProvider ซึ่งโหลดมาจาก GET /users/me ตอนเข้าสู่ระบบ/เปิดแอป
    // (RemoteAuthRepository.getCurrentUser() แมป 'monthly_income' มาใส่ใน user.income)
    final user = ref.watch(authProvider).value;
    if (user != null && user.income > 0) {
      return user.income;
    }

    return fallbackIncome;
  }

  /// อัปเดตรายได้ในหน่วยความจำ
  bool update(double income) {
    if (!income.isFinite || income <= 0) return false;
    state = income;
    return true;
  }
}
