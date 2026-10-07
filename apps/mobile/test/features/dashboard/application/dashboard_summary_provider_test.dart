import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subscription_track/features/dashboard/application/dashboard_summary_provider.dart';
import 'package:subscription_track/features/dashboard/data/remote_creep_score_repository.dart';
import 'package:subscription_track/features/dashboard/domain/creep_score_report.dart';
import 'package:subscription_track/features/dashboard/domain/creep_score_repository.dart';
import 'package:subscription_track/features/subscriptions/application/subscription_read_model.dart';

class _FakeCreepScoreRepository implements CreepScoreRepository {
  _FakeCreepScoreRepository({this.report, this.error});

  final CreepScoreReport? report;
  final Exception? error;

  @override
  Future<CreepScoreReport> getCreepScore() async {
    if (error != null) throw error!;
    return report!;
  }
}

void main() {
  final testSubs = [
    SubscriptionReadModel(
      id: 'sub-1',
      name: 'Annual Service',
      category: 'cloud',
      monthlyPrice: 100,
      usageStatus: 'unused',
      isSelected: false,
      nextBillingDate: DateTime(2026, 9, 20),
    ),
    SubscriptionReadModel(
      id: 'sub-2',
      name: 'Monthly Service',
      category: 'entertainment',
      monthlyPrice: 400,
      usageStatus: 'frequent',
      isSelected: false,
      nextBillingDate: DateTime(2026, 9, 10),
    ),
  ];

  test('DashboardSummary.fromSubscriptions calculates client-side fallback correctly', () {
    final summary = DashboardSummary.fromSubscriptions(
      monthlyIncome: 10000,
      subscriptions: testSubs,
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

  group('dashboardSummaryProvider', () {
    test('successfully maps real backend CreepScoreReport and computes unused savings client-side', () async {
      const testReport = CreepScoreReport(
        monthlyTotal: 500.0,
        creepScore: 8.5,
        riskLevel: 'SAFE',
        monthlyIncome: 35000.0,
        totalCardFunds: 10000.0,
        denominatorUsed: 'monthly_income',
        activeSubscriptionsCount: 2,
        categoryBreakdown: [
          CategoryBreakdownItem(category: 'entertainment', amount: 400.0, percentage: 80.0),
          CategoryBreakdownItem(category: 'cloud', amount: 100.0, percentage: 20.0),
        ],
        upcomingRenewals: [
          DashboardRenewal(
            id: 'sub-2',
            name: 'Monthly Service',
            category: 'entertainment',
            price: 400.0,
            billingCycle: 'MONTHLY',
            daysUntilRenewal: 5,
            nextBillingDate: null,
          ),
        ],
      );

      final container = ProviderContainer(
        overrides: [
          subscriptionReadModelsProvider.overrideWithValue(
            AsyncData(testSubs),
          ),
          creepScoreRepositoryProvider.overrideWithValue(
            _FakeCreepScoreRepository(report: testReport),
          ),
        ],
      );
      addTearDown(container.dispose);

      // Wait for creepScoreFutureProvider to resolve
      await container.read(creepScoreFutureProvider.future);

      final summaryAsync = container.read(dashboardSummaryProvider);
      expect(summaryAsync, isA<AsyncData<DashboardSummary>>());

      final summary = summaryAsync.value!;
      // From real backend report
      expect(summary.monthlyTotal, 500.0);
      expect(summary.creepScore, 8.5);
      expect(summary.riskLevel, 'SAFE');
      expect(summary.denominatorUsed, 'monthly_income');
      expect(summary.activeSubscriptionsCount, 2);
      expect(summary.categoryBreakdown.length, 2);
      expect(summary.upcomingRenewals.first.name, 'Monthly Service');

      // Client-side computed unused fallback
      expect(summary.unusedCount, 1);
      expect(summary.unusedMonthlySavings, 100.0);
    });

    test('falls back gracefully to client-side math when backend call fails', () async {
      final container = ProviderContainer(
        overrides: [
          subscriptionReadModelsProvider.overrideWithValue(
            AsyncData(testSubs),
          ),
          creepScoreRepositoryProvider.overrideWithValue(
            _FakeCreepScoreRepository(error: Exception('Network offline')),
          ),
        ],
      );
      addTearDown(container.dispose);

      // Wait for creepScoreFutureProvider to resolve (it resolves to null on error)
      await container.read(creepScoreFutureProvider.future);

      final summaryAsync = container.read(dashboardSummaryProvider);
      expect(summaryAsync, isA<AsyncData<DashboardSummary>>());

      final summary = summaryAsync.value!;
      // Client-side math fallback
      expect(summary.monthlyTotal, 500.0);
      expect(summary.unusedCount, 1);
      expect(summary.unusedMonthlySavings, 100.0);
      expect(summary.upcomingRenewals.length, 2);
    });
  });
}

