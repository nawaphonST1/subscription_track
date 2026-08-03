import 'package:subscription_track/models/subscription.dart';
import 'package:subscription_track/repositories/subscription_repository.dart';

/// Repository สำหรับพัฒนา UI และทดสอบโดยไม่ต้องรอฐานข้อมูลหรือ API
final class InMemorySubscriptionRepository implements SubscriptionRepository {
  InMemorySubscriptionRepository({
    List<Subscription>? initialSubscriptions,
    this.ioDelay = const Duration(milliseconds: 300),
  }) : _subscriptions = List<Subscription>.of(
         initialSubscriptions ?? _createSeedSubscriptions(),
       );

  final Duration ioDelay;
  final List<Subscription> _subscriptions;

  @override
  Future<List<Subscription>> getSubscriptions() async {
    await _simulateIo();
    return List<Subscription>.unmodifiable(_subscriptions);
  }

  @override
  Future<Subscription> getSubscriptionById(String id) async {
    await _simulateIo();
    return _findById(id);
  }

  @override
  Future<void> addSubscription(Subscription subscription) async {
    await _simulateIo();
    if (_subscriptions.any((item) => item.id == subscription.id)) {
      throw DuplicateSubscriptionException(subscription.id);
    }
    _subscriptions.add(subscription);
  }

  @override
  Future<void> updateSubscription(Subscription subscription) async {
    await _simulateIo();
    final index = _indexOf(subscription.id);
    _subscriptions[index] = subscription;
  }

  @override
  Future<void> deleteSubscription(String id) async {
    await _simulateIo();
    final index = _indexOf(id);
    _subscriptions.removeAt(index);
  }

  @override
  Future<void> toggleSelection(String id) async {
    await _simulateIo();
    final index = _indexOf(id);
    final current = _subscriptions[index];
    _subscriptions[index] = current.copyWith(isSelected: !current.isSelected);
  }

  Future<void> _simulateIo() => Future<void>.delayed(ioDelay);

  int _indexOf(String id) {
    final index = _subscriptions.indexWhere((item) => item.id == id);
    if (index == -1) throw SubscriptionNotFoundException(id);
    return index;
  }

  Subscription _findById(String id) => _subscriptions[_indexOf(id)];

  static List<Subscription> _createSeedSubscriptions() {
    final now = DateTime.now();
    return [
      Subscription(
        id: 'netflix-premium',
        name: 'Netflix Premium',
        price: 419,
        category: 'streaming',
        nextBillingDate: now.add(const Duration(days: 5)),
        usageStatus: 'frequent',
        confidence: 94,
      ),
      Subscription(
        id: 'spotify-premium',
        name: 'Spotify Premium',
        price: 139,
        category: 'music',
        nextBillingDate: now.add(const Duration(days: 12)),
        usageStatus: 'frequent',
        confidence: 89,
      ),
      Subscription(
        id: 'google-one',
        name: 'Google One Cloud',
        price: 99,
        category: 'cloud',
        nextBillingDate: now.add(const Duration(days: 3)),
        usageStatus: 'moderate',
        confidence: 72,
      ),
      Subscription(
        id: 'chatgpt-plus',
        name: 'ChatGPT Plus',
        price: 750,
        category: 'ai',
        nextBillingDate: now.add(const Duration(days: 8)),
        usageStatus: 'frequent',
        confidence: 91,
      ),
      Subscription(
        id: 'adobe-creative-cloud',
        name: 'Adobe Creative Cloud',
        price: 800,
        category: 'creative',
        nextBillingDate: now.add(const Duration(days: 20)),
        usageStatus: 'unused',
        confidence: 28,
      ),
    ];
  }
}
