import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subscription_track/core/utils/logger.dart';
import 'package:subscription_track/features/dashboard/data/remote_creep_score_repository.dart';
import 'package:subscription_track/features/dashboard/domain/creep_score_report.dart';
import 'package:subscription_track/features/profile/application/user_income_controller.dart';
import 'package:subscription_track/features/subscriptions/application/subscription_read_model.dart';

final creepScoreFutureProvider =
    FutureProvider.autoDispose<CreepScoreReport?>((ref) async {
  // Watch subscriptions so whenever subscriptions change, creep score is re-fetched automatically
  ref.watch(subscriptionReadModelsProvider);
  try {
    return await ref.watch(creepScoreRepositoryProvider).getCreepScore();
  } catch (e) {
    logger.w('CreepScore API unavailable, using client-side fallback: $e');
    return null;
  }
});

final dashboardSummaryProvider = Provider<AsyncValue<DashboardSummary>>((ref) {
  final subscriptionsAsync = ref.watch(subscriptionReadModelsProvider);
  final creepScoreAsync = ref.watch(creepScoreFutureProvider);
  final income = ref.watch(effectiveIncomeProvider);

  return subscriptionsAsync.when(
    loading: () => const AsyncLoading(),
    error: (err, stack) => AsyncError(err, stack),
    data: (subscriptions) {
      // หมายเหตุความไม่ตรงกันของ API (Discrepancy Documented Fallback):
      // Backend GET /creep-score คืน monthly_total, creep_score, risk_level,
      // category_breakdown, upcoming_renewals แต่ไม่มีข้อมูล unused subscriptions
      // จึงคำนวณ unusedCount และ unusedMonthlySavings จาก subscriptionReadModels ฝั่ง client
      // ตามเดิมเป็น deliberate fallback
      final unused =
          subscriptions.where((item) => item.usageStatus == 'unused');
      final unusedCount = unused.length;
      final unusedMonthlySavings = unused.fold<double>(
        0,
        (total, item) => total + item.monthlyPrice,
      );

      return creepScoreAsync.when(
        loading: () => AsyncData(
          DashboardSummary.fromSubscriptions(
            subscriptions: subscriptions,
            monthlyIncome: income,
          ),
        ),
        error: (_, __) => AsyncData(
          DashboardSummary.fromSubscriptions(
            subscriptions: subscriptions,
            monthlyIncome: income,
          ),
        ),
        data: (report) {
          if (report == null) {
            return AsyncData(
              DashboardSummary.fromSubscriptions(
                subscriptions: subscriptions,
                monthlyIncome: income,
              ),
            );
          }

          return AsyncData(
            DashboardSummary(
              monthlyTotal: report.monthlyTotal,
              creepScore: report.creepScore,
              unusedCount: unusedCount,
              unusedMonthlySavings: unusedMonthlySavings,
              upcomingRenewals: report.upcomingRenewals.isNotEmpty
                  ? report.upcomingRenewals
                  : subscriptions
                      .map(DashboardRenewal.fromSubscription)
                      .toList(growable: false),
              riskLevel: report.riskLevel,
              monthlyIncome: report.monthlyIncome,
              totalCardFunds: report.totalCardFunds,
              denominatorUsed: report.denominatorUsed,
              activeSubscriptionsCount: report.activeSubscriptionsCount,
              categoryBreakdown: report.categoryBreakdown,
            ),
          );
        },
      );
    },
  );
});

class DashboardSummary {
  const DashboardSummary({
    required this.monthlyTotal,
    required this.creepScore,
    required this.unusedCount,
    required this.unusedMonthlySavings,
    required this.upcomingRenewals,
    this.riskLevel,
    this.monthlyIncome,
    this.totalCardFunds,
    this.denominatorUsed,
    this.activeSubscriptionsCount,
    this.categoryBreakdown = const [],
  });

  factory DashboardSummary.fromSubscriptions({
    required List<SubscriptionReadModel> subscriptions,
    required double monthlyIncome,
  }) {
    final monthlyTotal = subscriptions.fold<double>(
      0,
      (total, item) => total + item.monthlyPrice,
    );
    final unused = subscriptions.where((item) => item.usageStatus == 'unused');
    final upcoming =
        subscriptions
            .map(DashboardRenewal.fromSubscription)
            .toList(growable: false)
          ..sort((a, b) {
            final aDate = a.nextBillingDate ?? DateTime(9999);
            final bDate = b.nextBillingDate ?? DateTime(9999);
            return aDate.compareTo(bDate);
          });

    return DashboardSummary(
      monthlyTotal: monthlyTotal,
      creepScore: monthlyIncome > 0 ? monthlyTotal / monthlyIncome * 100 : 0,
      unusedCount: unused.length,
      unusedMonthlySavings: unused.fold<double>(
        0,
        (total, item) => total + item.monthlyPrice,
      ),
      upcomingRenewals: upcoming,
    );
  }

  final double monthlyTotal;
  final double creepScore;
  final int unusedCount;
  final double unusedMonthlySavings;
  final List<DashboardRenewal> upcomingRenewals;
  final String? riskLevel;
  final double? monthlyIncome;
  final double? totalCardFunds;
  final String? denominatorUsed;
  final int? activeSubscriptionsCount;
  final List<CategoryBreakdownItem> categoryBreakdown;
}

class DashboardRenewal {
  const DashboardRenewal({
    required this.name,
    required this.category,
    required this.nextBillingDate,
    this.id,
    this.price,
    this.billingCycle,
    this.daysUntilRenewal,
    this.cardNickname,
    this.last4Digits,
  });

  factory DashboardRenewal.fromSubscription(
    SubscriptionReadModel subscription,
  ) {
    return DashboardRenewal(
      id: subscription.id,
      name: subscription.name,
      category: subscription.category,
      price: subscription.monthlyPrice,
      billingCycle: 'monthly',
      nextBillingDate: subscription.nextBillingDate,
    );
  }

  factory DashboardRenewal.fromJson(Map<String, dynamic> json) {
    final nextDateRaw = json['next_renewal_date'];
    return DashboardRenewal(
      id: json['id'] as String?,
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? 'other',
      price: (json['price'] as num?)?.toDouble(),
      billingCycle: json['billing_cycle'] as String?,
      daysUntilRenewal: json['days_until_renewal'] as int?,
      cardNickname: json['card_nickname'] as String?,
      last4Digits: json['last_4_digits'] as String?,
      nextBillingDate: nextDateRaw != null
          ? DateTime.tryParse(nextDateRaw.toString())
          : null,
    );
  }

  final String? id;
  final String name;
  final String category;
  final double? price;
  final String? billingCycle;
  final DateTime? nextBillingDate;
  final int? daysUntilRenewal;
  final String? cardNickname;
  final String? last4Digits;
}

