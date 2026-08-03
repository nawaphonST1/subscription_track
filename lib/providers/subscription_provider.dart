import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subscription_track/models/subscription.dart';
import 'package:subscription_track/repositories/in_memory_subscription_repository.dart';
import 'package:subscription_track/repositories/subscription_repository.dart';

/// จุดสลับ data source ของทั้ง feature และ override เป็น fake/mock ได้ใน test
final subscriptionRepositoryProvider = Provider<SubscriptionRepository>(
  (ref) => InMemorySubscriptionRepository(),
);

final subscriptionListProvider =
    AsyncNotifierProvider<SubscriptionListController, List<Subscription>>(
      SubscriptionListController.new,
    );

final subscriptionByIdProvider = FutureProvider.family<Subscription, String>(
  (ref, id) =>
      ref.watch(subscriptionRepositoryProvider).getSubscriptionById(id),
);

/// Controller ของหน้า subscription: UI อ่าน state และเรียก command ผ่าน notifier
final class SubscriptionListController
    extends AsyncNotifier<List<Subscription>> {
  SubscriptionRepository get _repository =>
      ref.read(subscriptionRepositoryProvider);

  @override
  Future<List<Subscription>> build() {
    return ref.watch(subscriptionRepositoryProvider).getSubscriptions();
  }

  Future<void> refresh() async {
    state = const AsyncLoading<List<Subscription>>();
    state = await AsyncValue.guard(_repository.getSubscriptions);
  }

  Future<void> addSubscription(Subscription subscription) async {
    final previous = await future;
    try {
      await _repository.addSubscription(subscription);
      state = AsyncData<List<Subscription>>([...previous, subscription]);
    } catch (error, stackTrace) {
      state = AsyncData<List<Subscription>>(previous);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> updateSubscription(Subscription subscription) async {
    final previous = await future;
    try {
      await _repository.updateSubscription(subscription);
      state = AsyncData<List<Subscription>>([
        for (final item in previous)
          if (item.id == subscription.id) subscription else item,
      ]);
    } catch (error, stackTrace) {
      state = AsyncData<List<Subscription>>(previous);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  /// ลบจาก UI ก่อนเพื่อให้ตอบสนองทันที และ rollback หาก data source ล้มเหลว
  Future<void> deleteSubscription(String id) async {
    final previous = await future;
    state = AsyncData<List<Subscription>>(
      previous.where((item) => item.id != id).toList(growable: false),
    );

    try {
      await _repository.deleteSubscription(id);
    } catch (error, stackTrace) {
      state = AsyncData<List<Subscription>>(previous);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> deleteSelected() async {
    final previous = await future;
    final selectedIds = previous
        .where((item) => item.isSelected)
        .map((item) => item.id)
        .toList(growable: false);
    if (selectedIds.isEmpty) return;

    state = AsyncData<List<Subscription>>(
      previous.where((item) => !item.isSelected).toList(growable: false),
    );

    try {
      for (final id in selectedIds) {
        await _repository.deleteSubscription(id);
      }
    } catch (error, stackTrace) {
      // บาง data source อาจลบบางรายการไปแล้ว จึง reload จาก source ให้ตรงจริง
      state = await AsyncValue.guard(_repository.getSubscriptions);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  /// toggle แบบ optimistic เพื่อให้ checkbox/simulation ไม่หน่วง 300 ms
  Future<void> toggleSelection(String id) async {
    final previous = await future;
    state = AsyncData<List<Subscription>>([
      for (final item in previous)
        if (item.id == id)
          item.copyWith(isSelected: !item.isSelected)
        else
          item,
    ]);

    try {
      await _repository.toggleSelection(id);
    } catch (error, stackTrace) {
      state = AsyncData<List<Subscription>>(previous);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }
}
