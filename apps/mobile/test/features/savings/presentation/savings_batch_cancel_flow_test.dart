import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subscription_track/core/security/pin_provider.dart';
import 'package:subscription_track/core/widgets/pin_verification_dialog.dart';
import 'package:subscription_track/features/savings/data/remote_savings_repository.dart';
import 'package:subscription_track/features/savings/domain/savings_optimizer_report.dart';
import 'package:subscription_track/features/savings/domain/savings_repository.dart';
import 'package:subscription_track/features/savings/presentation/savings_tab.dart';
import 'package:subscription_track/features/subscriptions/data/in_memory_subscription_repository.dart';
import 'package:subscription_track/features/subscriptions/application/subscription_list_controller.dart';

import '../../../support/in_memory_pin_repository.dart';

class _CapturingSavingsRepository implements SavingsRepository {
  _CapturingSavingsRepository(this.report);

  final SavingsOptimizerReport report;
  List<String>? capturedSubscriptionIds;
  String? capturedPin;

  @override
  Future<SavingsOptimizerReport> getOptimizerReport() async => report;

  @override
  Future<BatchCancelResult> batchCancel({
    required List<String> subscriptionIds,
    required String pin,
  }) async {
    capturedSubscriptionIds = subscriptionIds;
    capturedPin = pin;
    return BatchCancelResult(
      message: 'OK',
      cancelledCount: subscriptionIds.length,
      totalYearlySavingsUnlocked: 5028.0,
    );
  }
}

void main() {
  const testPin = '482910';

  const testReport = SavingsOptimizerReport(
    unusedSubscriptionsCount: 1,
    totalMonthlySavings: 419.0,
    totalYearlySavingsProjection: 5028.0,
    recommendedCancellations: [
      SavingsOptimizerItem(
        id: 'sub-test-1',
        name: 'Netflix Premium',
        category: 'entertainment',
        price: 419.0,
        billingCycle: 'monthly',
        normalizedMonthlyCost: 419.0,
        yearlySavingsProjection: 5028.0,
        paymentCard: SavingsPaymentCard(
          cardNickname: 'Main Card',
          last4Digits: '1234',
          bankName: 'SCB',
        ),
      ),
    ],
  );

  testWidgets(
      'User selects unused subscription -> confirms -> enters PIN -> batchCancel receives IDs and PIN',
      (tester) async {
    final pinRepo = InMemoryPinRepository(currentPin: testPin);
    final savingsRepo = _CapturingSavingsRepository(testReport);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pinRepositoryProvider.overrideWithValue(pinRepo),
          savingsRepositoryProvider.overrideWithValue(savingsRepo),
          subscriptionRepositoryProvider.overrideWithValue(
            InMemorySubscriptionRepository(ioDelay: Duration.zero),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SavingsTab(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Verify item is displayed with card info
    expect(find.text('Netflix Premium'), findsOneWidget);
    expect(find.textContaining('Main Card (•• 1234)'), findsOneWidget);

    // 2. Select the item via CheckboxListTile
    final checkboxTile = find.byKey(const Key('saving-sub-test-1'));
    expect(checkboxTile, findsOneWidget);
    await tester.tap(checkboxTile);
    await tester.pumpAndSettle();

    // 3. Tap cancel selected button
    final cancelBtn = find.byKey(const Key('cancel-selected-button'));
    expect(cancelBtn, findsOneWidget);
    await tester.tap(cancelBtn);
    await tester.pumpAndSettle();

    // 4. Confirmation dialog -> confirm
    expect(find.text('ยืนยันการยกเลิก'), findsOneWidget);
    final confirmButton = find.widgetWithText(FilledButton, 'ยกเลิกรายการ');
    expect(confirmButton, findsOneWidget);
    await tester.tap(confirmButton);
    await tester.pumpAndSettle();

    // 5. PIN dialog opens -> enter 6-digit PIN
    expect(find.text('ยืนยันการยกเลิกบริการ'), findsOneWidget);
    final pinTextField = find.descendant(
      of: find.byType(PinVerificationDialog),
      matching: find.byType(TextField),
    );
    expect(pinTextField, findsOneWidget);
    await tester.enterText(pinTextField, testPin);
    await tester.pumpAndSettle();

    // 6. Verify batchCancel was invoked with the exact selected ID and PIN
    expect(savingsRepo.capturedSubscriptionIds, ['sub-test-1']);
    expect(savingsRepo.capturedPin, testPin);

    // 7. Verify success snackbar appears
    expect(
      find.textContaining('ยกเลิกบริการแล้ว 1 รายการ'),
      findsOneWidget,
    );
  });
}
