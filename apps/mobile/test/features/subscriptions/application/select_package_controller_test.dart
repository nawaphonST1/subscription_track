import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subscription_track/features/subscriptions/application/select_package_controller.dart';
import 'package:subscription_track/features/subscriptions/domain/billing_cycle.dart';
import 'package:subscription_track/features/subscriptions/domain/preset_package.dart';
import 'package:subscription_track/features/subscriptions/domain/preset_plan.dart';

void main() {
  const netflix = PresetPackage(
    id: 'preset-netflix',
    name: 'Netflix',
    price: 419,
    billingPeriod: 'Monthly',
    category: 'streaming',
    maxSlots: 4,
    plans: [
      PresetPlan(
        tier: 'Mobile',
        monthlyPrice: 99,
        yearlyPrice: 990,
        maxSlots: 1,
        features: ['480p SD'],
      ),
      PresetPlan(
        tier: 'Standard',
        monthlyPrice: 349,
        yearlyPrice: 3490,
        maxSlots: 2,
        features: ['1080p Full HD'],
      ),
      PresetPlan(
        tier: 'Premium',
        monthlyPrice: 419,
        yearlyPrice: 4190,
        maxSlots: 4,
        features: ['4K UHD + HDR'],
      ),
    ],
  );

  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() => container.dispose());

  test('build seeds state from the package default plan', () {
    final state = container.read(selectPackageControllerProvider(netflix));
    expect(state.selectedPlan.tier, 'Premium');
    expect(state.billingCycle, BillingCycle.monthly);
    expect(state.sharedMembers, 1);
    expect(state.calculatedTotalPrice, 419.0);
    expect(state.calculatedCostPerSlot, 419.0);
  });

  test('selectPlan switches tier and clamps sharedMembers to the new maxSlots', () {
    final notifier = container.read(
      selectPackageControllerProvider(netflix).notifier,
    );
    notifier.setSharedMembers(4);
    expect(
      container.read(selectPackageControllerProvider(netflix)).sharedMembers,
      4,
    );

    notifier.selectPlan(netflix.plans[0]); // Mobile: maxSlots 1
    final state = container.read(selectPackageControllerProvider(netflix));
    expect(state.selectedPlan.tier, 'Mobile');
    expect(state.sharedMembers, 1);
  });

  test('setSharedMembers clamps within 1..selectedPlan.maxSlots', () {
    final notifier = container.read(
      selectPackageControllerProvider(netflix).notifier,
    );

    notifier.setSharedMembers(10);
    expect(
      container.read(selectPackageControllerProvider(netflix)).sharedMembers,
      4,
    );

    notifier.setSharedMembers(0);
    expect(
      container.read(selectPackageControllerProvider(netflix)).sharedMembers,
      1,
    );
  });

  test('calculatedCostPerSlot divides the total price by sharedMembers', () {
    final notifier = container.read(
      selectPackageControllerProvider(netflix).notifier,
    );
    notifier.setSharedMembers(4);

    final state = container.read(selectPackageControllerProvider(netflix));
    expect(state.calculatedCostPerSlot, 104.75);
  });

  test('toggleBillingCycle switches calculatedTotalPrice to the yearly price', () {
    final notifier = container.read(
      selectPackageControllerProvider(netflix).notifier,
    );
    notifier.toggleBillingCycle(BillingCycle.yearly);

    final state = container.read(selectPackageControllerProvider(netflix));
    expect(state.billingCycle, BillingCycle.yearly);
    expect(state.calculatedTotalPrice, 4190.0);
  });

  test('toSubscriptionDraft builds a Subscription carrying plan/slot metadata', () {
    final notifier = container.read(
      selectPackageControllerProvider(netflix).notifier,
    );
    notifier.setSharedMembers(4);

    final draft = notifier.toSubscriptionDraft();
    expect(draft.name, 'Netflix Premium');
    expect(draft.presetId, 'preset-netflix');
    expect(draft.planTier, 'Premium');
    expect(draft.sharedMembers, 4);
    expect(draft.price, 419.0);
    expect(draft.pricePerSlot, 104.75);
    expect(draft.billingPeriod, 'monthly');
  });
}
