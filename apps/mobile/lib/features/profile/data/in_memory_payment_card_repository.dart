import 'package:subscription_track/features/profile/domain/payment_card.dart';
import 'package:subscription_track/features/profile/domain/payment_card_repository.dart';

final class InMemoryPaymentCardRepository implements PaymentCardRepository {
  InMemoryPaymentCardRepository({
    this.ioDelay = const Duration(milliseconds: 250),
  });

  final Duration ioDelay;
  final Set<String> _linkedCardIds = {'kbank-4242', 'scb-8888'};

  @override
  Future<List<PaymentCard>> getLinkedCards() async {
    await _simulateIo();
    return List.unmodifiable(
      _mockCards.where((card) => _linkedCardIds.contains(card.id)),
    );
  }

  @override
  Future<List<PaymentCard>> getAvailableCards() async {
    await _simulateIo();
    return List.unmodifiable(
      _mockCards.where((card) => !_linkedCardIds.contains(card.id)),
    );
  }

  @override
  Future<PaymentCard> linkCard(String id) async {
    await _simulateIo();
    final card = _mockCards.where((item) => item.id == id).firstOrNull;
    if (card == null) throw PaymentCardNotFoundException(id);
    if (!_linkedCardIds.add(id)) throw PaymentCardAlreadyLinkedException(id);
    return card;
  }

  Future<void> _simulateIo() => Future<void>.delayed(ioDelay);
}

final class PaymentCardNotFoundException implements Exception {
  const PaymentCardNotFoundException(this.id);

  final String id;
}

final class PaymentCardAlreadyLinkedException implements Exception {
  const PaymentCardAlreadyLinkedException(this.id);

  final String id;
}

const _mockCards = <PaymentCard>[
  PaymentCard(
    id: 'kbank-4242',
    bankName: 'KBank Platinum',
    last4Digits: '4242',
    creditLimit: 50000,
    currentBalance: 12500,
    colorHex: '#00A859',
    detectedSubscriptions: [
      DetectedSubscription(
        id: 'netflix-premium',
        name: 'Netflix Premium',
        price: 419,
        category: 'streaming',
        usageStatus: 'frequent',
        confidence: 94,
        daysUntilNextBilling: 5,
      ),
      DetectedSubscription(
        id: 'spotify-premium',
        name: 'Spotify Premium',
        price: 139,
        category: 'music',
        usageStatus: 'frequent',
        confidence: 89,
        daysUntilNextBilling: 12,
      ),
    ],
  ),
  PaymentCard(
    id: 'scb-8888',
    bankName: 'SCB First',
    last4Digits: '8888',
    creditLimit: 100000,
    currentBalance: 8500,
    colorHex: '#4E2A84',
    detectedSubscriptions: [
      DetectedSubscription(
        id: 'google-one',
        name: 'Google One Cloud',
        price: 99,
        category: 'cloud',
        usageStatus: 'moderate',
        confidence: 72,
        daysUntilNextBilling: 3,
      ),
      DetectedSubscription(
        id: 'chatgpt-plus',
        name: 'ChatGPT Plus',
        price: 750,
        category: 'ai',
        usageStatus: 'frequent',
        confidence: 91,
        daysUntilNextBilling: 8,
      ),
      DetectedSubscription(
        id: 'adobe-creative-cloud',
        name: 'Adobe Creative Cloud',
        price: 800,
        category: 'creative',
        usageStatus: 'unused',
        confidence: 28,
        daysUntilNextBilling: 20,
      ),
    ],
  ),
  PaymentCard(
    id: 'uob-1234',
    bankName: 'UOB Preferred',
    last4Digits: '1234',
    creditLimit: 80000,
    currentBalance: 6200,
    colorHex: '#005EB8',
    detectedSubscriptions: [
      DetectedSubscription(
        id: 'disney-plus-uob',
        name: 'Disney+ Hotstar',
        price: 289,
        category: 'streaming',
        usageStatus: 'moderate',
        confidence: 88,
        daysUntilNextBilling: 9,
      ),
      DetectedSubscription(
        id: 'icloud-uob',
        name: 'iCloud+ 200GB',
        price: 99,
        category: 'cloud',
        usageStatus: 'frequent',
        confidence: 96,
        daysUntilNextBilling: 16,
      ),
    ],
  ),
  PaymentCard(
    id: 'krungsri-5454',
    bankName: 'Krungsri Signature',
    last4Digits: '5454',
    creditLimit: 120000,
    currentBalance: 4100,
    colorHex: '#F5B800',
    detectedSubscriptions: [
      DetectedSubscription(
        id: 'youtube-krungsri',
        name: 'YouTube Premium',
        price: 179,
        category: 'streaming',
        usageStatus: 'frequent',
        confidence: 93,
        daysUntilNextBilling: 7,
      ),
      DetectedSubscription(
        id: 'canva-krungsri',
        name: 'Canva Pro',
        price: 229,
        category: 'creative',
        usageStatus: 'moderate',
        confidence: 84,
        daysUntilNextBilling: 18,
      ),
    ],
  ),
];
