import 'package:flutter/material.dart';
import 'package:subscription_track/features/subscriptions/domain/subscription.dart';

class UsageStatusSelector extends StatelessWidget {
  const UsageStatusSelector({
    required this.selectedStatus,
    required this.onChanged,
    super.key,
  });

  final UsageStatus selectedStatus;
  final ValueChanged<UsageStatus> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ระดับการใช้งานในปัจจุบัน',
          style: TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        _StatusOption(
          status: UsageStatus.frequent,
          selectedStatus: selectedStatus,
          title: 'ใช้งานบ่อย (Frequent)',
          description: 'เปิดใช้งานเกือบทุกวัน คุ้มค่ากับราคา',
          color: const Color(0xFF10B981),
          onTap: onChanged,
        ),
        const SizedBox(height: 10),
        _StatusOption(
          status: UsageStatus.moderate,
          selectedStatus: selectedStatus,
          title: 'ใช้งานปานกลาง (Moderate)',
          description: 'เปิดใช้งานบ้างสัปดาห์ละ 1-2 ครั้ง',
          color: const Color(0xFFD97706),
          onTap: onChanged,
        ),
        const SizedBox(height: 10),
        _StatusOption(
          status: UsageStatus.unused,
          selectedStatus: selectedStatus,
          title: 'ไม่ได้ใช้งานเลย (Unused)',
          description: 'ไม่ได้เข้าใช้งานเลย แนะนำให้ยกเลิกบริการ',
          color: const Color(0xFFEF4444),
          onTap: onChanged,
        ),
      ],
    );
  }
}

class _StatusOption extends StatelessWidget {
  const _StatusOption({
    required this.status,
    required this.selectedStatus,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  final UsageStatus status;
  final UsageStatus selectedStatus;
  final String title;
  final String description;
  final Color color;
  final ValueChanged<UsageStatus> onTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = status == selectedStatus;
    return InkWell(
      onTap: () => onTap(status),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF131C2E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : const Color(0xFF243049),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? color : const Color(0xFF475569),
              size: 18,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFFCBD5E1),
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
