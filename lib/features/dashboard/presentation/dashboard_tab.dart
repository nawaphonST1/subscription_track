import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subscription_track/features/dashboard/application/dashboard_summary_provider.dart';
import 'package:subscription_track/features/dashboard/presentation/widgets/dashboard_content.dart';
import 'package:subscription_track/features/subscriptions/application/subscription_list_controller.dart';

class DashboardTab extends ConsumerWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(dashboardSummaryProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: FilledButton.icon(
              onPressed: ref.read(subscriptionListProvider.notifier).refresh,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('โหลดข้อมูลอีกครั้ง'),
            ),
          ),
          data: (summary) => DashboardContent(summary: summary),
        );
  }
}
