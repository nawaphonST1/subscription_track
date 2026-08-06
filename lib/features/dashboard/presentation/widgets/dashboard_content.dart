import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subscription_track/core/layout/app_breakpoints.dart';
import 'package:subscription_track/features/dashboard/application/dashboard_summary_provider.dart';
import 'package:subscription_track/features/dashboard/presentation/widgets/dashboard_hero_card.dart';
import 'package:subscription_track/features/dashboard/presentation/widgets/dashboard_renewals_section.dart';
import 'package:subscription_track/features/dashboard/presentation/widgets/dashboard_unused_alert.dart';
import 'package:subscription_track/features/subscriptions/application/subscription_list_controller.dart';
import 'package:subscription_track/app/application/current_tab_controller.dart';

class DashboardContent extends ConsumerWidget {
  const DashboardContent({required this.summary, super.key});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unusedAlert = DashboardUnusedAlert(
      count: summary.unusedCount,
      monthlySavings: summary.unusedMonthlySavings,
      onOpenSavings: () => ref.read(currentTabProvider.notifier).select(2),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final useTwoColumns = constraints.maxWidth >= AppBreakpoints.desktop;
        return RefreshIndicator(
          onRefresh: ref.read(subscriptionListProvider.notifier).refresh,
          child: ListView(
            key: const PageStorageKey<String>('dashboard-tab'),
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppBreakpoints.contentMaxWidth,
                  ),
                  child: useTwoColumns
                      ? Row(
                          key: const Key('dashboard-desktop-layout'),
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  DashboardHeroCard(
                                    monthlyTotal: summary.monthlyTotal,
                                    creepScore: summary.creepScore,
                                  ),
                                  const SizedBox(height: 22),
                                  unusedAlert,
                                ],
                              ),
                            ),
                            const SizedBox(width: 22),
                            Expanded(
                              child: DashboardRenewalsSection(
                                renewals: summary.upcomingRenewals,
                                useGrid: true,
                              ),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            DashboardHeroCard(
                              monthlyTotal: summary.monthlyTotal,
                              creepScore: summary.creepScore,
                            ),
                            const SizedBox(height: 22),
                            DashboardRenewalsSection(
                              renewals: summary.upcomingRenewals,
                            ),
                            const SizedBox(height: 22),
                            unusedAlert,
                          ],
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
