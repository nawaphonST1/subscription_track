import 'package:flutter/material.dart';
import 'package:subscription_track/core/theme/app_colors.dart';

class DashboardHeroCard extends StatelessWidget {
  const DashboardHeroCard({
    required this.monthlyTotal,
    required this.creepScore,
    super.key,
  });

  final double monthlyTotal;
  final double creepScore;

  @override
  Widget build(BuildContext context) {
    final riskColor = creepScore >= 10
        ? AppColors.danger
        : creepScore >= 5
        ? AppColors.warning
        : AppColors.success;

    return Container(
      key: const Key('hero-payout-card'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF182541), AppColors.bgSecondary],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'รายจ่ายค่าสมาชิกรวม',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: riskColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  child: Text(
                    'Creep Risk ${creepScore.toStringAsFixed(1)}%',
                    key: const Key('creep-risk-value'),
                    style: TextStyle(
                      color: riskColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '฿${monthlyTotal.toStringAsFixed(0)} / เดือน',
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'คิดเป็น ฿${(monthlyTotal * 12).toStringAsFixed(0)} ต่อปี',
            style: const TextStyle(
              color: AppColors.primaryLight,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
