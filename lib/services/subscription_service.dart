import 'package:fpdart/fpdart.dart';
import 'package:subscription_track/core/errors/failures.dart';
import 'package:subscription_track/core/utils/logger.dart';
import 'package:subscription_track/features/subscriptions/domain/subscription.dart';

class SubscriptionService {
  final List<Subscription> _subscriptions = [
    Subscription(
      id: '1',
      name: 'Netflix',
      price: 599,
      billingPeriod: 'monthly',
      category: 'streaming',
      nextBillingDate: DateTime.now().add(const Duration(days: 5)),
      usageStatus: 'frequent',
      confidence: 92,
    ),
    Subscription(
      id: '2',
      name: 'Spotify',
      price: 178,
      billingPeriod: 'monthly',
      category: 'streaming',
      nextBillingDate: DateTime.now().add(const Duration(days: 12)),
      usageStatus: 'moderate',
      confidence: 65,
    ),
    Subscription(
      id: '3',
      name: 'ChatGPT Plus',
      price: 750,
      billingPeriod: 'monthly',
      category: 'ai',
      nextBillingDate: DateTime.now().add(const Duration(days: 8)),
      usageStatus: 'frequent',
      confidence: 88,
    ),
    Subscription(
      id: '4',
      name: 'Google One',
      price: 99,
      billingPeriod: 'monthly',
      category: 'cloud',
      nextBillingDate: DateTime.now().add(const Duration(days: 3)),
      usageStatus: 'unused',
      confidence: 15,
    ),
    Subscription(
      id: '5',
      name: 'Adobe Creative Cloud',
      price: 599,
      billingPeriod: 'monthly',
      category: 'creative',
      nextBillingDate: DateTime.now().add(const Duration(days: 20)),
      usageStatus: 'moderate',
      confidence: 45,
    ),
  ];

  Future<Either<Failure, List<Subscription>>> getAll() async {
    logger.i('Getting all subscriptions');
    await Future.delayed(const Duration(milliseconds: 500));
    return right(List.unmodifiable(_subscriptions));
  }

  Future<Either<Failure, Subscription?>> getById(String id) async {
    logger.i('Getting subscription: $id');
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _subscriptions.indexWhere((s) => s.id == id);
    if (index == -1) return right(null);
    return right(_subscriptions[index]);
  }

  Future<Either<Failure, Subscription>> create(
    Subscription subscription,
  ) async {
    logger.i('Creating subscription: ${subscription.name}');
    await Future.delayed(const Duration(milliseconds: 300));
    _subscriptions.add(subscription);
    return right(subscription);
  }

  Future<Either<Failure, Subscription>> update(
    Subscription subscription,
  ) async {
    logger.i('Updating subscription: ${subscription.id}');
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _subscriptions.indexWhere((s) => s.id == subscription.id);
    if (index == -1) return left(const Failure.notFound());
    _subscriptions[index] = subscription;
    return right(subscription);
  }

  Future<Either<Failure, Unit>> delete(String id) async {
    logger.i('Deleting subscription: $id');
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _subscriptions.indexWhere((s) => s.id == id);
    if (index == -1) return left(const Failure.notFound());
    _subscriptions.removeAt(index);
    return right(unit);
  }
}
