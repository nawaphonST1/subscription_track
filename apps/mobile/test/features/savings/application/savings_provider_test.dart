import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subscription_track/features/savings/application/savings_provider.dart';
import 'package:subscription_track/features/savings/data/remote_savings_repository.dart';
import 'package:subscription_track/features/savings/domain/savings_optimizer_report.dart';
import 'package:subscription_track/features/savings/domain/savings_repository.dart';
import 'package:subscription_track/features/subscriptions/application/subscription_read_model.dart';

class _FakeSavingsRepository implements SavingsRepository {
  _FakeSavingsRepository({
    this.report,
    this.getReportError,
  });

  final SavingsOptimizerReport? report;
  final Exception? getReportError;

  List<String>? lastBatchCancelIds;
  String? lastBatchCancelPin;

  @override
  Future<SavingsOptimizerReport> getOptimizerReport() async {
    if (getReportError != null) throw getReportError!;
    return report!;
  }

  @override
  Future<BatchCancelResult> batchCancel({
    required List<String> subscriptionIds,
    required String pin,
  }) async {
    lastBatchCancelIds = subscriptionIds;
    lastBatchCancelPin = pin;
    return BatchCancelResult(
      message: 'OK',
      cancelledCount: subscriptionIds.length,
      totalYearlySavingsUnlocked: 1000.0,
    );
  }
}

void main() {
  const testReport = SavingsOptimizerReport(
    unusedSubscriptionsCount: 2,
    totalMonthlySavings: 500,
    totalYearlySavingsProjection: 6000,
    recommendedCancellations: [
      SavingsOptimizerItem(
        id: 'sub-1',
        name: 'Unused Gym',
        category: 'fitness',
        price: 300,
        billingCycle: 'monthly',
        normalizedMonthlyCost: 300,
        yearlySavingsProjection: 3600,
        paymentCard: SavingsPaymentCard(
          cardNickname: 'Main Card',
          last4Digits: '1234',
          bankName: 'SCB',
        ),
      ),
      SavingsOptimizerItem(
        id: 'sub-2',
        name: 'Unused Cloud',
        category: 'cloud',
        price: 200,
        billingCycle: 'monthly',
        normalizedMonthlyCost: 200,
        yearlySavingsProjection: 2400,
        paymentCard: null,
      ),
    ],
  );

  group('SavingsViewState', () {
    test('derives selected count and yearly savings from subscription state (fallback)', () {
      final state = SavingsViewState.from([
        const SubscriptionReadModel(
          id: 'monthly',
          name: 'Monthly',
          category: 'other',
          monthlyPrice: 100,
          usageStatus: 'frequent',
          isSelected: true,
          nextBillingDate: null,
        ),
        const SubscriptionReadModel(
          id: 'yearly',
          name: 'Yearly',
          category: 'other',
          monthlyPrice: 100,
          usageStatus: 'frequent',
          isSelected: true,
          nextBillingDate: null,
        ),
        const SubscriptionReadModel(
          id: 'ignored',
          name: 'Ignored',
          category: 'other',
          monthlyPrice: 500,
          usageStatus: 'frequent',
          isSelected: false,
          nextBillingDate: null,
        ),
      ]);

      expect(state.selectedCount, 2);
      expect(state.yearlySavings, 2400);
      expect(state.hasSelection, isTrue);
      expect(state.items, hasLength(3));
    });

    test('builds from SavingsOptimizerReport correctly', () {
      final state = SavingsViewState.fromOptimizerReport(
        testReport,
        selectedIds: {'sub-1'},
      );

      expect(state.items.length, 2);
      expect(state.selectedCount, 1);
      expect(state.yearlySavings, 3600);
      expect(state.totalMonthlySavings, 500);
      expect(state.totalYearlySavingsProjection, 6000);
      expect(state.items.first.paymentCard?.displayName, 'Main Card (•• 1234)');
    });
  });

  group('SavingsNotifier', () {
    test('loads report from repository and handles selection toggle', () async {
      final fakeRepo = _FakeSavingsRepository(report: testReport);
      final container = ProviderContainer(
        overrides: [
          savingsRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final state = await container.read(savingsNotifierProvider.future);
      expect(state.items.length, 2);
      expect(state.selectedCount, 0);

      // Toggle first item
      container.read(savingsNotifierProvider.notifier).toggleSelection('sub-1');
      final toggledState = container.read(savingsViewStateProvider).value!;
      expect(toggledState.selectedCount, 1);
      expect(toggledState.yearlySavings, 3600);
      expect(toggledState.items.first.isSelected, isTrue);

      // Toggle off
      container.read(savingsNotifierProvider.notifier).toggleSelection('sub-1');
      final untoggledState = container.read(savingsViewStateProvider).value!;
      expect(untoggledState.selectedCount, 0);
      expect(untoggledState.yearlySavings, 0);
      expect(untoggledState.items.first.isSelected, isFalse);
    });

    test('batchCancel sends IDs and PIN to repository', () async {
      final fakeRepo = _FakeSavingsRepository(report: testReport);
      final container = ProviderContainer(
        overrides: [
          savingsRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      await container.read(savingsNotifierProvider.future);
      final result = await container
          .read(savingsNotifierProvider.notifier)
          .batchCancel(['sub-1', 'sub-2'], '654321');

      expect(fakeRepo.lastBatchCancelIds, ['sub-1', 'sub-2']);
      expect(fakeRepo.lastBatchCancelPin, '654321');
      expect(result.cancelledCount, 2);
    });

    test('falls back to local subscriptions when repository fails', () async {
      final fakeRepo = _FakeSavingsRepository(
        getReportError: Exception('Network offline'),
      );
      final container = ProviderContainer(
        overrides: [
          savingsRepositoryProvider.overrideWithValue(fakeRepo),
          subscriptionReadModelsProvider.overrideWithValue(
            const AsyncData([
              SubscriptionReadModel(
                id: 'local-1',
                name: 'Local Unused',
                category: 'entertainment',
                monthlyPrice: 150,
                usageStatus: 'unused',
                isSelected: false,
                nextBillingDate: null,
              ),
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);

      final state = await container.read(savingsNotifierProvider.future);
      expect(state.items.length, 1);
      expect(state.items.first.name, 'Local Unused');
    });
  });
}
