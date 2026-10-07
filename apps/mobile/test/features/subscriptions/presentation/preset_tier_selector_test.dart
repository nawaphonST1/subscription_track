import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subscription_track/features/subscriptions/domain/preset_plan.dart';
import 'package:subscription_track/features/subscriptions/presentation/widgets/preset_tier_selector.dart';

void main() {
  const plans = [
    PresetPlan(tier: 'Mobile', monthlyPrice: 99, maxSlots: 1),
    PresetPlan(tier: 'Standard', monthlyPrice: 349, maxSlots: 2),
    PresetPlan(tier: 'Premium', monthlyPrice: 419, maxSlots: 4),
  ];

  Future<void> pump(
    WidgetTester tester, {
    required String selectedTier,
    required ValueChanged<PresetPlan> onSelected,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PresetTierSelector(
            plans: plans,
            selectedTier: selectedTier,
            brandColor: Colors.blue,
            onSelected: onSelected,
          ),
        ),
      ),
    );
  }

  testWidgets('renders every plan tier label and price', (tester) async {
    await pump(tester, selectedTier: 'Premium', onSelected: (_) {});

    expect(find.text('Mobile'), findsOneWidget);
    expect(find.text('Standard'), findsOneWidget);
    expect(find.text('Premium'), findsOneWidget);
    expect(find.text('฿349/เดือน'), findsOneWidget);
  });

  testWidgets('tapping a tier card invokes onSelected with that plan', (
    tester,
  ) async {
    PresetPlan? tapped;
    await pump(
      tester,
      selectedTier: 'Premium',
      onSelected: (plan) => tapped = plan,
    );

    await tester.tap(find.text('Standard'));
    await tester.pump();

    expect(tapped?.tier, 'Standard');
  });
}
