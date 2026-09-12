import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subscription_track/features/auth/application/auth_provider.dart';
import 'package:subscription_track/features/onboarding/application/onboarding_controller.dart';

/// State ขั้นต่ำที่ router ใช้ตัดสินใจ startup destination
class AppFlowState {
  const AppFlowState({
    required this.isInitializing,
    required this.isOnboardingCompleted,
    required this.isAuthenticated,
  });

  static const mockDashboard = AppFlowState(
    isInitializing: false,
    isOnboardingCompleted: true,
    isAuthenticated: true,
  );

  final bool isInitializing;
  final bool isOnboardingCompleted;
  final bool isAuthenticated;
}

/// ใช้เฉพาะ demo/test ที่ต้องการข้าม auth; production default เป็น false
final mockAuthBypassProvider = NotifierProvider<MockAuthBypassController, bool>(
  MockAuthBypassController.new,
);

final class MockAuthBypassController extends Notifier<bool> {
  @override
  bool build() => false;

  void setEnabled(bool value) => state = value;
}

/// รวม state ข้าม feature ให้ router ตัดสินใจเส้นทางจากจุดเดียว
final appFlowProvider = Provider<AppFlowState>((ref) {
  final bypassAuth = ref.watch(mockAuthBypassProvider);
  final onboardingCompleted = ref.watch(onboardingProvider);
  final authState = ref.watch(authProvider);

  return AppFlowState(
    isInitializing: !bypassAuth && authState.isLoading,
    isOnboardingCompleted: onboardingCompleted,
    isAuthenticated: bypassAuth || authState.value != null,
  );
});
