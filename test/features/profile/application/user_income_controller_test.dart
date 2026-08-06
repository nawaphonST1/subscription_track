import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subscription_track/features/profile/application/user_income_controller.dart';

void main() {
  test('accepts only finite positive income', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(userIncomeProvider.notifier);

    expect(controller.update(42000), isTrue);
    expect(container.read(userIncomeProvider), 42000);
    expect(controller.update(0), isFalse);
    expect(controller.update(double.infinity), isFalse);
    expect(container.read(userIncomeProvider), 42000);
  });
}
