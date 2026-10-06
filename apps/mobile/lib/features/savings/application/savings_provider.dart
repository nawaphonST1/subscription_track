import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subscription_track/core/utils/logger.dart';
import 'package:subscription_track/features/savings/data/remote_savings_repository.dart';
import 'package:subscription_track/features/savings/domain/savings_optimizer_report.dart';
import 'package:subscription_track/features/subscriptions/application/subscription_list_controller.dart';
import 'package:subscription_track/features/subscriptions/application/subscription_read_model.dart';

final savingsNotifierProvider =
    AsyncNotifierProvider<SavingsNotifier, SavingsViewState>(
  SavingsNotifier.new,
);

final savingsViewStateProvider = Provider<AsyncValue<SavingsViewState>>((ref) {
  return ref.watch(savingsNotifierProvider);
});

final savingsActionsProvider = Provider<SavingsActions>((ref) {
  return SavingsActions(ref);
});

class SavingsActions {
  const SavingsActions(this._ref);

  final Ref _ref;

  Future<void> refresh() {
    return _ref.read(savingsNotifierProvider.notifier).refresh();
  }

  void toggleSelection(String id) {
    _ref.read(savingsNotifierProvider.notifier).toggleSelection(id);
  }

  Future<BatchCancelResult> batchCancel(List<String> ids, String pin) {
    return _ref.read(savingsNotifierProvider.notifier).batchCancel(ids, pin);
  }
}

class SavingsNotifier extends AsyncNotifier<SavingsViewState> {
  final Set<String> _selectedIds = <String>{};
  SavingsOptimizerReport? _cachedReport;

  @override
  Future<SavingsViewState> build() async {
    final repo = ref.watch(savingsRepositoryProvider);
    try {
      final report = await repo.getOptimizerReport();
      _cachedReport = report;
      return SavingsViewState.fromOptimizerReport(
        report,
        selectedIds: _selectedIds,
      );
    } catch (e) {
      logger.w(
        'SavingsRepository unavailable, falling back to local subscriptions: $e',
      );
      // Deliberate fallback: หาก API ไม่พร้อมหรืออยู่ในโหมดออฟไลน์
      // ให้คำนวณจาก subscriptionReadModelsProvider ในเครื่อง
      final subs =
          ref.watch(subscriptionReadModelsProvider).value ?? const [];
      final unusedSubs =
          subs.where((s) => s.usageStatus == 'unused').toList(growable: false);
      return SavingsViewState.fromSubscriptions(
        unusedSubs.isNotEmpty ? unusedSubs : subs,
        selectedIds: _selectedIds,
      );
    }
  }

  void toggleSelection(String id) {
    if (_selectedIds.contains(id)) {
      _selectedIds.remove(id);
    } else {
      _selectedIds.add(id);
    }

    final currentState = state.value;
    if (currentState == null) return;

    if (_cachedReport != null) {
      state = AsyncData(
        SavingsViewState.fromOptimizerReport(
          _cachedReport!,
          selectedIds: _selectedIds,
        ),
      );
    } else {
      state = AsyncData(
        currentState.copyWithToggled(id, _selectedIds.contains(id)),
      );
    }
  }

  Future<BatchCancelResult> batchCancel(List<String> ids, String pin) async {
    final repo = ref.read(savingsRepositoryProvider);
    final result = await repo.batchCancel(subscriptionIds: ids, pin: pin);

    _selectedIds.removeAll(ids);

    // Refresh both subscriptions and optimizer so cancelled items disappear
    ref.invalidate(subscriptionListProvider);
    ref.invalidateSelf();

    return result;
  }

  Future<void> refresh() async {
    _selectedIds.clear();
    ref.invalidateSelf();
    await future;
  }
}

class SavingsViewState {
  const SavingsViewState({
    required this.items,
    required this.selectedCount,
    required this.yearlySavings,
    this.totalMonthlySavings,
    this.totalYearlySavingsProjection,
  });

