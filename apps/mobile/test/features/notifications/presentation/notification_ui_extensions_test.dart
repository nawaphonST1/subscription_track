import 'package:flutter_test/flutter_test.dart';
import 'package:subscription_track/features/notifications/presentation/notification_ui_extensions.dart';

void main() {
  test('formats dates relative to calendar days', () {
    final now = DateTime(2026, 8, 6, 20);

    expect(
      formatNotificationDate(DateTime(2026, 8, 6, 9, 5), now: now),
      'วันนี้ - 09:05 น.',
    );
    expect(
      formatNotificationDate(DateTime(2026, 8, 7, 9), now: now),
      'พรุ่งนี้ - 09:00 น.',
    );
    expect(
      formatNotificationDate(DateTime(2026, 8, 3), now: now),
      '3 วันที่แล้ว',
    );
    expect(formatNotificationDate(null, now: now), 'ไม่ระบุเวลา');
  });
}
