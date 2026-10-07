import 'package:flutter/material.dart';
import 'package:subscription_track/core/theme/app_colors.dart';

class DashboardHeroCard extends StatelessWidget {
  const DashboardHeroCard({
    required this.monthlyTotal,
    required this.creepScore,
    this.totalCardFunds = 0,
    super.key,
  });

  final double monthlyTotal;
  final double creepScore;
  final double totalCardFunds;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final riskColor = creepScore >= 10
        ? AppColors.danger
        : creepScore >= 5
        ? AppColors.warning
        : AppColors.success;

    return Container(
      key: const Key('hero-payout-card'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? theme.colorScheme.primary.withValues(alpha: 0.45)
              : const Color(0xFFCBD5E1),
          width: 1.3,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
        gradient: isDark
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [const Color(0xFF182541), theme.cardColor],
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'รายจ่ายค่าสมาชิกรวม',
                  style: TextStyle(color: theme.textTheme.bodySmall?.color),
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
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (totalCardFunds > 0) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet_rounded,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'ยอดเงินในบัตรที่ผูก: ฿${totalCardFunds.toStringAsFixed(0)}',
                    key: const Key('total-card-funds-label'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
