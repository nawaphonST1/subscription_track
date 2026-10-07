import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subscription_track/features/subscriptions/application/subscription_list_controller.dart';
import 'package:subscription_track/features/subscriptions/domain/subscription.dart';

enum SubscriptionCategoryFilter {
  all('ทั้งหมด'),
  streaming('สตรีมมิ่ง'),
  music('เพลง'),
  productivity('การทำงาน'),
  entertainment('ความบันเทิง'),
  cloud('คลาวด์'),
  development('นักพัฒนา'),
  ai('AI'),
  creative('สร้างสรรค์');

  const SubscriptionCategoryFilter(this.label);

  final String label;

  static SubscriptionCategoryFilter fromKey(String key) {
    final lower = key.toLowerCase();
    for (final val in values) {
      if (val.name == lower) return val;
    }
    return switch (lower) {
      'music' => SubscriptionCategoryFilter.music,
      'entertainment' => SubscriptionCategoryFilter.entertainment,
      'productivity' => SubscriptionCategoryFilter.productivity,
      'development' => SubscriptionCategoryFilter.development,
      _ => SubscriptionCategoryFilter.all,
    };
  }

  bool matches(Subscription subscription) {
    final cat = subscription.category.toLowerCase();
    return switch (this) {
      SubscriptionCategoryFilter.all => true,
      SubscriptionCategoryFilter.streaming =>
        cat == 'streaming' || cat == 'music' || cat == 'entertainment',
      SubscriptionCategoryFilter.music => cat == 'music',
      SubscriptionCategoryFilter.productivity =>
        cat == 'productivity' || cat == 'ai',
      SubscriptionCategoryFilter.entertainment =>
        cat == 'entertainment' || cat == 'streaming',
      SubscriptionCategoryFilter.cloud => cat == 'cloud',
      SubscriptionCategoryFilter.development =>
        cat == 'development' || cat == 'dev',
      SubscriptionCategoryFilter.ai =>
        cat == 'ai' || cat == 'productivity',
      SubscriptionCategoryFilter.creative =>
        cat == 'creative' || cat == 'design',
    };
  }
}

class CategoryFilterItem {
  const CategoryFilterItem({
    required this.key,
    required this.label,
  });

  final String key;
  final String label;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryFilterItem &&
          runtimeType == other.runtimeType &&
          key.toLowerCase() == other.key.toLowerCase();

  @override
  int get hashCode => key.toLowerCase().hashCode;
}

String formatCategoryLabel(String key) {
  return switch (key.toLowerCase()) {
    'all' => 'ทั้งหมด',
    'streaming' => 'สตรีมมิ่ง',
    'music' => 'เพลง',
    'productivity' => 'การทำงาน',
    'entertainment' => 'ความบันเทิง',
    'cloud' => 'คลาวด์',
    'development' => 'นักพัฒนา',
    'ai' => 'AI',
    'creative' => 'สร้างสรรค์',
    'education' => 'การศึกษา',
    'gaming' => 'เกม',
    _ => key,
  };
}

class SubscriptionFilterState {
  const SubscriptionFilterState({
    this.query = '',
    this.selectedCategory = 'all',
  });

  final String query;
  final String selectedCategory;

  SubscriptionCategoryFilter get category =>
      SubscriptionCategoryFilter.fromKey(selectedCategory);

  SubscriptionFilterState copyWith({
    String? query,
    String? selectedCategory,
    SubscriptionCategoryFilter? category,
  }) {
    return SubscriptionFilterState(
      query: query ?? this.query,
      selectedCategory: selectedCategory ??
          (category != null ? category.name : this.selectedCategory),
    );
  }
}

final subscriptionFilterProvider =
    NotifierProvider<SubscriptionFilterController, SubscriptionFilterState>(
      SubscriptionFilterController.new,
    );

final availableCategoriesProvider = Provider<List<CategoryFilterItem>>((ref) {
  final subscriptions = ref.watch(subscriptionListProvider).value ?? const [];

  final userCategories = <String>{};
  for (final sub in subscriptions) {
    final cat = sub.category.trim();
    if (cat.isNotEmpty) {
      userCategories.add(cat);
    }
  }

  const backendCategories = [
    'Streaming',
    'Music',
    'Productivity',
    'Entertainment',
    'Cloud',
    'Development',
  ];

  final orderedKeys = <String>[];
  for (final cat in userCategories) {
    if (!orderedKeys.any((k) => k.toLowerCase() == cat.toLowerCase())) {
      orderedKeys.add(cat);
    }
  }
  for (final cat in backendCategories) {
    if (!orderedKeys.any((k) => k.toLowerCase() == cat.toLowerCase())) {
      orderedKeys.add(cat);
    }
  }

  return [
    const CategoryFilterItem(key: 'all', label: 'ทั้งหมด'),
    for (final key in orderedKeys)
      CategoryFilterItem(key: key, label: formatCategoryLabel(key)),
  ];
});

final visibleSubscriptionsProvider = Provider<AsyncValue<List<Subscription>>>((
  ref,
) {
  final filter = ref.watch(subscriptionFilterProvider);
  final query = filter.query.trim().toLowerCase();
  final target = filter.selectedCategory.trim().toLowerCase();

  return ref.watch(subscriptionListProvider).whenData((subscriptions) {
    return subscriptions
        .where((subscription) {
          final matchesQuery =
              query.isEmpty || subscription.name.toLowerCase().contains(query);
          if (!matchesQuery) return false;

          if (target == 'all' || target.isEmpty) return true;

          final subCat = subscription.category.trim().toLowerCase();
          if (subCat == target) return true;

          if (target == 'ai' && (subCat == 'productivity' || subCat == 'ai')) {
            return true;
          }
          if (target == 'productivity' &&
              (subCat == 'productivity' || subCat == 'ai')) {
            return true;
          }
          if (target == 'creative' &&
              (subCat == 'creative' || subCat == 'design')) {
            return true;
          }
          if (target == 'streaming' &&
              (subCat == 'streaming' ||
                  subCat == 'entertainment' ||
                  subCat == 'music')) {
            return true;
          }
          if (target == 'entertainment' &&
              (subCat == 'entertainment' || subCat == 'streaming')) {
            return true;
          }
          if (target == 'development' &&
              (subCat == 'development' || subCat == 'dev')) {
            return true;
          }

          return false;
        })
        .toList(growable: false);
  });
});

final class SubscriptionFilterController
    extends Notifier<SubscriptionFilterState> {
  @override
  SubscriptionFilterState build() => const SubscriptionFilterState();

  void updateQuery(String query) => state = state.copyWith(query: query);

  void selectCategory(SubscriptionCategoryFilter category) {
    state = state.copyWith(selectedCategory: category.name);
  }

  void selectCategoryKey(String categoryKey) {
    state = state.copyWith(selectedCategory: categoryKey);
  }

  void clear() => state = const SubscriptionFilterState();
}