  factory SavingsViewState.fromOptimizerReport(
    SavingsOptimizerReport report, {
    Set<String> selectedIds = const {},
  }) {
    final items = report.recommendedCancellations.map((item) {
      return SavingsItem.fromOptimizerItem(
        item,
        isSelected: selectedIds.contains(item.id),
      );
    }).toList(growable: false);

    final selectedItems = items.where((i) => i.isSelected);
    return SavingsViewState(
      items: items,
      selectedCount: selectedItems.length,
      yearlySavings: selectedItems.fold<double>(
        0,
        (sum, item) =>
            sum +
            (item.yearlySavingsProjection ?? (item.monthlyPrice * 12)),
      ),
      totalMonthlySavings: report.totalMonthlySavings,
      totalYearlySavingsProjection: report.totalYearlySavingsProjection,
    );
  }

  factory SavingsViewState.fromSubscriptions(
    List<SubscriptionReadModel> subscriptions, {
    Set<String> selectedIds = const {},
  }) {
    final items = subscriptions.map((s) {
      final isSelected = selectedIds.isNotEmpty
          ? selectedIds.contains(s.id)
          : s.isSelected;
      return SavingsItem.from(s).copyWith(isSelected: isSelected);
    }).toList(growable: false);

    final selectedItems = items.where((i) => i.isSelected);
    return SavingsViewState(
      items: items,
      selectedCount: selectedItems.length,
      yearlySavings: selectedItems.fold<double>(
        0,
        (sum, item) => sum + item.monthlyPrice * 12,
      ),
    );
  }

  /// Backward-compatible factory for existing unit tests
  factory SavingsViewState.from(List<SubscriptionReadModel> subscriptions) {
    return SavingsViewState.fromSubscriptions(subscriptions);
  }

  final List<SavingsItem> items;
  final int selectedCount;
  final double yearlySavings;
  final double? totalMonthlySavings;
  final double? totalYearlySavingsProjection;

  bool get hasSelection => selectedCount > 0;

  SavingsViewState copyWithToggled(String id, bool isSelected) {
    final updated = items.map((i) {
      if (i.id == id) return i.copyWith(isSelected: isSelected);
      return i;
    }).toList(growable: false);

    final selectedItems = updated.where((i) => i.isSelected);
    return SavingsViewState(
      items: updated,
      selectedCount: selectedItems.length,
      yearlySavings: selectedItems.fold<double>(
        0,
        (sum, item) =>
            sum +
            (item.yearlySavingsProjection ?? (item.monthlyPrice * 12)),
      ),
      totalMonthlySavings: totalMonthlySavings,
      totalYearlySavingsProjection: totalYearlySavingsProjection,
    );
  }
}

class SavingsItem {
  const SavingsItem({
    required this.id,
    required this.name,
    required this.category,
    required this.monthlyPrice,
    required this.isSelected,
    this.yearlySavingsProjection,
    this.brandColor,
    this.paymentCard,
  });

  factory SavingsItem.fromOptimizerItem(
    SavingsOptimizerItem item, {
    bool isSelected = false,
  }) {
    return SavingsItem(
      id: item.id,
      name: item.name,
      category: item.category,
      monthlyPrice: item.normalizedMonthlyCost > 0
          ? item.normalizedMonthlyCost
          : item.price,
      isSelected: isSelected,
      yearlySavingsProjection: item.yearlySavingsProjection,
      brandColor: item.brandColor,
      paymentCard: item.paymentCard,
    );
  }

  factory SavingsItem.from(SubscriptionReadModel subscription) {
    return SavingsItem(
      id: subscription.id,
      name: subscription.name,
      category: subscription.category,
      monthlyPrice: subscription.monthlyPrice,
      isSelected: subscription.isSelected,
      yearlySavingsProjection: subscription.monthlyPrice * 12,
    );
  }

  final String id;
  final String name;
  final String category;
  final double monthlyPrice;
  final bool isSelected;
  final double? yearlySavingsProjection;
  final String? brandColor;
  final SavingsPaymentCard? paymentCard;

  SavingsItem copyWith({
    bool? isSelected,
    double? monthlyPrice,
    double? yearlySavingsProjection,
    String? brandColor,
    SavingsPaymentCard? paymentCard,
  }) {
    return SavingsItem(
      id: id,
      name: name,
      category: category,
      monthlyPrice: monthlyPrice ?? this.monthlyPrice,
      isSelected: isSelected ?? this.isSelected,
      yearlySavingsProjection:
          yearlySavingsProjection ?? this.yearlySavingsProjection,
      brandColor: brandColor ?? this.brandColor,
      paymentCard: paymentCard ?? this.paymentCard,
    );
  }
}
