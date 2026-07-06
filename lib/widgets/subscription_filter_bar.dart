import 'package:flutter/material.dart';

class SubscriptionFilterBar extends StatelessWidget {
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;

  static const List<String> filters = [
    'ทั้งหมด',
    'สตรีมมิ่ง',
    'AI',
    'คลาวด์',
    'สร้างสรรค์',
  ];

  const SubscriptionFilterBar({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: filters.map((filter) {
        final isSelected = selectedFilter == filter;
        return ChoiceChip(
          label: Text(filter),
          selected: isSelected,
          onSelected: (_) => onFilterChanged(filter),
          selectedColor: const Color(0xFF2563EB),
          backgroundColor: const Color(0xFF131C2E),
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF94A3B8),
            fontWeight: FontWeight.w600,
          ),
          side: BorderSide(
            color: isSelected ? const Color(0xFF60A5FA) : const Color(0xFF243049),
          ),
        );
      }).toList(),
    );
  }
}
