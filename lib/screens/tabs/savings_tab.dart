import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subscription_track/core/layout/app_breakpoints.dart';
import 'package:subscription_track/core/theme/app_colors.dart';
import 'package:subscription_track/features/subscriptions/application/subscription_list_controller.dart';
import 'package:subscription_track/features/subscriptions/domain/subscription.dart';
import 'package:subscription_track/widgets/common/confirmation_dialog.dart';

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

    final summary = _SavingsSummary(
      selectedCount: selected.length,
      yearlySavings: yearlySavings,
      onCancelSelected: selected.isEmpty
          ? null
          : () => _cancelSelected(context, ref, selected.length),
    );
    final checklist = _SavingsChecklist(
      subscriptions: subscriptions,
      onToggle: (id) =>
          ref.read(subscriptionListProvider.notifier).toggleSelection(id),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final useTwoColumns = constraints.maxWidth >= AppBreakpoints.tablet;

        return ListView(
          key: const PageStorageKey<String>('savings-tab'),
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppBreakpoints.contentMaxWidth,
                ),
                child: useTwoColumns
                    ? Row(
                        key: const Key('savings-desktop-layout'),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: summary),
                          const SizedBox(width: 22),
                          Expanded(flex: 2, child: checklist),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          summary,
                          const SizedBox(height: 20),
                          checklist,
                        ],
                      ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _cancelSelected(
    BuildContext context,
    WidgetRef ref,
    int count,
  ) async {
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'ยืนยันการยกเลิก',
      message: 'นำ $count รายการออกจากรายการติดตามหรือไม่?',
      confirmText: 'ยกเลิกรายการ',
      cancelText: 'ย้อนกลับ',
      isDanger: true,
      icon: Icons.delete_sweep_rounded,
    );
    if (!confirmed || !context.mounted) return;

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

class _SavingsSummary extends StatelessWidget {
  const _SavingsSummary({
    required this.selectedCount,
    required this.yearlySavings,
    required this.onCancelSelected,
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
                'ยกเลิก $selectedCount รายการ ประหยัด ฿${yearlySavings.toStringAsFixed(0)}/ปี',
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

class _SavingsChecklist extends StatelessWidget {
  const _SavingsChecklist({
    required this.subscriptions,
    required this.onToggle,
  });

  final List<Subscription> subscriptions;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'เลือกรายการที่ต้องการยกเลิก',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        for (final subscription in subscriptions)
          _SavingsChecklistTile(
            subscription: subscription,
            onChanged: () => onToggle(subscription.id),
          ),
      ],
    );
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
