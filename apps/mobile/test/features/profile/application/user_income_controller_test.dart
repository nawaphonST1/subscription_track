import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subscription_track/features/auth/application/auth_provider.dart';
import 'package:subscription_track/features/auth/domain/credit_card.dart';
import 'package:subscription_track/features/auth/domain/user.dart';
import 'package:subscription_track/features/profile/application/payment_card_linking_controller.dart';
import 'package:subscription_track/features/profile/application/user_income_controller.dart';
import 'package:subscription_track/features/profile/domain/payment_card.dart';

import 'package:subscription_track/features/profile/domain/payment_card_repository.dart';

class _MockAuthNotifier extends AuthNotifier {
  _MockAuthNotifier(this._initialUser);
  final User? _initialUser;

  @override
  AsyncValue<User?> build() {
    return AsyncValue.data(_initialUser);
  }
}

class _MockPaymentCardRepository implements PaymentCardRepository {
  const _MockPaymentCardRepository(this._cards);
  final List<PaymentCard> _cards;

  @override
  Future<List<PaymentCard>> getLinkedCards() async => _cards;

  @override
  Future<List<PaymentCard>> getAvailableCards() async => const [];

  @override
  Future<PaymentCard> linkCard(String id) async => _cards.first;

  @override
  Future<void> deleteCard(String id, {String? pin}) async {}
}

void main() {
  group('UserIncomeController initialization', () {
    test('loads real monthly_income from user profile when available', () {
      const user = User(
        id: 'u1',
        email: 'test@example.com',
        income: 52000,
      );
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(() => _MockAuthNotifier(user)),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(userIncomeProvider), 52000);
    });

    test('falls back to credit card total balance when user.income is 0', () {
      const user = User(
        id: 'u2',
        email: 'test@example.com',
        income: 0,
        creditCards: [
          CreditCard(
            id: 'c1',
            bankName: 'SCB',
            last4Digits: '1234',
            creditLimit: 50000,
            currentBalance: 25000,
            cardColor: '#1A1F71',
          ),
          CreditCard(
            id: 'c2',
            bankName: 'KBank',
            last4Digits: '5678',
            creditLimit: 50000,
            currentBalance: 15000,
            cardColor: '#1A1F71',
          ),
        ],
      );
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(() => _MockAuthNotifier(user)),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(effectiveIncomeProvider), 40000);
    });

    test('falls back to linkedPaymentCards total balance when user.income is 0', () async {
      const user = User(
        id: 'u3',
        email: 'test@example.com',
        income: 0,
      );
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(() => _MockAuthNotifier(user)),
          paymentCardRepositoryProvider.overrideWithValue(
            const _MockPaymentCardRepository([
              PaymentCard(
                id: 'pc1',
                bankName: 'KBank',
                last4Digits: '9999',
                creditLimit: 0,
                currentBalance: 15000,
                colorHex: '#1A1F71',
                detectedSubscriptions: [],
              ),
              PaymentCard(
                id: 'pc2',
                bankName: 'SCB',
                last4Digits: '8888',
                creditLimit: 0,
                currentBalance: 45000,
                colorHex: '#1A1F71',
                detectedSubscriptions: [],
              ),
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(linkedPaymentCardsProvider.future);
      expect(container.read(effectiveIncomeProvider), 60000);
    });

    test('falls back to 0.0 when no user or cards are present', () {
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(() => _MockAuthNotifier(null)),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(userIncomeProvider), 0.0);
    });
  });

  group('UserIncomeController update', () {
    test('accepts only finite positive income', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final controller = container.read(userIncomeProvider.notifier);

      expect(controller.update(42000), isTrue);
      expect(container.read(userIncomeProvider), 42000);
      expect(controller.update(0), isFalse);
      expect(controller.update(-500), isFalse);
      expect(controller.update(double.infinity), isFalse);
      expect(container.read(userIncomeProvider), 42000);
    });
  });
}

