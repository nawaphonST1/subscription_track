import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subscription_track/app/application/current_tab_controller.dart';
import 'package:subscription_track/app/presentation/widgets/main_app_header.dart';
import 'package:subscription_track/app/presentation/widgets/main_app_navigation.dart';
import 'package:subscription_track/core/layout/app_breakpoints.dart';
import 'package:subscription_track/features/dashboard/presentation/dashboard_tab.dart';
import 'package:subscription_track/features/profile/application/user_income_controller.dart';
import 'package:subscription_track/features/profile/presentation/income_editor_sheet.dart';
import 'package:subscription_track/features/profile/presentation/profile_tab.dart';
import 'package:subscription_track/features/savings/presentation/savings_tab.dart';
import 'package:subscription_track/features/settings/presentation/settings_tab.dart';
import 'package:subscription_track/features/subscriptions/presentation/subscriptions_tab.dart';

class MainNavigationShell extends ConsumerWidget {
  const MainNavigationShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTab = ref.watch(currentTabProvider);
    final income = ref.watch(userIncomeProvider);
    final selectTab = ref.read(currentTabProvider.notifier).select;
    final theme = Theme.of(context);
    Future<void> editIncome() =>
        showIncomeEditorSheet(context: context, currentIncome: income);
    final pages = <Widget>[
      const DashboardTab(),
      const SubscriptionsTab(),
      const SavingsTab(),
      const SettingsTab(),
      ProfileTab(onEditIncome: editIncome),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final useRail = constraints.maxWidth >= AppBreakpoints.desktop;
        final extendRail =
            constraints.maxWidth >= AppBreakpoints.expandedNavigation;
        final content = IndexedStack(index: currentTab, children: pages);
        return Scaffold(
          appBar: MainAppHeader(onEditIncome: editIncome),
          body: useRail
              ? Row(
                  children: [
                    MainAppNavigationRail(
                      selectedIndex: currentTab,
                      extended: extendRail,
                      onSelected: selectTab,
                    ),
                    VerticalDivider(width: 1, color: theme.dividerColor),
                    Expanded(child: content),
                  ],
                )
              : content,
          bottomNavigationBar: useRail
              ? null
              : MainAppNavigationBar(
                  selectedIndex: currentTab,
                  onSelected: selectTab,
                ),
        );
      },
    );
  }
}
