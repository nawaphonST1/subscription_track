import 'package:flutter/material.dart';
import 'package:subscription_track/core/layout/app_breakpoints.dart';
import 'package:subscription_track/core/theme/app_colors.dart';
import 'package:subscription_track/features/subscriptions/application/subscription_filter_controller.dart';

class SubscriptionFilterBar extends StatelessWidget {
  const SubscriptionFilterBar({
    required this.filter,
    required this.onQueryChanged,
    required this.onCategorySelected,
    super.key,
  });

  final SubscriptionFilterState filter;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<SubscriptionCategoryFilter> onCategorySelected;

  @override
  Widget build(BuildContext context) {
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
                    for (final category in SubscriptionCategoryFilter.values)
                      Padding(
                        padding: const EdgeInsets.only(right: 7),
                        child: ChoiceChip(
                          key: Key('category-${category.name}'),
                          label: Text(category.label),
                          selected: filter.category == category,
                          onSelected: (_) => onCategorySelected(category),
                          selectedColor: AppColors.primary,
                          backgroundColor: AppColors.bgSecondary,
                          side: BorderSide(
                            color: filter.category == category
                                ? AppColors.primary
                                : AppColors.border,
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
