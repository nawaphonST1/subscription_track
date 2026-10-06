import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subscription_track/features/auth/application/auth_provider.dart';

final userIncomeProvider = NotifierProvider<UserIncomeController, double>(
  UserIncomeController.new,
);

final class UserIncomeController extends Notifier<double> {
  static const double fallbackIncome = 35000.0;

  @override
  double build() {
    // 1. ดึงข้อมูลผู้ใช้จาก authProvider ซึ่งโหลดมาจาก GET /users/me ตอนเข้าสู่ระบบ/เปิดแอป
    // (RemoteAuthRepository.getCurrentUser() แมป 'monthly_income' มาใส่ใน user.income)
    final user = ref.watch(authProvider).value;
    if (user != null && user.income > 0) {
      return user.income;
    }

    // 2. หากยังไม่มี monthly_income ให้ดูจากผลรวมวงเงิน/ยอดในบัตรเครดิต (ถ้ามี)
    if (user != null && user.creditCards.isNotEmpty) {
      final totalBalance = user.creditCards.fold<double>(
        0,
        (sum, card) => sum + card.currentBalance,
      );
      if (totalBalance > 0) return totalBalance;
    }

    // 3. UI fallback ค่าเริ่มต้นสุดท้าย 35,000 บาท หากเน็ตหลุดหรือไม่พบค่ายอดเงิน
    return fallbackIncome;
  }

  /// อัปเดตรายได้ในหน่วยความจำ
  ///
  /// หมายเหตุการตัดสินใจ (Product Decision):
  /// ใน `income_editor_sheet.dart` ระบุชัดเจนว่า TextField เป็น readOnly พร้อมคำอธิบาย
  /// "ดึงข้อมูลจาก CreditCard ในระบบ ไม่อนุญาตให้แก้ไขโดยตรง" แสดงว่า intent เดิมของ Product
  /// คือให้คำนวณจากบัตรเครดิตที่ผูกไว้ จึงยังไม่ยิง `PATCH /users/income` โดยตรงจาก UI
  /// ในระหว่างรอข้อสรุป Product requirement ว่าจะเปิดให้พิมพ์แก้ไขหรือไม่
  /// คงฟังก์ชัน `update(income)` สำหรับการทำงานในหน่วยความจำและทดสอบไว้ตามเดิม
  bool update(double income) {
    if (!income.isFinite || income <= 0) return false;
    state = income;
    return true;
  }
}

