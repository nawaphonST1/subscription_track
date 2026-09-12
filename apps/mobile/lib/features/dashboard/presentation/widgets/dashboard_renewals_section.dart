import 'package:flutter/material.dart';
import 'package:subscription_track/core/widgets/service_icon.dart';
import 'package:subscription_track/features/dashboard/application/dashboard_summary_provider.dart';

class DashboardRenewalsSection extends StatelessWidget {
  const DashboardRenewalsSection({
    required this.renewals,
    this.useGrid = false,
    super.key,
  });

  final List<DashboardRenewal> renewals;
  final bool useGrid;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'รายการใกล้ตัดเงิน',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              'เรียงตามวันชำระถัดไป',
              style: TextStyle(
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (useGrid)
          GridView.builder(
            key: const Key('renewals-desktop-grid'),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: renewals.length,
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 250,
              mainAxisExtent: 90,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemBuilder: (context, index) =>
                _RenewalCard(renewal: renewals[index], fillWidth: true),
          )
        else
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: renewals.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) =>
                  _RenewalCard(renewal: renewals[index], fillWidth: false),
            ),
          ),
      ],
    );
  }
}

class _RenewalCard extends StatelessWidget {
  const _RenewalCard({required this.renewal, required this.fillWidth});

  final DashboardRenewal renewal;
  final bool fillWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final daysLeft = renewal.nextBillingDate
        ?.difference(DateTime.now())
        .inDays
        .clamp(0, 999);

    return Container(
      width: fillWidth ? null : 154,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          ServiceIcon(serviceName: renewal.name, category: renewal.category),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  renewal.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  daysLeft == null ? 'ยังไม่กำหนดวัน' : 'อีก $daysLeft วัน',
                  style: TextStyle(
                    color: theme.textTheme.bodySmall?.color,
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
