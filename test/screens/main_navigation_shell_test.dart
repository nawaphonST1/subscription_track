import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subscription_track/core/theme/app_theme.dart';
import 'package:subscription_track/providers/subscription_provider.dart';
import 'package:subscription_track/repositories/in_memory_subscription_repository.dart';
import 'package:subscription_track/screens/main_navigation_shell.dart';

Widget _buildShell() {
  return ProviderScope(
    overrides: [
      subscriptionRepositoryProvider.overrideWithValue(
        InMemorySubscriptionRepository(ioDelay: Duration.zero),
      ),
    ],
    child: MaterialApp(theme: AppTheme.dark, home: const MainNavigationShell()),
  );
}

void main() {
  testWidgets('switches between all four destinations', (tester) async {
    await tester.pumpWidget(_buildShell());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('hero-payout-card')), findsOneWidget);

    await tester.tap(find.text('รายการ'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('subscription-search-field')), findsOneWidget);
    expect(find.byKey(const Key('add-subscription-button')), findsOneWidget);

    await tester.tap(find.text('ประหยัด'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('savings-goal-banner')), findsOneWidget);

    await tester.tap(find.text('โปรไฟล์'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('profile-income-setting')), findsOneWidget);
  });

  testWidgets('filters subscriptions by search and category', (tester) async {
    await tester.pumpWidget(_buildShell());
    await tester.pumpAndSettle();
    await tester.tap(find.text('รายการ'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('subscription-search-field')),
      'ChatGPT',
    );
    await tester.pump();

    expect(find.text('ChatGPT Plus'), findsOneWidget);
    expect(find.text('Netflix Premium'), findsNothing);

    await tester.enterText(
      find.byKey(const Key('subscription-search-field')),
      '',
    );
    await tester.tap(find.byKey(const Key('category-cloud')));
    await tester.pump();

    expect(find.text('Google One Cloud'), findsOneWidget);
    expect(find.text('ChatGPT Plus'), findsNothing);
  });

  testWidgets('updates income and recalculates the creep score', (
    tester,
  ) async {
    await tester.pumpWidget(_buildShell());
    await tester.pumpAndSettle();

    final initialRisk = tester.widget<Text>(
      find.byKey(const Key('creep-risk-value')),
    );
    expect(initialRisk.data, contains('6.3%'));

    await tester.tap(find.byKey(const Key('income-chip')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('income-field')), '70000');
    await tester.tap(find.byKey(const Key('save-income-button')));
    await tester.pumpAndSettle();

    final updatedRisk = tester.widget<Text>(
      find.byKey(const Key('creep-risk-value')),
    );
    expect(updatedRisk.data, contains('3.2%'));
  });
}
