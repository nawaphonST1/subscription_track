import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subscription_track/app/application/app_flow_provider.dart';
import 'package:subscription_track/features/auth/application/auth_provider.dart';
import 'package:subscription_track/features/auth/domain/user.dart';

class _MockAuthNotifier extends AuthNotifier {
  _MockAuthNotifier(this._initialUser);
  final User? _initialUser;

  @override
  AsyncValue<User?> build() {
    return AsyncValue.data(_initialUser);
  }
}

void main() {
  group('AppFlowState constructor defaults', () {
    test('isPinSetupCompleted defaults to false (fail-closed)', () {
      const state = AppFlowState(
        isInitializing: false,
        isOnboardingCompleted: true,
        isAuthenticated: true,
      );

      expect(state.isPinSetupCompleted, isFalse);
    });

    test('mockDashboard explicitly sets isPinSetupCompleted to true', () {
      expect(AppFlowState.mockDashboard.isPinSetupCompleted, isTrue);
    });
  });

  group('appFlowProvider PIN setup state derivation', () {
    test('derives isPinSetupCompleted as false when user is null (fail-closed)', () {
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(() => _MockAuthNotifier(null)),
        ],
      );
      addTearDown(container.dispose);

      final state = container.read(appFlowProvider);
      expect(state.isPinSetupCompleted, isFalse);
    });

    test('derives isPinSetupCompleted from user.pinConfigured when user is present', () {
      const userWithoutPin = User(
        id: 'u1',
        email: 'u1@test.com',
        pinConfigured: false,
      );

      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(() => _MockAuthNotifier(userWithoutPin)),
        ],
      );
      addTearDown(container.dispose);

      final state = container.read(appFlowProvider);
      expect(state.isPinSetupCompleted, isFalse);
    });

    test('derives isPinSetupCompleted as true when user.pinConfigured is true', () {
      const userWithPin = User(
        id: 'u2',
        email: 'u2@test.com',
        pinConfigured: true,
      );

      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(() => _MockAuthNotifier(userWithPin)),
        ],
      );
      addTearDown(container.dispose);

      final state = container.read(appFlowProvider);
      expect(state.isPinSetupCompleted, isTrue);
    });
  });
}
