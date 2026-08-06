import 'package:subscription_track/features/notifications/domain/app_notification.dart';

List<AppNotification> createMockNotifications({DateTime? now}) {
  final reference = now ?? DateTime.now();
  return [
    AppNotification(
      id: '1',
      type: 'upcoming_bill',
      title: 'Netflix กำลังจะต่ออายุในอีก 3 วัน',
      body: 'ยอดชำระ ฿419 จะถูกหักอัตโนมัติผ่านบัตรเครดิตของคุณ',
      scheduledAt: reference.add(const Duration(days: 3)),
    ),
    AppNotification(
      id: '2',
      type: 'unused_warning',
      title: 'Adobe Creative Cloud ไม่ได้ใช้งานมาระยะหนึ่งแล้ว',
      body: 'คุณไม่ได้เปิดใช้งานบริการนี้ใน 30 วัน แนะนำให้ตรวจสอบแผนการใช้งาน',
      scheduledAt: reference.subtract(const Duration(hours: 4)),
    ),
    AppNotification(
      id: '3',
      type: 'price_change',
      title: 'ChatGPT Plus แจ้งปรับเปลี่ยนราคา',
      body: 'การปรับราคาจะเริ่มมีผลในรอบบิลถัดไป',
      scheduledAt: reference.subtract(const Duration(days: 1)),
      isRead: true,
    ),
    AppNotification(
      id: '4',
      type: 'upcoming_bill',
      title: 'Spotify Premium จะต่ออายุพรุ่งนี้',
      body: 'เตรียมเงิน ฿139 สำหรับรอบบิลถัดไป',
      scheduledAt: reference.add(const Duration(days: 1)),
      isRead: true,
    ),
    AppNotification(
      id: '5',
      title: 'ยินดีต้อนรับสู่ Subscription Track',
      body: 'เริ่มต้นตั้งค่ารายได้และการแจ้งเตือนได้จากหน้าตั้งค่า',
      scheduledAt: reference.subtract(const Duration(days: 3)),
      isRead: true,
    ),
  ];
}
