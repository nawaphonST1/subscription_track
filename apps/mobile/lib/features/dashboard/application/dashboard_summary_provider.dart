import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subscription_track/features/profile/application/user_income_controller.dart';
import 'package:subscription_track/features/subscriptions/application/subscription_read_model.dart';

final dashboardSummaryProvider = Provider<AsyncValue<DashboardSummary>>((ref) {
  final income = ref.watch(userIncomeProvider);
  return ref
      .watch(subscriptionReadModelsProvider)
      .whenData(
        (subscriptions) => DashboardSummary.fromSubscriptions(
          subscriptions: subscriptions,
          monthlyIncome: income,
        ),
      );
});

class DashboardSummary {
  const DashboardSummary({
    required this.monthlyTotal,
    required this.creepScore,
    required this.unusedCount,
    required this.unusedMonthlySavings,
    required this.upcomingRenewals,
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
}

class DashboardRenewal {
  const DashboardRenewal({
    required this.name,
    required this.category,
    required this.nextBillingDate,
  });

  factory DashboardRenewal.fromSubscription(
    SubscriptionReadModel subscription,
  ) {
    return DashboardRenewal(
      name: subscription.name,
      category: subscription.category,
      nextBillingDate: subscription.nextBillingDate,
    );
  }

  final String name;
  final String category;
  final DateTime? nextBillingDate;
}
