import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:subscription_track/core/utils/logger.dart';
import 'package:subscription_track/features/subscriptions/domain/preset_plan.dart';

part 'preset_package.freezed.dart';

@freezed
abstract class PresetPackage with _$PresetPackage {
  const factory PresetPackage({
    required String name,
    required double price,
    required String billingPeriod,
    required String category,
    String? id,
    String? brandColor,
    String? iconUrl,
    String? description,
    @Default([]) List<PresetPlan> plans,
    @Default([]) List<String> features,
    @Default(1) int maxSlots,
  }) = _PresetPackage;

  static String _normalizeBillingPeriod(dynamic raw) {
    if (raw == null) return 'Monthly';
    final s = raw.toString().trim().toLowerCase();
    switch (s) {
      case 'monthly':
        return 'Monthly';
      case 'yearly':
        return 'Yearly';
      case 'weekly':
        return 'Weekly';
      default:
        logger.w(
          'PresetPackage: unrecognized billing_cycle "$raw", falling back to "Monthly"',
        );
        return 'Monthly';
    }
  }

  factory PresetPackage.fromJson(Map<String, dynamic> json) {
    final priceVal = json['default_price'] ?? json['price'];
    final billingVal = json['billing_cycle'] ?? json['billingPeriod'];
    final plansRaw = json['available_plans'] ?? json['plans'];
    final featuresRaw = json['features'];
    final maxSlotsRaw = json['max_slots'] ?? json['maxSlots'];

    return PresetPackage(
      id: json['id'] as String?,
      name: json['name'] as String? ?? '',
      price: (priceVal as num?)?.toDouble() ?? 0.0,
      billingPeriod: _normalizeBillingPeriod(billingVal),
      category: (json['category'] as String?)?.toLowerCase() ?? 'entertainment',
      brandColor: json['brand_color'] as String? ?? json['brandColor'] as String?,
      iconUrl: json['icon_url'] as String? ?? json['iconUrl'] as String?,
      description: json['description'] as String?,
      plans: plansRaw is List
          ? plansRaw
              .whereType<Map>()
              .map((e) => PresetPlan.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
      features: featuresRaw is List
          ? featuresRaw.whereType<String>().toList()
          : const [],
      maxSlots: (maxSlotsRaw as num?)?.toInt() ?? 1,
    );
  }
}

extension PresetPackageX on PresetPackage {
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'name': name,
    'default_price': price,
    'billing_cycle': billingPeriod.toUpperCase(),
    'category': category,
    if (brandColor != null) 'brand_color': brandColor,
    if (iconUrl != null) 'icon_url': iconUrl,
    if (description != null) 'description': description,
  };

  bool get hasMultiplePlans => plans.length > 1;

  /// The plan tier this package's legacy `price`/`billingPeriod` fields
  /// correspond to, or a synthesized single plan when the backend hasn't
  /// provided `available_plans` (older API responses).
  PresetPlan get defaultPlan {
    if (plans.isEmpty) {
      return PresetPlan(
        tier: name,
        monthlyPrice: price,
        maxSlots: maxSlots,
        features: features,
      );
    }
    return plans.firstWhere(
      (p) => p.monthlyPrice == price,
      orElse: () => plans.first,
    );
  }

  double get lowestMonthlyPrice {
    if (plans.isEmpty) return price;
    return plans.map((p) => p.monthlyPrice).reduce((a, b) => a < b ? a : b);
  }
}
