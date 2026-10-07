import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:subscription_track/app/application/current_tab_controller.dart';
import 'package:subscription_track/app/presentation/widgets/main_app_header.dart';
import 'package:subscription_track/app/presentation/widgets/main_app_navigation.dart';
import 'package:subscription_track/app/routing/route_constants.dart';
import 'package:subscription_track/core/layout/app_breakpoints.dart';
import 'package:subscription_track/core/network/network_status.dart';
import 'package:subscription_track/core/widgets/connectivity_status_banner.dart';
import 'package:subscription_track/features/dashboard/presentation/dashboard_tab.dart';
import 'package:subscription_track/features/profile/application/user_income_controller.dart';
import 'package:subscription_track/features/profile/presentation/income_editor_sheet.dart';
import 'package:subscription_track/features/profile/presentation/profile_tab.dart';
import 'package:subscription_track/features/savings/presentation/savings_tab.dart';
import 'package:subscription_track/features/settings/presentation/settings_tab.dart';
import 'package:subscription_track/features/subscriptions/presentation/subscriptions_tab.dart';

class MainNavigationShell extends ConsumerWidget {
  const MainNavigationShell({
    this.navigationShell,
    this.state,
    this.child,
    super.key,
  });

  final StatefulNavigationShell? navigationShell;
  final GoRouterState? state;
  final Widget? child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTab = ref.watch(currentTabProvider);
    final selectedIndex = navigationShell?.currentIndex ?? currentTab;
    final income = ref.watch(userIncomeProvider);
    final theme = Theme.of(context);

    // Sync tab controller when currentTabProvider changes programmatically
    ref.listen<int>(currentTabProvider, (_, next) {
      if (navigationShell != null && navigationShell!.currentIndex != next) {
        navigationShell!.goBranch(next, initialLocation: false);
      }
    });

    // ตรวจจับสถานะการเชื่อมต่อเน็ต: เด้งเตือนทันทีเมื่อไม่มีเน็ต
    ref.listen<ConnectivityState>(networkStatusProvider, (previous, next) {
      if (next.isNoInternet && (previous == null || !previous.isNoInternet)) {
        showNoInternetDialog(context, ref);
      }
    });

    void selectTab(int index) {
      if (navigationShell != null) {
        navigationShell!.goBranch(
          index,
          initialLocation: index == navigationShell!.currentIndex,
        );
      }
      ref.read(currentTabProvider.notifier).select(index);
    }

    Future<void> editIncome() =>
        showIncomeEditorSheet(context: context, currentIncome: income);

    final pages = <Widget>[
      const DashboardTab(),
      const SubscriptionsTab(),
      const SavingsTab(),
      const SettingsTab(),
      ProfileTab(onEditIncome: editIncome),
    ];

    final currentPath = state?.uri.path ??
        (() {
          try {
            return GoRouterState.of(context).uri.path;
          } catch (_) {
            return '';
          }
        })();

    final isTopLevel = currentPath.isEmpty ||
        currentPath == RouteConstants.dashboard ||
        currentPath == RouteConstants.subscriptions ||
        currentPath == RouteConstants.savings ||
        currentPath == RouteConstants.settings ||
        currentPath == RouteConstants.profile;

    final content = navigationShell ??
        child ??
        IndexedStack(index: selectedIndex, children: pages);

    return LayoutBuilder(
      builder: (context, constraints) {
        final useRail = constraints.maxWidth >= AppBreakpoints.desktop;
        final extendRail =
            constraints.maxWidth >= AppBreakpoints.expandedNavigation;
        return Scaffold(
          appBar: isTopLevel
              ? MainAppHeader(onEditIncome: editIncome)
              : null,
          body: Column(
            children: [
              const ConnectivityStatusBanner(),
              Expanded(
                child: useRail
                    ? Row(
                        children: [
                          MainAppNavigationRail(
                            selectedIndex: selectedIndex,
                            extended: extendRail,
                            onSelected: selectTab,
                          ),
                          VerticalDivider(width: 1, color: theme.dividerColor),
                          Expanded(child: content),
                        ],
                      )
                    : content,
              ),
            ],
          ),
          bottomNavigationBar: useRail
              ? null
              : MainAppNavigationBar(
                  selectedIndex: selectedIndex,
                  onSelected: selectTab,
                ),
        );
      },
    );
  }
}
