/// Billing cycle for the tiered plan-selection flow (package tier picker,
/// [SelectedPackageState]). Scoped to this feature only — the rest of the
/// app (Subscription.billingPeriod, admin package model, dashboard/savings
/// reports) still uses free-form billing-period strings.
enum BillingCycle {
  monthly,
  yearly;

  String toApiString() {
    return switch (this) {
      BillingCycle.monthly => 'MONTHLY',
      BillingCycle.yearly => 'YEARLY',
    };
  }

  static BillingCycle fromApiString(String? raw) {
    return raw?.toUpperCase() == 'YEARLY'
        ? BillingCycle.yearly
        : BillingCycle.monthly;
  }
}
