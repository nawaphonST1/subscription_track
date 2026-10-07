import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subscription_track/core/layout/app_breakpoints.dart';
import 'package:subscription_track/core/theme/app_colors.dart';
import 'package:subscription_track/core/widgets/confirmation_dialog.dart';
import 'package:subscription_track/core/widgets/pin_verification_dialog.dart';
import 'package:subscription_track/features/savings/application/savings_provider.dart';
import 'package:subscription_track/features/savings/data/remote_savings_repository.dart';
import 'package:subscription_track/features/savings/presentation/widgets/savings_checklist.dart';
import 'package:subscription_track/features/savings/presentation/widgets/savings_summary.dart';

class SavingsTab extends ConsumerWidget {
  const SavingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = ref.read(savingsActionsProvider);
    return ref
        .watch(savingsViewStateProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: FilledButton(
              onPressed: actions.refresh,
              child: const Text('โหลดข้อมูลอีกครั้ง'),
            ),
          ),
          data: (state) => _SavingsContent(state: state),
        );
  }
}

class _SavingsContent extends ConsumerWidget {
  const _SavingsContent({required this.state});

  final SavingsViewState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = ref.read(savingsActionsProvider);
    final summary = SavingsSummary(
      selectedCount: state.selectedCount,
      yearlySavings: state.yearlySavings,
      onCancelSelected: state.hasSelection
          ? () => _confirmCancellation(context, actions)
          : null,
    );
    final checklist = SavingsChecklist(
      items: state.items,
      onToggle: actions.toggleSelection,
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

  Future<void> _confirmCancellation(
    BuildContext context,
    SavingsActions actions,
  ) async {
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'ยืนยันการยกเลิก',
      message: 'นำ ${state.selectedCount} รายการออกจากรายการติดตามหรือไม่?',
      confirmText: 'ยกเลิกรายการ',
      cancelText: 'ย้อนกลับ',
      isDanger: true,
      icon: Icons.delete_sweep_rounded,
    );
    if (!confirmed || !context.mounted) return;

    final pin = await PinVerificationDialog.showForPin(
      context: context,
      title: 'ยืนยันการยกเลิกบริการ',
      message: 'กรุณากรอกรหัส PIN เพื่อยกเลิกบริการที่เลือกทั้งหมด ${state.selectedCount} รายการ',
    );
    if (pin == null || !context.mounted) return;

    final selectedIds = state.items
        .where((item) => item.isSelected)
        .map((item) => item.id)
        .toList(growable: false);

    try {
      final result = await actions.batchCancel(selectedIds, pin);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'ยกเลิกบริการแล้ว ${result.cancelledCount} รายการ '
            '(ประหยัด ฿${result.totalYearlySavingsUnlocked.toStringAsFixed(0)}/ปี)',
          ),
        ),
      );
    } on PinLockoutException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: AppColors.danger,
        ),
      );
    } on InvalidPinException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: AppColors.danger,
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ทำรายการไม่สำเร็จ กรุณาลองอีกครั้ง')),
      );
    }
  }
}
