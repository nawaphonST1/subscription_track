import 'package:flutter/material.dart';
import 'package:subscription_track/features/notifications/domain/app_notification.dart';

extension AppNotificationUi on AppNotification {
  IconData get icon => switch (type) {
    'upcoming_bill' => Icons.calendar_month_rounded,
    'unused_warning' => Icons.warning_amber_rounded,
    'price_change' => Icons.trending_up_rounded,
    _ => Icons.notifications_none_rounded,
  };

  Color get accentColor => switch (type) {
    'upcoming_bill' => const Color(0xFFF59E0B),
    'unused_warning' => const Color(0xFFEF4444),
    'price_change' => const Color(0xFF8B5CF6),
    _ => const Color(0xFF3B82F6),
  };
}

String formatNotificationDate(DateTime? date, {DateTime? now}) {
  if (date == null) return 'ไม่ระบุเวลา';
  final reference = now ?? DateTime.now();
  final dateOnly = DateTime(date.year, date.month, date.day);
  final referenceOnly = DateTime(
    reference.year,
    reference.month,
    reference.day,
  );
  final dayDifference = dateOnly.difference(referenceOnly).inDays;
  final time =
      '${date.hour.toString().padLeft(2, '0')}:'
      '${date.minute.toString().padLeft(2, '0')} น.';

  return switch (dayDifference) {
    0 => 'วันนี้ - $time',
    1 => 'พรุ่งนี้ - $time',
    -1 => 'เมื่อวานนี้ - $time',
    > 1 && <= 7 => 'อีก $dayDifference วันข้างหน้า',
    < -1 && >= -7 => '${dayDifference.abs()} วันที่แล้ว',
    _ => '${date.day}/${date.month}/${date.year}',
  };
}
