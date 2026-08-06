import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subscription_track/features/subscriptions/application/subscription_list_controller.dart';
import 'package:subscription_track/features/subscriptions/domain/subscription.dart';

final savingsViewStateProvider = Provider<AsyncValue<SavingsViewState>>((ref) {
  return ref.watch(subscriptionListProvider).whenData(SavingsViewState.from);
});

final savingsActionsProvider = Provider<SavingsActions>(SavingsActions.new);

class SavingsActions {
  const SavingsActions(this._ref);

  final Ref _ref;

  Future<void> refresh() {
    return _ref.read(subscriptionListProvider.notifier).refresh();
  }

  Future<void> toggleSelection(String id) {
    return _ref.read(subscriptionListProvider.notifier).toggleSelection(id);
  }

  Future<void> deleteSelected() {
    return _ref.read(subscriptionListProvider.notifier).deleteSelected();
  }
}

class SavingsViewState {
  const SavingsViewState({
    required this.items,
    required this.selectedCount,
    required this.yearlySavings,
  });

  factory SavingsViewState.from(List<Subscription> subscriptions) {
    final items = subscriptions.map(SavingsItem.from).toList(growable: false);
    final selectedItems = items.where((item) => item.isSelected);
    return SavingsViewState(
      items: items,
      selectedCount: selectedItems.length,
      yearlySavings: selectedItems.fold<double>(
        0,
        (total, item) => total + item.monthlyPrice * 12,
      ),
    );
  }

  final List<SavingsItem> items;
  final int selectedCount;
  final double yearlySavings;

  bool get hasSelection => selectedCount > 0;
}

class SavingsItem {
  const SavingsItem({
    required this.id,
    required this.name,
    required this.category,
    required this.monthlyPrice,
    required this.isSelected,
  });

  factory SavingsItem.from(Subscription subscription) {
    return SavingsItem(
      id: subscription.id,
      name: subscription.name,
      category: subscription.category,
      monthlyPrice: subscription.monthlyPrice,
      isSelected: subscription.isSelected,
    );
  }

  final String id;
  final String name;
  final String category;
  final double monthlyPrice;
  final bool isSelected;
}
