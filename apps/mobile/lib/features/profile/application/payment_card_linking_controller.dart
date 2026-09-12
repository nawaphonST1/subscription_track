import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subscription_track/features/profile/data/in_memory_payment_card_repository.dart';
import 'package:subscription_track/features/profile/domain/payment_card.dart';
import 'package:subscription_track/features/profile/domain/payment_card_repository.dart';
import 'package:subscription_track/features/subscriptions/application/subscription_list_controller.dart';
import 'package:subscription_track/features/subscriptions/domain/subscription.dart';

final paymentCardRepositoryProvider = Provider<PaymentCardRepository>(
  (ref) => InMemoryPaymentCardRepository(),
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

  Future<PaymentCardLinkResult> linkCard(String id) async {
    final previous = await future;
    final card = await _repository.linkCard(id);

    try {
      final importedCount = await ref
          .read(subscriptionListProvider.notifier)
          .importSubscriptions(card.detectedSubscriptions.map(_toSubscription));
      state = AsyncData([...previous, card]);
      return PaymentCardLinkResult(
        card: card,
        importedSubscriptionCount: importedCount,
      );
    } catch (error, stackTrace) {
      state = await AsyncValue.guard(_repository.getLinkedCards);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Subscription _toSubscription(DetectedSubscription detected) {
    return Subscription(
      id: detected.id,
      name: detected.name,
      price: detected.price,
      category: detected.category,
      usageStatus: detected.usageStatus,
      confidence: detected.confidence,
      nextBillingDate: DateTime.now().add(
        Duration(days: detected.daysUntilNextBilling),
      ),
      createdAt: DateTime.now(),
    );
  }
}
