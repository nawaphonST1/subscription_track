import 'package:subscription_track/features/profile/domain/payment_card.dart';

abstract interface class PaymentCardRepository {
  Future<List<PaymentCard>> getLinkedCards();

  Future<List<PaymentCard>> getAvailableCards();

  Future<PaymentCard> linkCard(String id);
}
