import 'package:freezed_annotation/freezed_annotation.dart';

part 'preset_plan.freezed.dart';

/// One tier of a [PresetPackage] (e.g. Netflix's "Standard" or "Premium"
/// plan), parsed from `SubscriptionPreset.available_plans` on the backend.
@freezed
abstract class PresetPlan with _$PresetPlan {
  const factory PresetPlan({
    required String tier,
    required double monthlyPrice,
    double? yearlyPrice,
    @Default(1) int maxSlots,
    @Default([]) List<String> features,
  }) = _PresetPlan;

  factory PresetPlan.fromJson(Map<String, dynamic> json) {
    final monthlyRaw = json['monthlyPrice'] ?? json['monthly_price'];
    final yearlyRaw = json['yearlyPrice'] ?? json['yearly_price'];
    final maxSlotsRaw = json['maxSlots'] ?? json['max_slots'];
    final featuresRaw = json['features'];

    return PresetPlan(
      tier: json['tier'] as String? ?? '',
      monthlyPrice: (monthlyRaw as num?)?.toDouble() ?? 0.0,
      yearlyPrice: (yearlyRaw as num?)?.toDouble(),
      maxSlots: (maxSlotsRaw as num?)?.toInt() ?? 1,
      features: featuresRaw is List
          ? featuresRaw.whereType<String>().toList()
          : const [],
    );
  }
}
