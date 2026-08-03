import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subscription_track/providers/auth_provider.dart';

/// สถานะขั้นต่ำที่ Router ใช้ตัดสินใจเลือกหน้าเริ่มต้นของแอป
class AppFlowState {
  const AppFlowState({
    required this.isInitializing,
    required this.isOnboardingCompleted,
    required this.isAuthenticated,
  });

  /// ใช้ใน widget tests หรือ demo ที่ต้องเปิด Dashboard โดยตรง
  static const mockDashboard = AppFlowState(
    isInitializing: false,
    isOnboardingCompleted: true,
    isAuthenticated: true,
  );

  final bool isInitializing;
  final bool isOnboardingCompleted;
  final bool isAuthenticated;
}

/// Mock switch ชั่วคราวระหว่างรอระบบ auth จริงพร้อมใช้งาน
///
/// ค่าเริ่มต้นเป็น true ตาม requirement จึงข้าม Login ไป Dashboard ได้ทันที
/// เมื่อต้องการทดสอบ Login จริง ให้เรียก setEnabled(false)
class MockAuthBypassController extends Notifier<bool> {
  @override
  bool build() => false;

  void setEnabled(bool value) => state = value;
}

final mockAuthBypassProvider = NotifierProvider<MockAuthBypassController, bool>(
  MockAuthBypassController.new,
);

/// Mock onboarding persistence สำหรับช่วงที่ local storage ยังไม่เชื่อมต่อ
class OnboardingController extends Notifier<bool> {
  @override
  bool build() => false;

  void setCompleted(bool value) => state = value;
}

final onboardingProvider = NotifierProvider<OnboardingController, bool>(
  OnboardingController.new,
);

/// รวม mock startup state กับ authProvider ตัวจริงของเพื่อนร่วมทีม
///
/// เมื่อปิด mockAuthBypassProvider แล้ว LoginScreen login สำเร็จ ค่า User จาก
/// authProvider จะทำให้ Router redirect ไป Dashboard โดยอัตโนมัติ
final appFlowProvider = Provider<AppFlowState>((ref) {
  final isMockAuthEnabled = ref.watch(mockAuthBypassProvider);
  final isOnboardingCompleted = ref.watch(onboardingProvider);
  final authState = ref.watch(authProvider);

  return AppFlowState(
    isInitializing: !isMockAuthEnabled && authState.isLoading,
    isOnboardingCompleted: isOnboardingCompleted,
    isAuthenticated: isMockAuthEnabled || authState.value != null,
  );
});
