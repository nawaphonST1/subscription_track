import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subscription_track/core/theme/app_colors.dart';
import 'package:subscription_track/models/subscription.dart';
import 'package:subscription_track/providers/subscription_provider.dart';

class SavingsTab extends ConsumerWidget {
  const SavingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptions = ref.watch(subscriptionListProvider);
    return subscriptions.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: FilledButton(
          onPressed: ref.read(subscriptionListProvider.notifier).refresh,
          child: const Text('โหลดข้อมูลอีกครั้ง'),
        ),
      ),
      data: (items) => _SavingsContent(subscriptions: items),
    );
  }
}

class _SavingsContent extends ConsumerWidget {
  const _SavingsContent({required this.subscriptions});

  final List<Subscription> subscriptions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = subscriptions
        .where((item) => item.isSelected)
        .toList(growable: false);
    final yearlySavings =
        selected.fold<double>(0, (total, item) => total + item.monthlyPrice) *
        12;

    return ListView(
      key: const PageStorageKey<String>('savings-tab'),
      padding: const EdgeInsets.all(16),
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
                'ยกเลิก ${selected.length} รายการ ประหยัด ฿${yearlySavings.toStringAsFixed(0)}/ปี',
                key: const Key('savings-goal-value'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'เลือกรายการที่ต้องการยกเลิก',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        for (final subscription in subscriptions)
          _SavingsChecklistTile(
            subscription: subscription,
            onChanged: () => ref
                .read(subscriptionListProvider.notifier)
                .toggleSelection(subscription.id),
          ),
        const SizedBox(height: 12),
        FilledButton.icon(
          key: const Key('cancel-selected-button'),
          onPressed: selected.isEmpty
              ? null
              : () => _cancelSelected(context, ref, selected.length),
          icon: const Icon(Icons.delete_sweep_rounded),
          label: const Text('ยกเลิกรายการที่เลือกทั้งหมด'),
          style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
        ),
      ],
    );
  }

  Future<void> _cancelSelected(
    BuildContext context,
    WidgetRef ref,
    int count,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ยืนยันการยกเลิก'),
        content: Text('นำ $count รายการออกจากรายการติดตามหรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('ย้อนกลับ'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('ยืนยัน'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(subscriptionListProvider.notifier).deleteSelected();
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('ยกเลิกบริการแล้ว $count รายการ')));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ทำรายการไม่สำเร็จ กรุณาลองอีกครั้ง')),
      );
    }
  }
}

class _SavingsChecklistTile extends StatelessWidget {
  const _SavingsChecklistTile({
    required this.subscription,
    required this.onChanged,
  });

  final Subscription subscription;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: CheckboxListTile(
        key: Key('saving-${subscription.id}'),
        value: subscription.isSelected,
        onChanged: (_) => onChanged(),
        activeColor: AppColors.success,
        secondary: Icon(subscription.iconData, color: subscription.iconColor),
        title: Text(
          subscription.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '฿${subscription.monthlyPrice.toStringAsFixed(0)}/เดือน',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
      ),
    );
  }
}
