import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subscription_track/core/theme/app_colors.dart';
import 'package:subscription_track/models/subscription.dart';
import 'package:subscription_track/providers/main_navigation_provider.dart';
import 'package:subscription_track/providers/subscription_provider.dart';

class SubscriptionsTab extends ConsumerWidget {
  const SubscriptionsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final subscriptions = ref.watch(visibleSubscriptionsProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
          child: Column(
            children: [
              TextField(
                key: const Key('subscription-search-field'),
                onChanged: ref.read(searchQueryProvider.notifier).update,
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
                    for (final category in SubscriptionCategoryFilter.values)
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
            data: (items) {
              if (items.isEmpty) {
                return const _EmptySubscriptions();
              }
              return ListView.separated(
                key: const PageStorageKey<String>('subscriptions-tab'),
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) => _SubscriptionListTile(
                  subscription: items[index],
                  onToggle: () => ref
                      .read(subscriptionListProvider.notifier)
                      .toggleSelection(items[index].id),
                  onDelete: () =>
                      _deleteSubscription(context, ref, items[index]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _deleteSubscription(
    BuildContext context,
    WidgetRef ref,
    Subscription subscription,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ลบบริการนี้หรือไม่?'),
        content: Text(subscription.name),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('ไม่ลบ'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );
    if (shouldDelete != true || !context.mounted) return;

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
  });

  final Subscription subscription;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.bgSecondary,
      borderRadius: BorderRadius.circular(14),
      child: ListTile(
        key: Key('subscription-${subscription.id}'),
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
