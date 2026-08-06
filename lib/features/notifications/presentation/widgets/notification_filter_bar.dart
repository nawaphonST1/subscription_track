import 'package:flutter/material.dart';
import 'package:subscription_track/features/notifications/application/notification_center_controller.dart';

class NotificationFilterBar extends StatelessWidget {
  const NotificationFilterBar({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final NotificationFilter selected;
  final ValueChanged<NotificationFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          for (final filter in NotificationFilter.values) ...[
            _FilterChip(
              label: filter.label,
              selected: selected == filter,
              onTap: () => onSelected(filter),
            ),
            if (filter != NotificationFilter.values.last)
              const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

extension on NotificationFilter {
  String get label => switch (this) {
    NotificationFilter.all => 'ทั้งหมด',
    NotificationFilter.unread => 'ยังไม่ได้อ่าน',
    NotificationFilter.read => 'อ่านแล้ว',
  };
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: selected
              ? theme.colorScheme.onPrimary
              : theme.textTheme.bodyMedium?.color,
          fontSize: 13,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: selected,
      onSelected: (value) {
        if (value) onTap();
      },
      selectedColor: theme.colorScheme.primary,
      backgroundColor: theme.cardColor,
      side: BorderSide(
        color: selected ? theme.colorScheme.primary : theme.dividerColor,
        width: 1.5,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      showCheckmark: false,
    );
  }
}
