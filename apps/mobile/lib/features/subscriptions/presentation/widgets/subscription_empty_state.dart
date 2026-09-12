import 'package:flutter/material.dart';

class SubscriptionEmptyState extends StatelessWidget {
  const SubscriptionEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 44,
            color: theme.textTheme.bodySmall?.color,
          ),
          const SizedBox(height: 10),
          const Text('ไม่พบบริการที่ตรงกับการค้นหา'),
        ],
      ),
    );
  }
}
