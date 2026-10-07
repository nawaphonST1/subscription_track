import 'package:flutter/material.dart';
import 'package:subscription_track/features/subscriptions/domain/preset_plan.dart';

class PresetTierSelector extends StatelessWidget {
  const PresetTierSelector({
    required this.plans,
    required this.selectedTier,
    required this.brandColor,
    required this.onSelected,
    super.key,
  });

  final List<PresetPlan> plans;
  final String selectedTier;
  final Color brandColor;
  final ValueChanged<PresetPlan> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 88,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: plans.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final plan = plans[index];
          final isSelected = plan.tier == selectedTier;

          return GestureDetector(
            onTap: () => onSelected(plan),
            child: Container(
              width: 128,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? brandColor.withValues(alpha: 0.12)
                    : theme.cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? brandColor : theme.dividerColor,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.tier,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isSelected
                          ? brandColor
                          : theme.textTheme.titleSmall?.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '฿${plan.monthlyPrice.toStringAsFixed(0)}/เดือน',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
