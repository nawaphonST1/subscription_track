import 'package:flutter/material.dart';
import 'package:subscription_track/core/theme/app_colors.dart';

class SubscriptionEmptyState extends StatelessWidget {
  const SubscriptionEmptyState({super.key});

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
