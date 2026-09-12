import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subscription_track/core/theme/app_theme.dart';
import 'package:subscription_track/features/subscriptions/application/subscription_filter_controller.dart';
import 'package:subscription_track/features/subscriptions/domain/subscription.dart';
import 'package:subscription_track/features/subscriptions/presentation/widgets/subscription_detail_sheet.dart';
import 'package:subscription_track/features/subscriptions/presentation/widgets/subscription_filter_bar.dart';
import 'package:subscription_track/features/subscriptions/presentation/widgets/subscription_general_fields.dart';

const _subscription = Subscription(
  id: 'theme-test',
  name: 'Theme Service',
  price: 199,
  category: 'ai',
);

Widget _lightApp(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(body: child),
);

void main() {
  testWidgets('form fields inherit readable light-theme text', (tester) async {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    addTearDown(nameController.dispose);
    addTearDown(priceController.dispose);

    await tester.pumpWidget(
      _lightApp(
        SubscriptionGeneralFields(
          nameController: nameController,
          priceController: priceController,
          billingPeriod: 'Monthly',
          nameValidator: (_) => null,
          priceValidator: (_) => null,
          onBillingPeriodChanged: (_) {},
        ),
      ),
    );

    final editable = tester.widget<EditableText>(
      find.byType(EditableText).first,
    );
    expect(editable.style.color, isNot(Colors.white));
  });

  testWidgets('filter chips use light-theme surfaces', (tester) async {
    await tester.pumpWidget(
      _lightApp(
        SubscriptionFilterBar(
          filter: const SubscriptionFilterState(),
          onQueryChanged: (_) {},
          onCategorySelected: (_) {},
        ),
      ),
    );

    final unselectedChip = tester.widget<ChoiceChip>(
      find.byKey(const Key('category-streaming')),
    );
    expect(unselectedChip.backgroundColor, AppTheme.light.cardColor);
  });

  testWidgets('detail sheet text remains readable in light mode', (
    tester,
  ) async {
    await tester.pumpWidget(
      _lightApp(
        SubscriptionDetailSheet(subscription: _subscription, onSaved: (_) {}),
      ),
    );

    final serviceName = tester.widget<Text>(find.text('Theme Service'));
    final detailValue = tester.widget<Text>(find.text('ai'));
    expect(serviceName.style?.color, isNot(Colors.white));
    expect(detailValue.style?.color, isNot(Colors.white));
  });
}
