import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subscription_track/features/auth/application/auth_provider.dart';

final userIncomeProvider = NotifierProvider<UserIncomeController, double>(
  UserIncomeController.new,
);

final class UserIncomeController extends Notifier<double> {
  @override
  double build() {
    // ดึงค่า User จากระบบ Auth แทนการตั้งค่าคงที่ 35000
    final user = ref.watch(authProvider).value;
    
    // ถ้าไม่มี User หรือไม่มีบัตรเครดิต ให้คืนค่า 0
    if (user == null || user.creditCards.isEmpty) {
      return 0.0;
    }

    // คำนวณยอดเงินรวม (Current Balance) จากบัตรเครดิตทุกใบ
    return user.creditCards.fold(
      0.0, 
      (sum, card) => sum + card.currentBalance,
    );
  }

  // ฟังก์ชันนี้เก็บไว้ตามเดิม เผื่อระบบเก่าเรียกใช้ จะได้ไม่เกิด Error (แม้เราจะไม่ได้ใช้บน UI แล้ว)
  bool update(double income) {
    if (!income.isFinite || income <= 0) return false;
    state = income;
    return true;
  }
}