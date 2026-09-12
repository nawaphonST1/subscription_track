import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subscription_track/features/subscriptions/application/subscription_list_controller.dart';
import 'package:subscription_track/features/subscriptions/domain/subscription.dart';

enum SubscriptionCategoryFilter {
  all('ทั้งหมด'),
  streaming('สตรีมมิ่ง'),
  ai('AI'),
  cloud('คลาวด์'),
  creative('สร้างสรรค์');

  const SubscriptionCategoryFilter(this.label);

  final String label;

  bool matches(Subscription subscription) {
    final category = subscription.category.toLowerCase();
    return switch (this) {
      SubscriptionCategoryFilter.all => true,
      SubscriptionCategoryFilter.streaming =>
        category == 'streaming' || category == 'music',
      SubscriptionCategoryFilter.ai => category == 'ai',
      SubscriptionCategoryFilter.cloud => category == 'cloud',
      SubscriptionCategoryFilter.creative =>
        category == 'creative' || category == 'design',
    };
  }
}

class SubscriptionFilterState {
  const SubscriptionFilterState({
    this.query = '',
    this.category = SubscriptionCategoryFilter.all,
  });

  final String query;
  final SubscriptionCategoryFilter category;

  SubscriptionFilterState copyWith({
    String? query,
    SubscriptionCategoryFilter? category,
  }) {
    return SubscriptionFilterState(
      query: query ?? this.query,
      category: category ?? this.category,
    );
  }
}

final subscriptionFilterProvider =
    NotifierProvider<SubscriptionFilterController, SubscriptionFilterState>(
      SubscriptionFilterController.new,
    );

final visibleSubscriptionsProvider = Provider<AsyncValue<List<Subscription>>>((
  ref,
) {
  final filter = ref.watch(subscriptionFilterProvider);
  final query = filter.query.trim().toLowerCase();

  return ref.watch(subscriptionListProvider).whenData((subscriptions) {
    return subscriptions
        .where((subscription) {
          final matchesQuery =
              query.isEmpty || subscription.name.toLowerCase().contains(query);
          return matchesQuery && filter.category.matches(subscription);
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
    state = state.copyWith(category: category);
  }

  void clear() => state = const SubscriptionFilterState();
}
