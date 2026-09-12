import 'package:flutter/material.dart';
import 'package:subscription_track/core/widgets/service_icon.dart';
import 'package:subscription_track/features/subscriptions/domain/subscription.dart';

class SubscriptionDetailHeader extends StatelessWidget {
  const SubscriptionDetailHeader({
    required this.subscription,
    required this.onReset,
    super.key,
  });

  final Subscription subscription;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: theme.scaffoldBackgroundColor,
              child: ServiceIcon(
                serviceName: subscription.name,
                category: subscription.category,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subscription.name,
                    style: TextStyle(
                      color: theme.textTheme.titleMedium?.color,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subscription.billingPeriod,
                    style: TextStyle(
                      color: theme.textTheme.bodySmall?.color,
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
            Expanded(
              child: Text(
                'รายละเอียดบริการ',
                style: TextStyle(
                  color: theme.textTheme.titleMedium?.color,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.edit_rounded, size: 18),
              label: const Text('แก้ไข'),
            ),
          ],
        ),
      ],
    );
  }
}
