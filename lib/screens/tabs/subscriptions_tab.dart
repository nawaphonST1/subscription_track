import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subscription_track/core/layout/app_breakpoints.dart';
import 'package:subscription_track/core/theme/app_colors.dart';
import 'package:subscription_track/models/subscription.dart';
import 'package:subscription_track/providers/main_navigation_provider.dart';
import 'package:subscription_track/providers/subscription_provider.dart';
import 'package:subscription_track/widgets/common/confirmation_dialog.dart';

class SubscriptionsTab extends ConsumerWidget {
  const SubscriptionsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final subscriptions = ref.watch(visibleSubscriptionsProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final useGrid = constraints.maxWidth >= AppBreakpoints.tablet;

        return Column(
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppBreakpoints.contentMaxWidth,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                  child: Column(
                    children: [
                      TextField(
                        key: const Key('subscription-search-field'),
                        onChanged: ref
                            .read(searchQueryProvider.notifier)
                            .update,
                        textInputAction: TextInputAction.search,
                        decoration: const InputDecoration(
                          hintText: 'ค้นหาตามชื่อบริการ...',
                          prefixIcon: Icon(Icons.search_rounded),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (final category
                                in SubscriptionCategoryFilter.values)
                              Padding(
                                padding: const EdgeInsets.only(right: 7),
                                child: ChoiceChip(
                                  key: Key('category-${category.name}'),
                                  label: Text(category.label),
                                  selected: selectedCategory == category,
                                  onSelected: (_) => ref
                                      .read(selectedCategoryProvider.notifier)
                                      .select(category),
                                  selectedColor: AppColors.primary,
                                  backgroundColor: AppColors.bgSecondary,
                                  side: BorderSide(
                                    color: selectedCategory == category
                                        ? AppColors.primary
                                        : AppColors.border,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: subscriptions.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: FilledButton.icon(
                    onPressed: ref
                        .read(subscriptionListProvider.notifier)
                        .refresh,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('ลองอีกครั้ง'),
                  ),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return const _EmptySubscriptions();
                  }
                  Widget buildTile(BuildContext context, int index) {
                    final subscription = items[index];
                    return _SubscriptionListTile(
                      subscription: subscription,
                      onToggle: () => ref
                          .read(subscriptionListProvider.notifier)
                          .toggleSelection(subscription.id),
                      onDelete: () =>
                          _deleteSubscription(context, ref, subscription),
                      onShowDetails: () =>
                          _showSubscriptionDetails(context, ref, subscription),
                    );
                  }

                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: AppBreakpoints.contentMaxWidth,
                      ),
                      child: useGrid
                          ? GridView.builder(
                              key: const Key('subscriptions-desktop-grid'),
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                              itemCount: items.length,
                              gridDelegate:
                                  const SliverGridDelegateWithMaxCrossAxisExtent(
                                    maxCrossAxisExtent: 560,
                                    mainAxisExtent: 76,
                                    crossAxisSpacing: 10,
                                    mainAxisSpacing: 10,
                                  ),
                              itemBuilder: buildTile,
                            )
                          : ListView.separated(
                              key: const PageStorageKey<String>(
                                'subscriptions-tab',
                              ),
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                              itemCount: items.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 10),
                              itemBuilder: buildTile,
                            ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showSubscriptionDetails(
    BuildContext context,
    WidgetRef ref,
    Subscription subscription,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.bgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return _SubscriptionDetailSheet(
          subscription: subscription,
          onSaved: (updatedSubscription) {
            ref
                .read(subscriptionListProvider.notifier)
                .updateSubscription(updatedSubscription);
          },
        );
      },
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

class _SubscriptionListTile extends StatelessWidget {
  const _SubscriptionListTile({
    required this.subscription,
    required this.onToggle,
    required this.onDelete,
    required this.onShowDetails,
  });

  final Subscription subscription;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onShowDetails;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.bgSecondary,
      borderRadius: BorderRadius.circular(14),
      child: ListTile(
        key: Key('subscription-${subscription.id}'),
        onTap: onShowDetails,
        contentPadding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
        leading: CircleAvatar(
          backgroundColor: AppColors.bgPrimary,
          child: Icon(subscription.iconData, color: subscription.iconColor),
        ),
        title: Text(
          subscription.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '${subscription.billingPeriod} • ${subscription.usageStatusText}',
            style: TextStyle(
              color: subscription.usageStatusColor,
              fontSize: 11,
            ),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '฿${subscription.monthlyPrice.toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            IconButton(
              tooltip: subscription.isSelected
                  ? 'นำออกจากรายการจำลอง'
                  : 'เพิ่มในรายการจำลอง',
              onPressed: onToggle,
              icon: Icon(
                subscription.isSelected
                    ? Icons.check_circle_rounded
                    : Icons.add_circle_outline_rounded,
                color: subscription.isSelected
                    ? AppColors.success
                    : AppColors.textTertiary,
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'ตัวเลือก',
              onSelected: (action) {
                if (action == 'delete') onDelete();
              },
              itemBuilder: (_) => const [
                PopupMenuItem<String>(value: 'delete', child: Text('ลบบริการ')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SubscriptionDetailSheet extends StatefulWidget {
  const _SubscriptionDetailSheet({
    required this.subscription,
    required this.onSaved,
  });

  final Subscription subscription;
  final ValueChanged<Subscription> onSaved;

  @override
  State<_SubscriptionDetailSheet> createState() =>
      _SubscriptionDetailSheetState();
}

class _SubscriptionDetailSheetState extends State<_SubscriptionDetailSheet> {
  late bool reminderEnabled = widget.subscription.reminderEnabled;
  late int reminderDays = _readReminderDays(widget.subscription);
  late bool markCancelled =
      widget.subscription.usageStatus.toLowerCase() == 'cancelled';

  @override
  Widget build(BuildContext context) {
    final nextBillingDate =
        widget.subscription.nextBillingDate?.toLocal().toString().split(
          ' ',
        )[0] ??
        'ยังไม่กำหนด';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.bgPrimary,
                  child: Icon(
                    widget.subscription.iconData,
                    color: widget.subscription.iconColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.subscription.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.subscription.billingPeriod,
                        style: const TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'รายละเอียดบริการ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      reminderEnabled = widget.subscription.reminderEnabled;
                      reminderDays = _readReminderDays(widget.subscription);
                      markCancelled =
                          widget.subscription.usageStatus.toLowerCase() ==
                          'cancelled';
                    });
                  },
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  label: const Text('แก้ไข'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _DetailRow(label: 'หมวดหมู่', value: widget.subscription.category),
            _DetailRow(
              label: 'งวดชำระ',
              value: widget.subscription.billingPeriod,
            ),
            _DetailRow(label: 'วันชำระครั้งถัดไป', value: nextBillingDate),
            _DetailRow(
              label: 'ค่าใช้จ่ายต่อเดือน',
              value: '฿${widget.subscription.monthlyPrice.toStringAsFixed(0)}',
            ),
            _DetailRow(
              label: 'สถานะการใช้งาน',
              value: widget.subscription.usageStatusText,
            ),
            _DetailRow(
              label: 'ความเชื่อมั่น',
              value: '${widget.subscription.confidence}%',
            ),
            const SizedBox(height: 16),
            const Text(
              'การแจ้งเตือน',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'เปิดการแจ้งเตือน',
                style: TextStyle(color: Colors.white),
              ),
              value: reminderEnabled,
              onChanged: (value) {
                setState(() {
                  reminderEnabled = value;
                  if (!value) {
                    reminderDays = 0;
                  } else if (reminderDays == 0) {
                    reminderDays = 3;
                  }
                });
              },
            ),
            if (reminderEnabled)
              Wrap(
                spacing: 8,
                children: [
                  _ReminderChip(
                    key: const Key('reminder-3-days'),
                    label: '3 วัน',
                    selected: reminderDays == 3,
                    onTap: () {
                      setState(() => reminderDays = 3);
                    },
                  ),
                  _ReminderChip(
                    key: const Key('reminder-7-days'),
                    label: '7 วัน',
                    selected: reminderDays == 7,
                    onTap: () {
                      setState(() => reminderDays = 7);
                    },
                  ),
                ],
              ),
            const SizedBox(height: 12),
            CheckboxListTile.adaptive(
              key: const Key('mark-subscription-cancelled'),
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'ยกเลิกแล้ว',
                style: TextStyle(color: Colors.white),
              ),
              value: markCancelled,
              onChanged: (value) {
                setState(() => markCancelled = value ?? false);
              },
            ),
            const SizedBox(height: 16),
            if (reminderEnabled)
              Text(
                'เตือนล่วงหน้า $reminderDays วัน',
                style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 12,
                ),
              ),
            if (markCancelled)
              const Text(
                'ยกเลิกแล้ว',
                key: Key('cancelled-status-label'),
                style: TextStyle(color: AppColors.success, fontSize: 12),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('ยกเลิก'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    key: const Key('save-subscription-details'),
                    onPressed: () {
                      final reminderFields = widget.subscription.customFields
                          .where((entry) => entry['key'] != 'reminderDays')
                          .toList(growable: false);

                      final updatedSubscription = widget.subscription.copyWith(
                        reminderEnabled: reminderEnabled,
                        usageStatus: markCancelled
                            ? 'cancelled'
                            : (widget.subscription.usageStatus.toLowerCase() ==
                                      'cancelled'
                                  ? 'moderate'
                                  : widget.subscription.usageStatus),
                        customFields: reminderEnabled
                            ? [
                                ...reminderFields,
                                {
                                  'key': 'reminderDays',
                                  'value': reminderDays.toString(),
                                },
                              ]
                            : reminderFields,
                      );

                      widget.onSaved(updatedSubscription);
                      Navigator.of(context).pop();
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    child: const Text('บันทึก'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static int _readReminderDays(Subscription subscription) {
    if (!subscription.reminderEnabled) return 0;

    for (final field in subscription.customFields) {
      if (field['key'] == 'reminderDays') {
        final days = int.tryParse(field['value'] ?? '');
        if (days == 3 || days == 7) return days!;
      }
    }
    return 3;
  }
}

class _ReminderChip extends StatelessWidget {
  const _ReminderChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.bgPrimary,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textTertiary,
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySubscriptions extends StatelessWidget {
  const _EmptySubscriptions();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 44,
            color: AppColors.textTertiary,
          ),
          SizedBox(height: 10),
          Text('ไม่พบบริการที่ตรงกับการค้นหา'),
        ],
      ),
    );
  }
}
