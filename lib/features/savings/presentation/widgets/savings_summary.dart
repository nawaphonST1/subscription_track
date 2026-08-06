import 'package:flutter/material.dart';
import 'package:subscription_track/core/theme/app_colors.dart';

class SavingsSummary extends StatelessWidget {
  const SavingsSummary({
    required this.selectedCount,
    required this.yearlySavings,
    required this.onCancelSelected,
    super.key,
  });

  final int selectedCount;
  final double yearlySavings;
  final VoidCallback? onCancelSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          key: const Key('savings-goal-banner'),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'เป้าหมายการประหยัด',
                style: TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'ยกเลิก $selectedCount รายการ '
                'ประหยัด ฿${yearlySavings.toStringAsFixed(0)}/ปี',
                key: const Key('savings-goal-value'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          key: const Key('cancel-selected-button'),
          onPressed: onCancelSelected,
          icon: const Icon(Icons.delete_sweep_rounded),
          label: const Text('ยกเลิกรายการที่เลือกทั้งหมด'),
          style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
        ),
      ],
    );
  }
}
