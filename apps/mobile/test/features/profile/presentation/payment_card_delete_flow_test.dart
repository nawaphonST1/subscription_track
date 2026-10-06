import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subscription_track/core/security/pin_provider.dart';
import 'package:subscription_track/features/profile/application/payment_card_linking_controller.dart';
import 'package:subscription_track/features/profile/domain/payment_card.dart';
import 'package:subscription_track/features/profile/domain/payment_card_repository.dart';
import 'package:subscription_track/features/profile/presentation/widgets/linked_accounts_card.dart';

import '../../../support/in_memory_pin_repository.dart';

class _CapturingPaymentCardRepository implements PaymentCardRepository {
  String? deletedId;
  String? deletedPin;

  @override
  Future<List<PaymentCard>> getLinkedCards() async => [
        const PaymentCard(
          id: 'card-test-1',
          bankName: 'KBank Platinum',
          last4Digits: '4242',
          creditLimit: 50000,
          currentBalance: 12500,
          colorHex: '#00A859',
          detectedSubscriptions: [],
        ),
      ];

  @override
  Future<List<PaymentCard>> getAvailableCards() async => [];

  @override
  Future<PaymentCard> linkCard(String id) async => const PaymentCard(
        id: 'card-test-1',
        bankName: 'KBank Platinum',
        last4Digits: '4242',
        creditLimit: 50000,
        currentBalance: 12500,
        colorHex: '#00A859',
        detectedSubscriptions: [],
      );

  @override
  Future<void> deleteCard(String id, {String? pin}) async {
    deletedId = id;
    deletedPin = pin;
  }
}

void main() {
  const testPin = '482910';

  testWidgets(
      'User enters PIN in verification dialog -> payment card deletion receives that exact PIN',
      (tester) async {
    final pinRepo = InMemoryPinRepository(currentPin: testPin);
    final cardRepo = _CapturingPaymentCardRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pinRepositoryProvider.overrideWithValue(pinRepo),
          paymentCardRepositoryProvider.overrideWithValue(cardRepo),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: LinkedAccountsCard(),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Verify card is displayed
    expect(find.text('KBank Platinum'), findsOneWidget);

    // 2. Tap delete button on the card tile
    final deleteButton = find.byTooltip('ยกเลิกการเชื่อมต่อบัตร');
    expect(deleteButton, findsOneWidget);
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();

    // 3. Confirmation dialog opens -> confirm deletion
    expect(find.text('ยกเลิกการเชื่อมต่อบัตรหรือไม่?'), findsOneWidget);
    final confirmButton = find.widgetWithText(FilledButton, 'ยกเลิกบัตร');
    expect(confirmButton, findsOneWidget);
    await tester.tap(confirmButton);
    await tester.pumpAndSettle();

    // 4. PIN dialog opens -> enter PIN
    expect(find.text('ยืนยันการยกเลิกบัตร'), findsOneWidget);
    final pinTextField = find.byType(TextField);
    expect(pinTextField, findsOneWidget);
    await tester.enterText(pinTextField, testPin);
    await tester.pump();
    await tester.pumpAndSettle();

    // 5. Verify repository received the delete request with the exact entered PIN
    expect(cardRepo.deletedId, 'card-test-1');
    expect(cardRepo.deletedPin, testPin);
  });
}
