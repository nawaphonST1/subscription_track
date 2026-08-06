import 'package:flutter/material.dart';
import 'package:subscription_track/core/theme/app_colors.dart';

class DashboardUnusedAlert extends StatelessWidget {
  const DashboardUnusedAlert({
    required this.count,
    required this.monthlySavings,
    required this.onOpenSavings,
    super.key,
  });

  final int count;
  final double monthlySavings;
  final VoidCallback onOpenSavings;

  @override
  Widget build(BuildContext context) {
    final hasUnused = count > 0;
    final statusColor = hasUnused ? AppColors.danger : AppColors.success;
    return Container(
      key: const Key('unused-service-alert'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(
            hasUnused ? Icons.warning_amber_rounded : Icons.verified_rounded,
            color: statusColor,
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
