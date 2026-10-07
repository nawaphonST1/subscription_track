import 'package:flutter/material.dart';
import 'package:subscription_track/core/theme/app_colors.dart';

class SavingsSummary extends StatelessWidget {
  const SavingsSummary({
    required this.selectedCount,
    required this.yearlySavings,
    required this.onCancelSelected,
    this.totalPotentialSavings = 0,
    this.totalItemsCount = 0,
    super.key,
  });

  final int selectedCount;
  final double yearlySavings;
  final VoidCallback? onCancelSelected;
  final double totalPotentialSavings;
  final int totalItemsCount;

  @override
  Widget build(BuildContext context) {
    final hasSelection = selectedCount > 0;
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
              Text(
                hasSelection ? 'เป้าหมายการประหยัด' : 'โอกาสประหยัดค่าบริการ',
                style: const TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                hasSelection
                    ? 'ยกเลิก $selectedCount รายการ ประหยัด ฿${yearlySavings.toStringAsFixed(0)}/ปี'
                    : totalItemsCount > 0
                        ? 'ตรวจพบ $totalItemsCount บริการที่ไม่ได้ใช้งาน • ประหยัดได้สูงสุด ฿${totalPotentialSavings.toStringAsFixed(0)}/ปี'
                        : 'ยกเลิก 0 รายการ ประหยัด ฿0/ปี',
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
          label: Text(
            hasSelection
                ? 'ยกเลิก $selectedCount รายการที่เลือก'
                : 'เลือกรายการด้านล่างเพื่อยกเลิก',
          ),
          style: FilledButton.styleFrom(
            backgroundColor: hasSelection ? AppColors.danger : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
