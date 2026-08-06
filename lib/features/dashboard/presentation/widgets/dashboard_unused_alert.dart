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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasUnused = count > 0;

    final baseColor = hasUnused ? AppColors.danger : AppColors.success;
    final bgAlpha = isDark ? 0.1 : 0.05;
    final borderAlpha = isDark ? 0.4 : 0.2;

    return Container(
      key: const Key('unused-service-alert'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: baseColor.withValues(alpha: bgAlpha),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: baseColor.withValues(alpha: borderAlpha)),
      ),
      child: Row(
        children: [
          Icon(
            hasUnused ? Icons.warning_amber_rounded : Icons.verified_rounded,
            color: baseColor,
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
                    style: TextStyle(
                      color: theme.textTheme.bodySmall?.color,
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
