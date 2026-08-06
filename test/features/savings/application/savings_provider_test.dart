import 'package:flutter_test/flutter_test.dart';
import 'package:subscription_track/features/savings/application/savings_provider.dart';
import 'package:subscription_track/features/subscriptions/application/subscription_read_model.dart';

void main() {
  test('derives selected count and yearly savings from subscription state', () {
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
}
