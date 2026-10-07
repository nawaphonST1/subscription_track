import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subscription_track/features/subscriptions/domain/billing_cycle.dart';
import 'package:subscription_track/features/subscriptions/domain/preset_package.dart';
import 'package:subscription_track/features/subscriptions/domain/preset_plan.dart';
import 'package:subscription_track/features/subscriptions/domain/subscription.dart';

class SelectedPackageState {
  const SelectedPackageState({
    required this.package,
    required this.selectedPlan,
    this.billingCycle = BillingCycle.monthly,
    this.sharedMembers = 1,
  });

  final PresetPackage package;
  final PresetPlan selectedPlan;
  final BillingCycle billingCycle;
  final int sharedMembers;

  double get calculatedTotalPrice {
    if (billingCycle == BillingCycle.yearly) {
      return selectedPlan.yearlyPrice ?? selectedPlan.monthlyPrice * 12;
    }
    return selectedPlan.monthlyPrice;
  }

  double get calculatedCostPerSlot => calculatedTotalPrice / sharedMembers;

  SelectedPackageState copyWith({
    PresetPlan? selectedPlan,
    BillingCycle? billingCycle,
    int? sharedMembers,
  }) {
    return SelectedPackageState(
      package: package,
      selectedPlan: selectedPlan ?? this.selectedPlan,
      billingCycle: billingCycle ?? this.billingCycle,
      sharedMembers: sharedMembers ?? this.sharedMembers,
    );
  }
}

final selectPackageControllerProvider = NotifierProvider.family<
    SelectPackageController, SelectedPackageState, PresetPackage>(
  SelectPackageController.new,
);

final class SelectPackageController extends Notifier<SelectedPackageState> {
  SelectPackageController(this._package);

  final PresetPackage _package;

  @override
  SelectedPackageState build() {
    return SelectedPackageState(
      package: _package,
      selectedPlan: _package.defaultPlan,
    );
  }

  void selectPlan(PresetPlan plan) {
    final clampedMembers = state.sharedMembers > plan.maxSlots
        ? plan.maxSlots
        : state.sharedMembers;
    state = state.copyWith(selectedPlan: plan, sharedMembers: clampedMembers);
  }

  void toggleBillingCycle(BillingCycle cycle) {
    state = state.copyWith(billingCycle: cycle);
  }

  void setSharedMembers(int count) {
    final clamped = count.clamp(1, state.selectedPlan.maxSlots);
    state = state.copyWith(sharedMembers: clamped);
  }

  Subscription toSubscriptionDraft() {
    final plan = state.selectedPlan;
    final package = state.package;

    return Subscription(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: package.hasMultiplePlans ? '${package.name} ${plan.tier}' : package.name,
      price: state.calculatedTotalPrice,
      billingPeriod: state.billingCycle.name,
      category: package.category,
      presetId: package.id,
      planTier: plan.tier,
      sharedMembers: state.sharedMembers,
      pricePerSlot: state.calculatedCostPerSlot,
    );
  }
}
