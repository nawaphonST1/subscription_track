import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subscription_track/features/onboarding/application/onboarding_controller.dart';

void main() {
  test('updates onboarding completion state', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(onboardingProvider), isFalse);
    container.read(onboardingProvider.notifier).setCompleted(true);
    expect(container.read(onboardingProvider), isTrue);
  });
}
