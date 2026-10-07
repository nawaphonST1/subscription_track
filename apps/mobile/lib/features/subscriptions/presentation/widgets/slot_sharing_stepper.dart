import 'package:flutter/material.dart';

class SlotSharingStepper extends StatelessWidget {
  const SlotSharingStepper({
    required this.sharedMembers,
    required this.maxSlots,
    required this.costPerSlot,
    required this.accentColor,
    required this.onChanged,
    super.key,
  });

  final int sharedMembers;
  final int maxSlots;
  final double costPerSlot;
  final Color accentColor;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (maxSlots <= 1) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'จำนวนคนที่หารค่าใช้จ่าย',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.textTheme.titleSmall?.color,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _StepperButton(
              icon: Icons.remove,
              onPressed: sharedMembers > 1
                  ? () => onChanged(sharedMembers - 1)
                  : null,
            ),
            SizedBox(
              width: 48,
              child: Text(
                '$sharedMembers',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _StepperButton(
              icon: Icons.add,
              onPressed: sharedMembers < maxSlots
                  ? () => onChanged(sharedMembers + 1)
                  : null,
            ),
            const SizedBox(width: 8),
            Text(
              'สูงสุด $maxSlots คน',
              style: TextStyle(
                fontSize: 12,
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
        if (sharedMembers > 1) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'หารแล้วเหลือเพียง ฿${costPerSlot.toStringAsFixed(0)}/คน/เดือน',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = onPressed != null;

    return IconButton.filled(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      style: IconButton.styleFrom(
        backgroundColor: enabled
            ? theme.colorScheme.primary.withValues(alpha: 0.12)
            : theme.disabledColor.withValues(alpha: 0.08),
        foregroundColor: enabled
            ? theme.colorScheme.primary
            : theme.disabledColor,
        minimumSize: const Size(36, 36),
      ),
    );
  }
}
