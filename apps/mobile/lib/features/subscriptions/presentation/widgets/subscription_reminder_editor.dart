import 'package:flutter/material.dart';

class SubscriptionReminderEditor extends StatelessWidget {
  const SubscriptionReminderEditor({
    required this.enabled,
    required this.days,
    required this.onEnabledChanged,
    required this.onDaysChanged,
    super.key,
  });

  final bool enabled;
  final int days;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<int> onDaysChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'การแจ้งเตือน',
          style: TextStyle(
            color: theme.textTheme.titleMedium?.color,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text(
            'เปิดการแจ้งเตือน',
            style: TextStyle(color: theme.textTheme.bodyLarge?.color),
          ),
          value: enabled,
          onChanged: onEnabledChanged,
        ),
        if (enabled)
          Wrap(
            spacing: 8,
            children: [
              _ReminderChip(
                key: const Key('reminder-3-days'),
                label: '3 วัน',
                selected: days == 3,
                onTap: () => onDaysChanged(3),
              ),
              _ReminderChip(
                key: const Key('reminder-7-days'),
                label: '7 วัน',
                selected: days == 7,
                onTap: () => onDaysChanged(7),
              ),
            ],
          ),
      ],
    );
  }
}

class _ReminderChip extends StatelessWidget {
  const _ReminderChip({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? theme.colorScheme.primary : theme.cardColor,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? theme.colorScheme.primary : theme.dividerColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? theme.colorScheme.onPrimary
                : theme.textTheme.bodyMedium?.color,
          ),
        ),
      ),
    );
  }
}
