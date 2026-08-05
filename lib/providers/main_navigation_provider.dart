import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subscription_track/models/subscription.dart';
import 'package:subscription_track/providers/subscription_provider.dart';

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

final currentTabProvider = NotifierProvider<CurrentTabController, int>(
  CurrentTabController.new,
);

final userIncomeProvider = NotifierProvider<UserIncomeController, double>(
  UserIncomeController.new,
);

final searchQueryProvider = NotifierProvider<SearchQueryController, String>(
  SearchQueryController.new,
);

final selectedCategoryProvider =
    NotifierProvider<SelectedCategoryController, SubscriptionCategoryFilter>(
      SelectedCategoryController.new,
    );

final notificationReminderProvider =
    NotifierProvider<NotificationReminderController, bool>(
      NotificationReminderController.new,
    );

/// รวม search และ category ไว้ใน derived provider เพื่อให้ View ไม่มี business logic
final visibleSubscriptionsProvider = Provider<AsyncValue<List<Subscription>>>((
  ref,
) {
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();
  final category = ref.watch(selectedCategoryProvider);

  return ref.watch(subscriptionListProvider).whenData((subscriptions) {
    return subscriptions
        .where((subscription) {
          final matchesQuery =
              query.isEmpty || subscription.name.toLowerCase().contains(query);
          return matchesQuery && category.matches(subscription);
        })
        .toList(growable: false);
  });
});

final class CurrentTabController extends Notifier<int> {
  @override
  int build() => 0;

  void select(int index) {
    if (index >= 0 && index < 5) state = index;
  }
}

final class UserIncomeController extends Notifier<double> {
  @override
  double build() => 35000;

  bool update(double income) {
    if (!income.isFinite || income <= 0) return false;
    state = income;
    return true;
  }
}

final class SearchQueryController extends Notifier<String> {
  @override
  String build() => '';

  void update(String query) => state = query;

  void clear() => state = '';
}

final class SelectedCategoryController
    extends Notifier<SubscriptionCategoryFilter> {
  @override
  SubscriptionCategoryFilter build() => SubscriptionCategoryFilter.all;

  void select(SubscriptionCategoryFilter category) => state = category;
}

final class NotificationReminderController extends Notifier<bool> {
  @override
  bool build() => true;

  void update({required bool enabled}) => state = enabled;
}
