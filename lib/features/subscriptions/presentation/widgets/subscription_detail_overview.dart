import 'package:flutter/material.dart';
import 'package:subscription_track/core/theme/app_colors.dart';
import 'package:subscription_track/features/subscriptions/domain/subscription.dart';
import 'package:subscription_track/features/subscriptions/presentation/subscription_ui_extensions.dart';

class SubscriptionDetailOverview extends StatelessWidget {
  const SubscriptionDetailOverview({required this.subscription, super.key});

  final Subscription subscription;

  @override
  Widget build(BuildContext context) {
    final nextBillingDate =
        subscription.nextBillingDate?.toLocal().toString().split(' ')[0] ??
        'ยังไม่กำหนด';

    return Column(
      children: [
        _DetailRow(label: 'หมวดหมู่', value: subscription.category),
        _DetailRow(label: 'งวดชำระ', value: subscription.billingPeriod),
        _DetailRow(label: 'วันชำระครั้งถัดไป', value: nextBillingDate),
        _DetailRow(
          label: 'ค่าใช้จ่ายต่อเดือน',
          value: '฿${subscription.monthlyPrice.toStringAsFixed(0)}',
        ),
        _DetailRow(
          label: 'สถานะการใช้งาน',
          value: subscription.usageStatusText,
        ),
        _DetailRow(
          label: 'ความเชื่อมั่น',
          value: '${subscription.confidence}%',
        ),
      ],
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
