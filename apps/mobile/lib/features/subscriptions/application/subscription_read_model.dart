import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subscription_track/features/subscriptions/application/subscription_list_controller.dart';
import 'package:subscription_track/features/subscriptions/domain/subscription.dart';

final subscriptionReadModelsProvider =
    Provider<AsyncValue<List<SubscriptionReadModel>>>((ref) {
      return ref
          .watch(subscriptionListProvider)
          .whenData(
            (items) => items
                .map(SubscriptionReadModel.fromSubscription)
                .toList(growable: false),
          );
    });

final subscriptionCommandsProvider = Provider<SubscriptionCommands>(
  SubscriptionCommands.new,
);

class SubscriptionCommands {
  const SubscriptionCommands(this._ref);

  final Ref _ref;

  Future<void> refresh() =>
      _ref.read(subscriptionListProvider.notifier).refresh();

  Future<void> toggleSelection(String id) =>
      _ref.read(subscriptionListProvider.notifier).toggleSelection(id);

  Future<void> deleteSelected() =>
      _ref.read(subscriptionListProvider.notifier).deleteSelected();
}

class SubscriptionReadModel {
  const SubscriptionReadModel({
    required this.id,
    required this.name,
    required this.category,
    required this.monthlyPrice,
    required this.usageStatus,
    required this.isSelected,
    required this.nextBillingDate,
  });

  factory SubscriptionReadModel.fromSubscription(Subscription subscription) {
    return SubscriptionReadModel(
      id: subscription.id,
      name: subscription.name,
      category: subscription.category,
      monthlyPrice: subscription.monthlyPrice,
      usageStatus: subscription.usageStatus,
      isSelected: subscription.isSelected,
      nextBillingDate: subscription.nextBillingDate,
    );
  }

  final String id;
  final String name;
  final String category;
  final double monthlyPrice;
  final String usageStatus;
  final bool isSelected;
  final DateTime? nextBillingDate;
}
