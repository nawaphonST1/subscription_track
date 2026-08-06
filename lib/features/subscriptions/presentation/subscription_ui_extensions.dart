import 'package:flutter/material.dart';
import 'package:subscription_track/features/subscriptions/domain/subscription.dart';

extension SubscriptionUiExtension on Subscription {
  Color get usageStatusColor {
    return switch (usageStatus.toLowerCase()) {
      'frequent' => const Color(0xFF10B981),
      'moderate' => const Color(0xFFF59E0B),
      'unused' => const Color(0xFFEF4444),
      _ => const Color(0xFF64748B),
    };
  }

  String get usageStatusText {
    return switch (usageStatus.toLowerCase()) {
      'frequent' => 'ใช้งานบ่อย',
      'moderate' => 'ใช้งานปานกลาง',
      'unused' => 'ไม่ได้ใช้งาน',
      _ => usageStatus,
    };
  }
}
