import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subscription_track/core/layout/app_breakpoints.dart';
import 'package:subscription_track/core/theme/app_colors.dart';
import 'package:subscription_track/features/subscriptions/application/subscription_list_controller.dart';
import 'package:subscription_track/features/subscriptions/domain/subscription.dart';
import 'package:subscription_track/providers/main_navigation_provider.dart';

class DashboardTab extends ConsumerWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptions = ref.watch(subscriptionListProvider);

    return subscriptions.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _DashboardError(
        onRetry: ref.read(subscriptionListProvider.notifier).refresh,
      ),
      data: (items) => _DashboardContent(subscriptions: items),
    );
  }
}

class _DashboardContent extends ConsumerWidget {
  const _DashboardContent({required this.subscriptions});

  final List<Subscription> subscriptions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final income = ref.watch(userIncomeProvider);
    final monthlyTotal = subscriptions.fold<double>(
      0,
      (total, item) => total + item.monthlyPrice,
    );
    final creepScore = income > 0 ? monthlyTotal / income * 100 : 0.0;
    final unused = subscriptions
        .where((item) => item.usageStatus == 'unused')
        .toList(growable: false);
    final upcoming = [...subscriptions]
      ..sort((a, b) {
        final aDate = a.nextBillingDate ?? DateTime(9999);
        final bDate = b.nextBillingDate ?? DateTime(9999);
        return aDate.compareTo(bDate);
      });

    final unusedAlert = _UnusedAlertCard(
      count: unused.length,
      monthlySavings: unused.fold<double>(
        0,
        (total, item) => total + item.monthlyPrice,
      ),
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
                                  _HeroPayoutCard(
                                    monthlyTotal: monthlyTotal,
                                    creepScore: creepScore,
                                  ),
                                  const SizedBox(height: 22),
                                  unusedAlert,
                                ],
                              ),
                            ),
                            const SizedBox(width: 22),
                            Expanded(
                              child: _RenewalsSection(
                                subscriptions: upcoming,
                                useGrid: true,
                              ),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _HeroPayoutCard(
                              monthlyTotal: monthlyTotal,
                              creepScore: creepScore,
                            ),
                            const SizedBox(height: 22),
                            _RenewalsSection(subscriptions: upcoming),
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

class _RenewalsSection extends StatelessWidget {
  const _RenewalsSection({required this.subscriptions, this.useGrid = false});

  final List<Subscription> subscriptions;
  final bool useGrid;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionTitle(
          title: 'รายการใกล้ตัดเงิน',
          subtitle: 'เรียงตามวันชำระถัดไป',
        ),
        const SizedBox(height: 10),
        if (useGrid)
          GridView.builder(
            key: const Key('renewals-desktop-grid'),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: subscriptions.length,
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 250,
              mainAxisExtent: 90,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemBuilder: (context, index) => _RenewalChip(
              subscription: subscriptions[index],
              fillWidth: true,
            ),
          )
        else
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: subscriptions.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) =>
                  _RenewalChip(subscription: subscriptions[index]),
            ),
          ),
      ],
    );
  }
}

class _HeroPayoutCard extends StatelessWidget {
  const _HeroPayoutCard({required this.monthlyTotal, required this.creepScore});

  final double monthlyTotal;
  final double creepScore;

  @override
  Widget build(BuildContext context) {
    final riskColor = creepScore >= 10
        ? AppColors.danger
        : creepScore >= 5
        ? AppColors.warning
        : AppColors.success;

    return Container(
      key: const Key('hero-payout-card'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF182541), AppColors.bgSecondary],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'รายจ่ายค่าสมาชิกรวม',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: riskColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  child: Text(
                    'Creep Risk ${creepScore.toStringAsFixed(1)}%',
                    key: const Key('creep-risk-value'),
                    style: TextStyle(
                      color: riskColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '฿${monthlyTotal.toStringAsFixed(0)} / เดือน',
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'คิดเป็น ฿${(monthlyTotal * 12).toStringAsFixed(0)} ต่อปี',
            style: const TextStyle(
              color: AppColors.primaryLight,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _RenewalChip extends StatelessWidget {
  const _RenewalChip({required this.subscription, this.fillWidth = false});

  final Subscription subscription;
  final bool fillWidth;

  @override
  Widget build(BuildContext context) {
    final billingDate = subscription.nextBillingDate;
    final daysLeft = billingDate
        ?.difference(DateTime.now())
        .inDays
        .clamp(0, 999);

    return Container(
      width: fillWidth ? null : 154,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(subscription.iconData, color: subscription.iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  subscription.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  daysLeft == null ? 'ยังไม่กำหนดวัน' : 'อีก $daysLeft วัน',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UnusedAlertCard extends StatelessWidget {
  const _UnusedAlertCard({
    required this.count,
    required this.monthlySavings,
    required this.onOpenSavings,
  });

  final int count;
  final double monthlySavings;
  final VoidCallback onOpenSavings;

  @override
  Widget build(BuildContext context) {
    final hasUnused = count > 0;
    return Container(
      key: const Key('unused-service-alert'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (hasUnused ? AppColors.danger : AppColors.success).withValues(
          alpha: 0.1,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (hasUnused ? AppColors.danger : AppColors.success).withValues(
            alpha: 0.4,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            hasUnused ? Icons.warning_amber_rounded : Icons.verified_rounded,
            color: hasUnused ? AppColors.danger : AppColors.success,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasUnused
                      ? 'พบ $count บริการที่ไม่ได้ใช้งาน'
                      : 'ยังไม่พบบริการที่ควรยกเลิก',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (hasUnused)
                  Text(
                    'อาจประหยัดได้ ฿${monthlySavings.toStringAsFixed(0)}/เดือน',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          if (hasUnused)
            TextButton(onPressed: onOpenSavings, child: const Text('ตรวจสอบ')),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
        Text(
          subtitle,
          style: const TextStyle(color: AppColors.textTertiary, fontSize: 11),
        ),
      ],
    );
  }
}

class _DashboardError extends StatelessWidget {
  const _DashboardError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FilledButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('โหลดข้อมูลอีกครั้ง'),
      ),
    );
  }
}
