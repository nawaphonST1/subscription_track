import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subscription_track/features/subscriptions/application/subscription_filter_controller.dart';
import 'package:subscription_track/features/subscriptions/application/subscription_list_controller.dart';
import 'package:subscription_track/features/subscriptions/domain/subscription.dart';
import 'package:subscription_track/features/subscriptions/presentation/widgets/subscription_collection.dart';
import 'package:subscription_track/features/subscriptions/presentation/widgets/subscription_detail_sheet.dart';
import 'package:subscription_track/features/subscriptions/presentation/widgets/subscription_empty_state.dart';
import 'package:subscription_track/features/subscriptions/presentation/widgets/subscription_filter_bar.dart';
import 'package:subscription_track/core/widgets/confirmation_dialog.dart';
import 'package:subscription_track/core/widgets/pin_verification_dialog.dart';

class SubscriptionsTab extends ConsumerWidget {
  const SubscriptionsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(subscriptionFilterProvider);
    final subscriptions = ref.watch(visibleSubscriptionsProvider);

    return Column(
      children: [
        SubscriptionFilterBar(
          filter: filter,
          onQueryChanged: ref
              .read(subscriptionFilterProvider.notifier)
              .updateQuery,
          onCategorySelected: ref
              .read(subscriptionFilterProvider.notifier)
              .selectCategory,
        ),
        Expanded(
          child: subscriptions.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: FilledButton.icon(
                onPressed: ref.read(subscriptionListProvider.notifier).refresh,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('ลองอีกครั้ง'),
              ),
            ),
            data: (items) => items.isEmpty
                ? const SubscriptionEmptyState()
                : SubscriptionCollection(
                    subscriptions: items,
                    onToggle: (subscription) => ref
                        .read(subscriptionListProvider.notifier)
                        .toggleSelection(subscription.id),
                    onDelete: (subscription) =>
                        _deleteSubscription(context, ref, subscription),
                    onShowDetails: (subscription) =>
                        _showSubscriptionDetails(context, ref, subscription),
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _showSubscriptionDetails(
    BuildContext context,
    WidgetRef ref,
    Subscription subscription,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: const Color(0xFF151D31),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SubscriptionDetailSheet(
        subscription: subscription,
        onSaved: ref.read(subscriptionListProvider.notifier).updateSubscription,
      ),
    );
  }

  Future<void> _deleteSubscription(
    BuildContext context,
    WidgetRef ref,
    Subscription subscription,
  ) async {
    final shouldDelete = await ConfirmationDialog.show(
      context: context,
      title: 'ลบบริการนี้หรือไม่?',
      message: subscription.name,
      confirmText: 'ลบบริการ',
      cancelText: 'ไม่ลบ',
      isDanger: true,
      icon: Icons.delete_outline_rounded,
    );
    if (!shouldDelete || !context.mounted) return;

    final pinVerified = await PinVerificationDialog.show(
      context: context,
      title: 'ยืนยันการลบบริการ',
      message: 'กรุณากรอกรหัส PIN เพื่อลบบริการ ${subscription.name}',
    );
    if (!pinVerified || !context.mounted) return;

    try {
      await ref
          .read(subscriptionListProvider.notifier)
          .deleteSubscription(subscription.id);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ลบบริการไม่สำเร็จ กรุณาลองอีกครั้ง')),
      );
    }
  }
}
