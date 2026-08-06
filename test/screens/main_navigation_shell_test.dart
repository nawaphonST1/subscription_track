import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subscription_track/core/theme/app_theme.dart';
import 'package:subscription_track/features/subscriptions/application/subscription_list_controller.dart';
import 'package:subscription_track/features/subscriptions/data/in_memory_subscription_repository.dart';
import 'package:subscription_track/app/presentation/main_navigation_shell.dart';

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
  testWidgets('switches between every integrated destination', (tester) async {
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

    await tester.tap(find.text('ตั้งค่า'));
    await tester.pumpAndSettle();
    expect(find.text('แจ้งเตือนก่อนตัดเงิน'), findsOneWidget);

    await tester.tap(find.text('โปรไฟล์'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('profile-income-setting')), findsOneWidget);
    expect(find.text('แจ้งเตือนก่อนตัดเงิน'), findsNothing);
  });

  testWidgets('uses bottom navigation on a mobile-width window', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_buildShell());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('main-bottom-navigation')), findsOneWidget);
    expect(find.byKey(const Key('main-navigation-rail')), findsNothing);
    expect(find.byKey(const Key('dashboard-desktop-layout')), findsNothing);
    expect(tester.takeException(), isNull);

    for (final destination in ['รายการ', 'ประหยัด', 'ตั้งค่า', 'โปรไฟล์']) {
      await tester.tap(find.text(destination));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: destination);
    }
  });

  testWidgets('adapts navigation and tab content for desktop width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_buildShell());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('main-navigation-rail')), findsOneWidget);
    expect(find.byKey(const Key('main-bottom-navigation')), findsNothing);
    expect(find.byKey(const Key('dashboard-desktop-layout')), findsOneWidget);
    expect(find.byKey(const Key('renewals-desktop-grid')), findsOneWidget);

    await tester.tap(find.text('รายการ'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('subscriptions-desktop-grid')), findsOneWidget);

    await tester.tap(find.text('ประหยัด'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('savings-desktop-layout')), findsOneWidget);

    for (final destination in ['ตั้งค่า', 'โปรไฟล์']) {
      await tester.tap(find.text(destination));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: destination);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('header avatar opens the profile destination', (tester) async {
    await tester.pumpWidget(_buildShell());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('header-profile-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('profile-income-setting')), findsOneWidget);
    expect(find.text('แจ้งเตือนก่อนตัดเงิน'), findsNothing);
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

  testWidgets('opens subscription details when a row is tapped', (
    tester,
  ) async {
    await tester.pumpWidget(_buildShell());
    await tester.pumpAndSettle();
    await tester.tap(find.text('รายการ'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('subscription-netflix-premium')));
    await tester.pumpAndSettle();

    expect(find.text('รายละเอียดบริการ'), findsOneWidget);
    expect(find.text('Netflix Premium'), findsWidgets);
  });

  testWidgets('allows editing reminders and marking a subscription cancelled', (
    tester,
  ) async {
    await tester.pumpWidget(_buildShell());
    await tester.pumpAndSettle();
    await tester.tap(find.text('รายการ'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('subscription-netflix-premium')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('แก้ไข'));
    await tester.pumpAndSettle();

    final sevenDays = find.byKey(const Key('reminder-7-days'));
    await tester.ensureVisible(sevenDays);
    await tester.tap(sevenDays);
    await tester.pump();

    final markCancelled = find.byKey(const Key('mark-subscription-cancelled'));
    await tester.ensureVisible(markCancelled);
    await tester.tap(markCancelled);
    await tester.pump();

    final saveButton = find.byKey(const Key('save-subscription-details'));
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('subscription-netflix-premium')));
    await tester.pumpAndSettle();

    expect(find.text('เตือนล่วงหน้า 7 วัน'), findsOneWidget);
    expect(find.byKey(const Key('cancelled-status-label')), findsOneWidget);
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
