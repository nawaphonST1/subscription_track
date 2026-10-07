/// แปลงค่า enum ระหว่างฝั่ง Dart (lowercase, ใช้ในแอป) กับฝั่ง backend
/// (`BillingCycle`/`UsageStatus` ของ Prisma — ตัวพิมพ์ใหญ่ทั้งหมด)
///
/// เขียนเป็นฟังก์ชัน mapping ที่ชัดเจนทั้งสองทิศทางแทนการแปลง string แบบ
/// ad-hoc กระจายอยู่หลายที่ เพื่อไม่ให้ค่าที่ map ไม่ได้ถูก "default เงียบ ๆ"
/// โดยไม่มีใครรู้ตัว (ปัญหาเดิมก่อนแก้ไขรอบนี้)
library;

/// `BillingCycle` ฝั่ง backend: MONTHLY | YEARLY | WEEKLY (ดู
/// `apps/server/prisma/schema.prisma`) ฝั่งแอปใช้ 'monthly'/'yearly' เป็นหลัก
/// (ตัวเลือกใน `SubscriptionGeneralFields` มีแค่ 2 ค่านี้) ส่วน 'weekly' ยังไม่
/// มีช่องให้เลือกใน UI ตอนนี้ แต่รองรับไว้เผื่ออนาคตเพราะ backend รองรับอยู่แล้ว
///
/// 'quarterly' ที่เคยอยู่ใน `SubscriptionExtension.monthlyPrice/yearlyPrice`
/// ไม่มี backend enum ให้ตรงเลย และไม่มีทางเลือกนี้ใน UI การเพิ่ม/แก้ไขรายการ
/// จริง (ตรวจสอบแล้ว) — ถ้าค่านี้หลุดมาถึงจุดส่ง backend จริง ๆ ถือเป็นบั๊กที่
/// ต้องเห็นชัด ๆ ไม่ใช่ถูกปัดเป็น MONTHLY แบบเงียบ ๆ จึง throw แทน
String billingCycleToBackend(String billingPeriod) {
  return switch (billingPeriod.toLowerCase()) {
    'monthly' => 'MONTHLY',
    'yearly' => 'YEARLY',
    'weekly' => 'WEEKLY',
    _ => throw ArgumentError(
        'billingPeriod "$billingPeriod" has no backend BillingCycle '
        'equivalent (expected monthly/yearly/weekly)',
      ),
  };
}

/// ทิศตรงข้าม: backend ส่งมาแค่ 3 ค่านี้เสมอ (Prisma enum บังคับไว้) จึงไม่มี
/// เคส "ค่าแปลกที่ map ไม่ได้" ในทิศนี้ — แต่ยัง throw แทน default เงียบ ๆ
/// เผื่อ backend เพิ่ม enum ใหม่ในอนาคตแล้วแอปยังไม่ได้อัปเดตตาม
String billingCycleFromBackend(String backendValue) {
  return switch (backendValue.toUpperCase()) {
    'MONTHLY' => 'monthly',
    'YEARLY' => 'yearly',
    'WEEKLY' => 'weekly',
    _ => throw ArgumentError(
        'Unknown backend billing_cycle "$backendValue"',
      ),
  };
}

/// `UsageStatus` ฝั่ง backend: FREQUENT | OCCASIONAL | UNUSED
///
/// ฝั่งแอปมี 3 ค่าเหมือนกันแต่ค่ากลางเรียกว่า 'moderate' (ไม่ใช่ 'occasional')
/// — เป็นชื่อเดียวที่ไม่ตรงกันตรง ๆ จึง map 'moderate' <-> 'OCCASIONAL' ชัดเจน
/// ตรงนี้ที่เดียว (ยืนยันจาก `UsageStatus` enum ใน schema.prisma: ไม่มีค่า
/// 'MODERATE')
String usageStatusToBackend(String usageStatus) {
  return switch (usageStatus.toLowerCase()) {
    'frequent' => 'FREQUENT',
    'moderate' => 'OCCASIONAL',
    'unused' => 'UNUSED',
    _ => throw ArgumentError(
        'usageStatus "$usageStatus" has no backend UsageStatus equivalent '
        '(expected frequent/moderate/unused)',
      ),
  };
}

String usageStatusFromBackend(String backendValue) {
  return switch (backendValue.toUpperCase()) {
    'FREQUENT' => 'frequent',
    'OCCASIONAL' => 'moderate',
    'UNUSED' => 'unused',
    _ => throw ArgumentError(
        'Unknown backend usage_status "$backendValue"',
      ),
  };
}
