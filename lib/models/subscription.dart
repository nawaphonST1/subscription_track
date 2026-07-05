import 'package:flutter/material.dart';

enum UsageStatus {
  frequent,    // ใช้งานบ่อย
  moderate,    // ใช้งานปานกลาง
  unused,      // ไม่ได้ใช้งาน
}

class SubscriptionModel {
  final String id;
  final String name;
  final double price;
  final int confidence;
  final UsageStatus usageStatus;
  final String billingPeriod;
  final IconData iconData;
  final Color iconColor;
  bool isSelected;

  SubscriptionModel({
    required this.id,
    required this.name,
    required this.price,
    required this.confidence,
    required this.usageStatus,
    required this.billingPeriod,
    required this.iconData,
    required this.iconColor,
    this.isSelected = false,
  });

  String get usageStatusText {
    switch (usageStatus) {
      case UsageStatus.frequent:
        return 'ใช้งานบ่อย';
      case UsageStatus.moderate:
        return 'ใช้งานปานกลาง';
      case UsageStatus.unused:
        return 'ไม่ได้ใช้งาน';
    }
  }

  Color get usageStatusColor {
    switch (usageStatus) {
      case UsageStatus.frequent:
        return const Color(0xFF10B981); // Emerald Green
      case UsageStatus.moderate:
        return const Color(0xFFD97706); // Amber/Yellow
      case UsageStatus.unused:
        return const Color(0xFFEF4444); // Rose Red
    }
  }
}
