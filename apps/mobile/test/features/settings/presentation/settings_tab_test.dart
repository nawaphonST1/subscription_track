import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subscription_track/app/application/theme_mode_controller.dart';
import 'package:subscription_track/core/theme/app_theme.dart';
import 'package:subscription_track/features/admin/application/admin_controller.dart';
import 'package:subscription_track/features/settings/application/notification_reminder_controller.dart';
import 'package:subscription_track/features/settings/presentation/settings_tab.dart';

Widget _buildSettingsApp() {
  return ProviderScope(
    child: Consumer(
      builder: (context, ref, _) => MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ref.watch(themeModeProvider),
        home: const Scaffold(body: SettingsTab()),
      ),
    ),
  );
}

void main() {
  testWidgets('theme switch updates the effective app brightness', (
    tester,
  ) async {
    await tester.pumpWidget(_buildSettingsApp());
    await tester.pumpAndSettle();

    final switchFinder = find.widgetWithText(SwitchListTile, 'โหมดกลางคืน');
    expect(
      Theme.of(tester.element(find.byType(SettingsTab))).brightness,
      Brightness.dark,
    );

    await tester.tap(switchFinder);
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.byType(SettingsTab))).brightness,
      Brightness.light,
    );

    await tester.tap(switchFinder);
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.byType(SettingsTab))).brightness,
      Brightness.dark,
    );
  });

  testWidgets('notification reminder remains independently controlled', (
    tester,
  ) async {
    await tester.pumpWidget(_buildSettingsApp());
    await tester.pumpAndSettle();

    await tester.tap(
      find.widgetWithText(SwitchListTile, 'แจ้งเตือนก่อนตัดเงิน'),
    );
    await tester.pumpAndSettle();

    final element = tester.element(find.byType(SettingsTab));
    final container = ProviderScope.containerOf(element);
    expect(container.read(notificationReminderProvider), isFalse);
    expect(container.read(themeModeProvider), ThemeMode.dark);
  });

  testWidgets('does not display admin portal tile when user is not admin', (
    tester,
  ) async {
    await tester.pumpWidget(_buildSettingsApp());
    await tester.pumpAndSettle();

    expect(find.text('ระบบจัดการผู้ดูแล (Admin Portal)'), findsNothing);
  });

  testWidgets('displays admin portal tile when user is admin', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isAdminUserProvider.overrideWith((ref) => Future.value(true)),
        ],
        child: Consumer(
          builder: (context, ref, _) => MaterialApp(
            theme: AppTheme.dark,
            home: const Scaffold(body: SettingsTab()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ระบบจัดการผู้ดูแล (Admin Portal)'), findsOneWidget);
  });
}
