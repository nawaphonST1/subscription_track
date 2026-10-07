import 'package:subscription_track/core/utils/logger.dart';
import 'package:subscription_track/features/subscriptions/domain/subscription_enum_mapper.dart';

class SavingsPaymentCard {
  const SavingsPaymentCard({
    this.cardNickname,
    required this.last4Digits,
    required this.bankName,
  });

  final String? cardNickname;
  final String last4Digits;
  final String bankName;

  factory SavingsPaymentCard.fromJson(Map<String, dynamic> json) {
    return SavingsPaymentCard(
      cardNickname: json['card_nickname'] as String?,
      last4Digits: json['last_4_digits'] as String? ?? '',
      bankName: json['bank_name'] as String? ?? '',
    );
  }

  String get displayName {
    if (cardNickname != null && cardNickname!.isNotEmpty) {
      return '$cardNickname (•• $last4Digits)';
    }
    return '$bankName (•• $last4Digits)';
  }

  Map<String, dynamic> toJson() => {
    if (cardNickname != null) 'card_nickname': cardNickname,
    'last_4_digits': last4Digits,
    'bank_name': bankName,
  };
}

class SavingsOptimizerItem {
  const SavingsOptimizerItem({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.billingCycle,
    required this.normalizedMonthlyCost,
    required this.yearlySavingsProjection,
    this.brandColor,
    this.paymentCard,
  });

  final String id;
  final String name;
  final String category;
  final double price;
  final String billingCycle;
  final double normalizedMonthlyCost;
  final double yearlySavingsProjection;
  final String? brandColor;
  final SavingsPaymentCard? paymentCard;

  static String _normalizeBillingCycle(dynamic raw) {
    if (raw == null) {
      logger.w('SavingsOptimizerItem: billing_cycle is null, defaulting to "monthly"');
      return 'monthly';
    }
    try {
      return billingCycleFromBackend(raw.toString());
    } catch (_) {
      logger.w(
        'SavingsOptimizerItem: unrecognized billing_cycle "$raw", falling back to "monthly"',
      );
      return 'monthly';
    }
  }

  factory SavingsOptimizerItem.fromJson(Map<String, dynamic> json) {
    final rawCard = json['payment_card'] as Map<String, dynamic>?;
    return SavingsOptimizerItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      category: (json['category'] as String?)?.toLowerCase() ?? 'other',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      billingCycle: _normalizeBillingCycle(json['billing_cycle']),
      normalizedMonthlyCost:
          (json['normalized_monthly_cost'] as num?)?.toDouble() ?? 0.0,
      yearlySavingsProjection:
          (json['yearly_savings_projection'] as num?)?.toDouble() ?? 0.0,
      brandColor: json['brand_color'] as String?,
      paymentCard: rawCard != null ? SavingsPaymentCard.fromJson(rawCard) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'price': price,
    'billing_cycle': billingCycle.toUpperCase(),
    'normalized_monthly_cost': normalizedMonthlyCost,
    'yearly_savings_projection': yearlySavingsProjection,
    if (brandColor != null) 'brand_color': brandColor,
    if (paymentCard != null) 'payment_card': paymentCard!.toJson(),
  };
}

class SavingsOptimizerReport {
  const SavingsOptimizerReport({
    required this.unusedSubscriptionsCount,
    required this.totalMonthlySavings,
    required this.totalYearlySavingsProjection,
    required this.recommendedCancellations,
  });

  final int unusedSubscriptionsCount;
  final double totalMonthlySavings;
  final double totalYearlySavingsProjection;
  final List<SavingsOptimizerItem> recommendedCancellations;

  factory SavingsOptimizerReport.fromJson(Map<String, dynamic> json) {
    // หมายเหตุความไม่ตรงกันของ Schema (Discrepancy Handling):
    // Backend จริงคืนคีย์ `recommended_cancellations`, `total_monthly_savings`, `total_yearly_savings_projection`
    // ขณะที่ read-only audit ระบุ `unused_subscriptions`, `potential_monthly_savings`, `potential_yearly_savings`
    // รองรับทั้งสองแบบเพื่อความยืดหยุ่นสูงสุด
    final rawList = (json['recommended_cancellations'] as List<dynamic>?) ??
        (json['unused_subscriptions'] as List<dynamic>?) ??
        const [];

    final monthly = json['total_monthly_savings'] ??
        json['potential_monthly_savings'];
    final yearly = json['total_yearly_savings_projection'] ??
        json['potential_yearly_savings'];

    return SavingsOptimizerReport(
      unusedSubscriptionsCount:
          (json['unused_subscriptions_count'] as num?)?.toInt() ??
              rawList.length,
      totalMonthlySavings: (monthly as num?)?.toDouble() ?? 0.0,
      totalYearlySavingsProjection: (yearly as num?)?.toDouble() ?? 0.0,
      recommendedCancellations: rawList
          .map((item) => SavingsOptimizerItem.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
    );
  }
}

class BatchCancelResult {
  const BatchCancelResult({
    required this.message,
    required this.cancelledCount,
    required this.totalYearlySavingsUnlocked,
  });

  final String message;
  final int cancelledCount;
  final double totalYearlySavingsUnlocked;

  factory BatchCancelResult.fromJson(Map<String, dynamic> json) {
    return BatchCancelResult(
      message: json['message'] as String? ?? 'Subscriptions successfully cancelled',
      cancelledCount: (json['cancelled_count'] as num?)?.toInt() ?? 0,
      totalYearlySavingsUnlocked:
          (json['total_yearly_savings_unlocked'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
