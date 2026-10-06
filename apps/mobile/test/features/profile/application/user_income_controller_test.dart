import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subscription_track/features/auth/application/auth_provider.dart';
import 'package:subscription_track/features/auth/domain/credit_card.dart';
import 'package:subscription_track/features/auth/domain/user.dart';
import 'package:subscription_track/features/profile/application/user_income_controller.dart';

class _MockAuthNotifier extends AuthNotifier {
  _MockAuthNotifier(this._initialUser);
  final User? _initialUser;

  @override
  AsyncValue<User?> build() {
    return AsyncValue.data(_initialUser);
  }
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

      expect(container.read(userIncomeProvider), 40000);
    });

    test('falls back to 35,000 when no user or cards are present', () {
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(() => _MockAuthNotifier(null)),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(userIncomeProvider), 35000);
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

