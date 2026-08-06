import 'package:flutter/material.dart';
import 'package:subscription_track/core/theme/app_colors.dart';
import 'package:subscription_track/core/widgets/service_icon.dart';
import 'package:subscription_track/features/savings/application/savings_provider.dart';

class SavingsChecklist extends StatelessWidget {
  const SavingsChecklist({
    required this.items,
    required this.onToggle,
    super.key,
  });

  final List<SavingsItem> items;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'เลือกรายการที่ต้องการยกเลิก',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        for (final item in items)
          _SavingsChecklistTile(item: item, onChanged: () => onToggle(item.id)),
      ],
    );
  }
}

class _SavingsChecklistTile extends StatelessWidget {
  const _SavingsChecklistTile({required this.item, required this.onChanged});

  final SavingsItem item;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: CheckboxListTile(
        key: Key('saving-${item.id}'),
        value: item.isSelected,
        onChanged: (_) => onChanged(),
        activeColor: AppColors.success,
        secondary: ServiceIcon(serviceName: item.name, category: item.category),
        title: Text(
          item.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '฿${item.monthlyPrice.toStringAsFixed(0)}/เดือน',
          style: TextStyle(
            color: theme.textTheme.bodySmall?.color,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}
