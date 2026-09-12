import 'package:freezed_annotation/freezed_annotation.dart';

part 'subscription.freezed.dart';
part 'subscription.g.dart';

/// Compatibility alias for call sites that still use the previous model name.
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
}
