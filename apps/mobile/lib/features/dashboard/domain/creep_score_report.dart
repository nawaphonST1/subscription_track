import 'package:subscription_track/features/dashboard/application/dashboard_summary_provider.dart';

class CreepScoreReport {
  const CreepScoreReport({
    required this.monthlyTotal,
    required this.creepScore,
    required this.riskLevel,
    required this.monthlyIncome,
    required this.totalCardFunds,
    required this.denominatorUsed,
    required this.activeSubscriptionsCount,
    required this.categoryBreakdown,
    required this.upcomingRenewals,
  });

  final double monthlyTotal;
  final double creepScore;
  final String riskLevel;
  final double monthlyIncome;
  final double totalCardFunds;
  final String denominatorUsed;
  final int activeSubscriptionsCount;
  final List<CategoryBreakdownItem> categoryBreakdown;
  final List<DashboardRenewal> upcomingRenewals;

  factory CreepScoreReport.fromJson(Map<String, dynamic> json) {
    return CreepScoreReport(
      monthlyTotal: (json['monthly_total'] as num?)?.toDouble() ?? 0.0,
      creepScore: (json['creep_score'] as num?)?.toDouble() ?? 0.0,
      riskLevel: json['risk_level'] as String? ?? 'SAFE',
      monthlyIncome: (json['monthly_income'] as num?)?.toDouble() ?? 0.0,
      totalCardFunds: (json['total_card_funds'] as num?)?.toDouble() ?? 0.0,
      denominatorUsed: json['denominator_used'] as String? ?? 'none',
      activeSubscriptionsCount:
          json['active_subscriptions_count'] as int? ?? 0,
      categoryBreakdown: (json['category_breakdown'] as List<dynamic>?)
              ?.map((item) =>
                  CategoryBreakdownItem.fromJson(item as Map<String, dynamic>))
              .toList(growable: false) ??
          const [],
      upcomingRenewals: (json['upcoming_renewals'] as List<dynamic>?)
              ?.map((item) =>
                  DashboardRenewal.fromJson(item as Map<String, dynamic>))
              .toList(growable: false) ??
          const [],
    );
  }
}

class CategoryBreakdownItem {
  const CategoryBreakdownItem({
    required this.category,
    required this.amount,
    required this.percentage,
  });

  factory CategoryBreakdownItem.fromJson(Map<String, dynamic> json) {
    return CategoryBreakdownItem(
      category: json['category'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }

  final String category;
  final double amount;
  final double percentage;
}
