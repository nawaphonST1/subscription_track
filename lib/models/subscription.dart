import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'subscription.freezed.dart';
part 'subscription.g.dart';

typedef SubscriptionModel = Subscription;

enum UsageStatus {
  frequent,
  moderate,
  unused;

  String get nameValue {
    return switch (this) {
      UsageStatus.frequent => 'frequent',
      UsageStatus.moderate => 'moderate',
      UsageStatus.unused => 'unused',
    };
  }
}

@freezed
abstract class Subscription with _$Subscription {
  const factory Subscription({
    required String id,
    required String name,
    required double price,
    @Default('monthly') String billingPeriod,
    @Default('other') String category,
    DateTime? nextBillingDate,
    @Default('moderate') String usageStatus,
    @Default(50) int confidence,
    @Default(false) bool isSelected,
    @Default([]) List<Map<String, String>> customFields,
    @Default(true) bool reminderEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Subscription;

  factory Subscription.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionFromJson(json);
}

extension SubscriptionExtension on Subscription {
  double get monthlyPrice {
    return switch (billingPeriod.toLowerCase()) {
      'yearly' => price / 12,
      'quarterly' => price / 3,
      _ => price,
    };
  }

  double get yearlyPrice {
    return switch (billingPeriod.toLowerCase()) {
      'monthly' => price * 12,
      'quarterly' => price * 4,
      _ => price,
    };
  }

  IconData get iconData {
    final lowerName = name.toLowerCase();
    final lowerCat = category.toLowerCase();
    if (lowerName.contains('netflix') || lowerCat.contains('entertainment')) {
      return Icons.play_circle_fill;
    }
    if (lowerName.contains('spotify') || lowerCat.contains('music')) {
      return Icons.music_note;
    }
    if (lowerName.contains('chatgpt') || lowerCat.contains('ai')) {
      return Icons.chat_bubble;
    }
    if (lowerName.contains('google') || lowerCat.contains('cloud')) {
      return Icons.cloud;
    }
    if (lowerName.contains('adobe') || lowerCat.contains('design')) {
      return Icons.palette;
    }
    return Icons.subscriptions;
  }

  Color get iconColor {
    final lowerName = name.toLowerCase();
    final lowerCat = category.toLowerCase();
    if (lowerName.contains('netflix') || lowerCat.contains('entertainment')) {
      return const Color(0xFF3B82F6);
    }
    if (lowerName.contains('spotify') || lowerCat.contains('music')) {
      return const Color(0xFF10B981);
    }
    if (lowerName.contains('chatgpt') || lowerCat.contains('ai')) {
      return const Color(0xFF8B5CF6);
    }
    if (lowerName.contains('google') || lowerCat.contains('cloud')) {
      return const Color(0xFFF59E0B);
    }
    if (lowerName.contains('adobe') || lowerCat.contains('design')) {
      return const Color(0xFFEF4444);
    }
    return const Color(0xFF6366F1);
  }

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
