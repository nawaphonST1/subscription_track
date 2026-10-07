import 'package:flutter/material.dart';
import 'package:subscription_track/core/layout/app_breakpoints.dart';
import 'package:subscription_track/features/subscriptions/application/subscription_filter_controller.dart';

class SubscriptionFilterBar extends StatelessWidget {
  const SubscriptionFilterBar({
    required this.filter,
    required this.onQueryChanged,
    this.onCategorySelected,
    this.onCategoryKeySelected,
    this.categories,
    super.key,
  });

  final SubscriptionFilterState filter;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<SubscriptionCategoryFilter>? onCategorySelected;
  final ValueChanged<String>? onCategoryKeySelected;
  final List<CategoryFilterItem>? categories;

  static const defaultCategories = [
    CategoryFilterItem(key: 'all', label: 'ทั้งหมด'),
    CategoryFilterItem(key: 'streaming', label: 'สตรีมมิ่ง'),
    CategoryFilterItem(key: 'music', label: 'เพลง'),
    CategoryFilterItem(key: 'productivity', label: 'การทำงาน'),
    CategoryFilterItem(key: 'entertainment', label: 'ความบันเทิง'),
    CategoryFilterItem(key: 'cloud', label: 'คลาวด์'),
    CategoryFilterItem(key: 'development', label: 'นักพัฒนา'),
    CategoryFilterItem(key: 'ai', label: 'AI'),
    CategoryFilterItem(key: 'creative', label: 'สร้างสรรค์'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = categories ?? defaultCategories;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppBreakpoints.contentMaxWidth,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
          child: Column(
            children: [
              TextField(
                key: const Key('subscription-search-field'),
                onChanged: onQueryChanged,
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  hintText: 'ค้นหาตามชื่อบริการ...',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final item in items)
                      Padding(
                        padding: const EdgeInsets.only(right: 7),
                        child: ChoiceChip(
                          key: Key('category-${item.key.toLowerCase()}'),
                          label: Text(item.label),
                          selected: filter.selectedCategory.toLowerCase() ==
                              item.key.toLowerCase(),
                          onSelected: (_) {
                            if (onCategoryKeySelected != null) {
                              onCategoryKeySelected!(item.key);
                            } else if (onCategorySelected != null) {
                              onCategorySelected!(
                                SubscriptionCategoryFilter.fromKey(item.key),
                              );
                            }
                          },
                          selectedColor: theme.colorScheme.primary,
                          backgroundColor: theme.cardColor,
                          side: BorderSide(
                            color: filter.selectedCategory.toLowerCase() ==
                                    item.key.toLowerCase()
                                ? theme.colorScheme.primary
                                : theme.dividerColor,
                            width: 1.2,
                          ),
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
  }
}
