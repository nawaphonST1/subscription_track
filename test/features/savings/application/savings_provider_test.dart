import 'package:flutter_test/flutter_test.dart';
import 'package:subscription_track/features/savings/application/savings_provider.dart';
import 'package:subscription_track/features/subscriptions/domain/subscription.dart';

void main() {
  test('derives selected count and yearly savings from subscription state', () {
    final state = SavingsViewState.from([
      const Subscription(
        id: 'monthly',
        name: 'Monthly',
        price: 100,
        isSelected: true,
      ),
      const Subscription(
        id: 'yearly',
        name: 'Yearly',
        price: 1200,
        billingPeriod: 'yearly',
        isSelected: true,
      ),
      const Subscription(id: 'ignored', name: 'Ignored', price: 500),
    ]);

    expect(state.selectedCount, 2);
    expect(state.yearlySavings, 2400);
    expect(state.hasSelection, isTrue);
    expect(state.items, hasLength(3));
  });
}
