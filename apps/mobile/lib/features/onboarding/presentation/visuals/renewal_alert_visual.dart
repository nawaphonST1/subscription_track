import 'package:flutter/material.dart';
import 'package:subscription_track/core/theme/app_colors.dart';
import 'package:subscription_track/core/theme/app_typography.dart';

class RenewalAlertVisual extends StatelessWidget {
  const RenewalAlertVisual({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth * 0.9).clamp(300.0, 380.0);
        return SizedBox(
          height: 240,
          width: double.infinity,
          child: Center(
            child: Container(
              width: cardWidth,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.bgSecondary,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.45),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.success.withValues(alpha: 0.18),
                    blurRadius: 22,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: AppColors.bgTertiary,
                    radius: 24,
                    child: Icon(
                      Icons.notifications_active,
                      color: AppColors.success,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'แจ้งเตือนการต่ออายุ',
                          style: AppTypography.labelLarge.copyWith(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Disney+ จะต่ออายุในอีก 2 วัน (\$13.99)',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
