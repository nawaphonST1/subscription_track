import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subscription_track/models/subscription.dart';
import 'package:subscription_track/providers/subscription_provider.dart';
import 'package:subscription_track/repositories/in_memory_subscription_repository.dart';
import 'package:subscription_track/repositories/subscription_repository.dart';

void main() {
  group('InMemorySubscriptionRepository', () {
    late InMemorySubscriptionRepository repository;

    setUp(() {
      repository = InMemorySubscriptionRepository(
        initialSubscriptions: const [],
        ioDelay: Duration.zero,
      );
    });

    test('performs add, read, update, toggle, and delete', () async {
      const subscription = Subscription(
        id: 'test-subscription',
        name: 'Test Plan',
        price: 199,
        category: 'testing',
      );

      await repository.addSubscription(subscription);
      expect(await repository.getSubscriptions(), [subscription]);
      expect(
        await repository.getSubscriptionById(subscription.id),
        subscription,
      );

      final updated = subscription.copyWith(price: 249);
      await repository.updateSubscription(updated);
      expect(
        (await repository.getSubscriptionById(subscription.id)).price,
        249,
      );

      await repository.toggleSelection(subscription.id);
      expect(
        (await repository.getSubscriptionById(subscription.id)).isSelected,
        isTrue,
      );

      await repository.deleteSubscription(subscription.id);
      expect(await repository.getSubscriptions(), isEmpty);
    });

    test('throws clear exceptions for invalid ids and duplicates', () async {
      const subscription = Subscription(
        id: 'duplicate',
        name: 'Duplicate',
        price: 99,
      );
      await repository.addSubscription(subscription);

      expect(
        () => repository.addSubscription(subscription),
        throwsA(isA<DuplicateSubscriptionException>()),
      );
      expect(
        () => repository.getSubscriptionById('missing'),
        throwsA(isA<SubscriptionNotFoundException>()),
      );
    });

    test('can override repository provider in a ProviderContainer', () async {
      final container = ProviderContainer(
        overrides: [
          subscriptionRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      expect(await container.read(subscriptionListProvider.future), isEmpty);
    });
  });
}
