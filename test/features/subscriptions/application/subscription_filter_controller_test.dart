import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subscription_track/features/subscriptions/application/subscription_filter_controller.dart';
import 'package:subscription_track/features/subscriptions/application/subscription_list_controller.dart';
import 'package:subscription_track/features/subscriptions/data/in_memory_subscription_repository.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(
      overrides: [
        subscriptionRepositoryProvider.overrideWithValue(
          InMemorySubscriptionRepository(ioDelay: Duration.zero),
        ),
      ],
    );
  });

  tearDown(() => container.dispose());

  test('combines search query and category in one filter state', () async {
    await container.read(subscriptionListProvider.future);

    final controller = container.read(subscriptionFilterProvider.notifier);
    controller.updateQuery('Google');
    controller.selectCategory(SubscriptionCategoryFilter.cloud);

    final state = container.read(subscriptionFilterProvider);
    final visible = container.read(visibleSubscriptionsProvider).requireValue;

    expect(state.query, 'Google');
    expect(state.category, SubscriptionCategoryFilter.cloud);
    expect(visible.map((item) => item.name), ['Google One Cloud']);
  });

  test('clear resets both search and category', () async {
    final allSubscriptions = await container.read(subscriptionListProvider.future);

    final controller = container.read(subscriptionFilterProvider.notifier);
    controller.updateQuery('ChatGPT');
    controller.selectCategory(SubscriptionCategoryFilter.ai);
    controller.clear();

    final state = container.read(subscriptionFilterProvider);
    final visible = container.read(visibleSubscriptionsProvider).requireValue;

    expect(state.query, isEmpty);
    expect(state.category, SubscriptionCategoryFilter.all);
    expect(visible, hasLength(allSubscriptions.length));
  });

  test('subscription list remains the single selection source', () async {
    final initial = await container.read(subscriptionListProvider.future);
    final target = initial.first;

    await container
        .read(subscriptionListProvider.notifier)
        .toggleSelection(target.id);

    final updated = container.read(subscriptionListProvider).requireValue;
    expect(
      updated.singleWhere((item) => item.id == target.id).isSelected,
      isNot(target.isSelected),
    );
  });
}
