import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subscription_track/features/dashboard/application/dashboard_summary_provider.dart';
import 'package:subscription_track/features/profile/data/remote_payment_card_repository.dart';
import 'package:subscription_track/features/profile/domain/payment_card.dart';
import 'package:subscription_track/features/profile/domain/payment_card_repository.dart';
import 'package:subscription_track/features/savings/application/savings_provider.dart';
import 'package:subscription_track/features/subscriptions/application/subscription_list_controller.dart';

final paymentCardRepositoryProvider = Provider<PaymentCardRepository>(
  (ref) => RemotePaymentCardRepository(),
);

final linkedPaymentCardsProvider =
    AsyncNotifierProvider<PaymentCardLinkingController, List<PaymentCard>>(
      PaymentCardLinkingController.new,
    );

final availablePaymentCardsProvider = FutureProvider<List<PaymentCard>>((ref) {
  ref.watch(linkedPaymentCardsProvider);
  return ref.watch(paymentCardRepositoryProvider).getAvailableCards();
});

final class PaymentCardLinkResult {
  const PaymentCardLinkResult({
    required this.card,
    required this.importedSubscriptionCount,
  });

  final PaymentCard card;
  final int importedSubscriptionCount;
}

final class PaymentCardLinkingController
    extends AsyncNotifier<List<PaymentCard>> {
  PaymentCardRepository get _repository =>
      ref.read(paymentCardRepositoryProvider);

  @override
  Future<List<PaymentCard>> build() {
    return ref.watch(paymentCardRepositoryProvider).getLinkedCards();
  }

  /// Backend's `POST /cards/link` already auto-creates the real
  /// `UserSubscription` rows server-side (see payment-cards.service.ts's
  /// `linkMockCard`), so this no longer imports `card.detectedSubscriptions`
  /// itself — doing so would double-create them. Instead it refreshes
  /// [subscriptionListProvider] from the backend and reports how many new
  /// rows actually showed up.
  Future<PaymentCardLinkResult> linkCard(String id) async {
    final previous = await future;
    final subscriptionsBefore =
        (await ref.read(subscriptionListProvider.future)).length;
    final card = await _repository.linkCard(id);

    try {
      await ref.read(subscriptionListProvider.notifier).refresh();
      ref.invalidate(savingsNotifierProvider);
      ref.invalidate(creepScoreFutureProvider);
      final subscriptionsAfter =
          (await ref.read(subscriptionListProvider.future)).length;
      state = AsyncData([...previous.where((c) => c.id != card.id), card]);
      return PaymentCardLinkResult(
        card: card,
        importedSubscriptionCount:
            (subscriptionsAfter - subscriptionsBefore).clamp(0, 1 << 30),
      );
    } catch (error, stackTrace) {
      state = await AsyncValue.guard(_repository.getLinkedCards);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> deleteCard(String id, {String? pin}) async {
    final previous = await future;
    final updated =
        previous.where((item) => item.id != id).toList(growable: false);
    state = AsyncData<List<PaymentCard>>(updated);

    try {
      await _repository.deleteCard(id, pin: pin);
      state = AsyncData<List<PaymentCard>>(updated);

      try {
        await ref.read(subscriptionListProvider.notifier).refresh();
      } catch (_) {
        // Non-critical if offline or in widget test
      }
      ref.invalidate(savingsNotifierProvider);
      ref.invalidate(creepScoreFutureProvider);
      ref.invalidate(availablePaymentCardsProvider);
    } catch (error, stackTrace) {
      state = AsyncData<List<PaymentCard>>(previous);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }
}
