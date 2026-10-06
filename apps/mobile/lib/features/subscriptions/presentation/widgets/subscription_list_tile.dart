import 'package:flutter/material.dart';
import 'package:subscription_track/core/theme/app_colors.dart';
import 'package:subscription_track/core/widgets/service_icon.dart';
import 'package:subscription_track/features/subscriptions/domain/subscription.dart';
import 'package:subscription_track/features/subscriptions/presentation/subscription_ui_extensions.dart';

class SubscriptionListTile extends StatelessWidget {
  const SubscriptionListTile({
    required this.subscription,
    required this.onToggle,
    required this.onDelete,
    required this.onShowDetails,
    super.key,
  });

  final Subscription subscription;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onShowDetails;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2E3D5B) : const Color(0xFFCBD5E1),
          width: 1.3,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.07),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: ListTile(
          key: Key('subscription-${subscription.id}'),
          onTap: onShowDetails,
          contentPadding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
          leading: CircleAvatar(
            backgroundColor: isDark
                ? const Color(0xFF1E293B)
                : const Color(0xFFF1F5F9),
            child: ServiceIcon(
              serviceName: subscription.name,
              category: subscription.category,
            ),
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
                    : theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
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
    ),
  );
  }
}
