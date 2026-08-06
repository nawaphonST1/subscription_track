import 'package:flutter_test/flutter_test.dart';
import 'package:subscription_track/features/dashboard/application/dashboard_summary_provider.dart';
import 'package:subscription_track/features/subscriptions/domain/subscription.dart';

void main() {
  test('calculates totals, risk, savings, and renewal order', () {
    final later = DateTime(2026, 9, 20);
    final sooner = DateTime(2026, 9, 10);
    final summary = DashboardSummary.fromSubscriptions(
      monthlyIncome: 10000,
      subscriptions: [
        Subscription(
          id: 'yearly-unused',
          name: 'Annual Service',
          price: 1200,
          billingPeriod: 'yearly',
          usageStatus: UsageStatus.unused.nameValue,
          nextBillingDate: later,
        ),
        Subscription(
          id: 'monthly-active',
          name: 'Monthly Service',
          price: 400,
          usageStatus: UsageStatus.frequent.nameValue,
          nextBillingDate: sooner,
        ),
      ],
    );

    expect(summary.monthlyTotal, 500);
    expect(summary.creepScore, 5);
    expect(summary.unusedCount, 1);
    expect(summary.unusedMonthlySavings, 100);
    expect(summary.upcomingRenewals.map((item) => item.name), [
      'Monthly Service',
      'Annual Service',
    ]);
  });
}
