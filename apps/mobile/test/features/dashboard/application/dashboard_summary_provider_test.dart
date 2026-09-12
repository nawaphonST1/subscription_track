import 'package:flutter_test/flutter_test.dart';
import 'package:subscription_track/features/dashboard/application/dashboard_summary_provider.dart';
import 'package:subscription_track/features/subscriptions/application/subscription_read_model.dart';

void main() {
  test('calculates totals, risk, savings, and renewal order', () {
    final later = DateTime(2026, 9, 20);
    final sooner = DateTime(2026, 9, 10);
    final summary = DashboardSummary.fromSubscriptions(
      monthlyIncome: 10000,
      subscriptions: [
        SubscriptionReadModel(
          id: 'yearly-unused',
          name: 'Annual Service',
          category: 'other',
          monthlyPrice: 100,
          usageStatus: 'unused',
          isSelected: false,
          nextBillingDate: later,
        ),
        SubscriptionReadModel(
          id: 'monthly-active',
          name: 'Monthly Service',
          category: 'other',
          monthlyPrice: 400,
          usageStatus: 'frequent',
          isSelected: false,
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
