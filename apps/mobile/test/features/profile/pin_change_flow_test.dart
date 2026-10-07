import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subscription_track/app/app.dart';
import 'package:subscription_track/app/application/app_flow_provider.dart';
import 'package:subscription_track/core/security/pin_provider.dart';
import 'package:subscription_track/core/widgets/change_pin_dialog.dart';
import 'package:subscription_track/features/dashboard/data/in_memory_creep_score_repository.dart';
import 'package:subscription_track/features/dashboard/data/remote_creep_score_repository.dart';
import 'package:subscription_track/features/notifications/application/notification_center_controller.dart';
import 'package:subscription_track/features/notifications/data/in_memory_notification_repository.dart';
import 'package:subscription_track/features/profile/application/payment_card_linking_controller.dart';
import 'package:subscription_track/features/profile/data/in_memory_payment_card_repository.dart';
import 'package:subscription_track/features/savings/data/in_memory_savings_repository.dart';
import 'package:subscription_track/features/savings/data/remote_savings_repository.dart';
import 'package:subscription_track/features/subscriptions/application/subscription_list_controller.dart';
import 'package:subscription_track/features/subscriptions/data/in_memory_subscription_repository.dart';

import '../../support/in_memory_pin_repository.dart';

List<dynamic> _offlineDataOverrides() => [
      subscriptionRepositoryProvider.overrideWithValue(
        InMemorySubscriptionRepository(ioDelay: Duration.zero),
      ),
      paymentCardRepositoryProvider.overrideWithValue(
        InMemoryPaymentCardRepository(ioDelay: Duration.zero),
      ),
      creepScoreRepositoryProvider.overrideWithValue(
        InMemoryCreepScoreRepository(ioDelay: Duration.zero),
      ),
      savingsRepositoryProvider.overrideWithValue(
        InMemorySavingsRepository(ioDelay: Duration.zero),
      ),
      notificationRepositoryProvider.overrideWithValue(
        InMemoryNotificationRepository(ioDelay: Duration.zero),
      ),
    ];

void main() {
  testWidgets(
    'E2E Flow: user navigates from Dashboard to Profile and executes 3-step PIN change flow',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const currentPin = '123456';
      const weakPin = '111111';
      const newPin = '987321';
      const mismatchPin = '987320';

      final pinRepo = InMemoryPinRepository(currentPin: currentPin);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appFlowProvider.overrideWithValue(AppFlowState.mockDashboard),
            pinRepositoryProvider.overrideWithValue(pinRepo),
            ..._offlineDataOverrides().cast(),
          ],
          child: const App(),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verify landing on Dashboard
      expect(find.byKey(const Key('hero-payout-card')), findsOneWidget);

      // 2. Navigate to Profile tab
      final profileTab = find.text('โปรไฟล์');
      expect(profileTab, findsOneWidget);
      await tester.tap(profileTab);
      await tester.pumpAndSettle();

      // 3. Find and tap PIN settings
      final pinSetting = find.byKey(const Key('pin-setting'));
      expect(pinSetting, findsOneWidget);
      await tester.tap(pinSetting);
      await tester.pumpAndSettle();

      // 4. Verify ChangePinDialog opens in Step 1 (Current PIN)
      expect(find.byType(ChangePinDialog), findsOneWidget);
      expect(find.text('ยืนยัน PIN เดิม'), findsOneWidget);

      // Helper to tap numeric keypad keys
      Future<void> tapKeypad(String pin) async {
        for (final digit in pin.split('')) {
          final keyFinder = find.byKey(Key('pin_key_$digit'));
          expect(keyFinder, findsOneWidget);
          await tester.tap(keyFinder);
          await tester.pump();
        }
        await tester.pumpAndSettle();
      }

      // Enter wrong current PIN first to test error handling
      await tapKeypad('999999');
      expect(find.text('รหัส PIN เดิมไม่ถูกต้อง'), findsOneWidget);
      expect(find.text('ยืนยัน PIN เดิม'), findsOneWidget);

      // Enter correct current PIN (123456)
      await tapKeypad(currentPin);
      expect(find.text('ตั้งค่า PIN ใหม่'), findsOneWidget);

      // 5. Step 2 (New PIN): Test weak PIN rejection (111111)
      await tapKeypad(weakPin);
      expect(
        find.textContaining('PIN is too weak'),
        findsOneWidget,
      );
      expect(find.text('ตั้งค่า PIN ใหม่'), findsOneWidget);

      // Enter valid new PIN (987321)
      await tapKeypad(newPin);
      expect(find.text('ยืนยัน PIN ใหม่'), findsOneWidget);

      // 6. Step 3 (Confirm PIN): Test mismatch PIN rejection
      await tapKeypad(mismatchPin);
      expect(find.text('PINs do not match. Please try again.'), findsOneWidget);
      expect(find.text('ตั้งค่า PIN ใหม่'), findsOneWidget);

      // Re-enter valid new PIN in Step 2
      await tapKeypad(newPin);
      expect(find.text('ยืนยัน PIN ใหม่'), findsOneWidget);

      // Confirm matching PIN in Step 3
      await tapKeypad(newPin);

      // 7. Verify submission, success SnackBar, and dialog dismissal
      expect(pinRepo.changeCallCount, 1);
      expect(pinRepo.currentPin, newPin);
      expect(find.text('เปลี่ยนรหัส PIN สำเร็จแล้ว'), findsOneWidget);
      expect(find.byType(ChangePinDialog), findsNothing);

      // Verify we are back on the Profile screen
      expect(find.byKey(const Key('pin-setting')), findsOneWidget);
    },
  );
}
