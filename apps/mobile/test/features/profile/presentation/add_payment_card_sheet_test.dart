import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subscription_track/features/profile/application/payment_card_linking_controller.dart';
import 'package:subscription_track/features/profile/domain/payment_card.dart';
import 'package:subscription_track/features/profile/domain/payment_card_repository.dart';
import 'package:subscription_track/features/profile/presentation/add_payment_card_sheet.dart';
import 'package:subscription_track/features/subscriptions/application/subscription_list_controller.dart';
import 'package:subscription_track/features/subscriptions/data/in_memory_subscription_repository.dart';

class _FakePaymentCardRepository implements PaymentCardRepository {
  String? lastLinkedId;
  bool shouldThrowOwnershipError = false;

  @override
  Future<List<PaymentCard>> getLinkedCards() async => [];

  @override
  Future<List<PaymentCard>> getAvailableCards() async => [
        const PaymentCard(
          id: 'mock-kbank-1',
          bankName: 'Kasikornbank',
          last4Digits: '9999',
          creditLimit: 0,
          currentBalance: 15000,
          colorHex: '#00A859',
          detectedSubscriptions: [],
        ),
      ];

  @override
  Future<PaymentCard> linkCard(String id) async {
    lastLinkedId = id;
    if (shouldThrowOwnershipError) {
      throw Exception('This card does not belong to your account.');
    }
    return PaymentCard(
      id: id,
      bankName: 'Siam Commercial Bank',
      last4Digits: '4321',
      creditLimit: 0,
      currentBalance: 25000,
      colorHex: '#1A1F71',
      detectedSubscriptions: const [],
    );
  }

  @override
  Future<void> deleteCard(String id, {String? pin}) async {}
}

void main() {
  Widget buildTestWidget({required _FakePaymentCardRepository repo}) {
    return ProviderScope(
      overrides: [
        paymentCardRepositoryProvider.overrideWithValue(repo),
        subscriptionRepositoryProvider.overrideWithValue(
          InMemorySubscriptionRepository(),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showAddPaymentCardSheet(context),
              child: const Text('Open Sheet'),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('validates required card ID input before submission',
      (tester) async {
    final repo = _FakePaymentCardRepository();
    await tester.pumpWidget(buildTestWidget(repo: repo));

    await tester.tap(find.text('Open Sheet'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('card_id_input')), findsOneWidget);
    expect(find.byKey(const Key('link_card_button')), findsOneWidget);

    // Tap link without entering card ID
    await tester.tap(find.byKey(const Key('link_card_button')));
    await tester.pumpAndSettle();

    expect(find.text('กรุณากรอก Card ID หรือหมายเลขบัตร'), findsOneWidget);
    expect(repo.lastLinkedId, isNull);
  });

  testWidgets('successfully links card when valid card ID is provided',
      (tester) async {
    final repo = _FakePaymentCardRepository();
    await tester.pumpWidget(buildTestWidget(repo: repo));

    await tester.tap(find.text('Open Sheet'));
    await tester.pumpAndSettle();

    const targetCardId = 'c0000000-0000-4000-a000-000000000001';
    await tester.enterText(
        find.byKey(const Key('card_id_input')), targetCardId);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('link_card_button')));
    await tester.pumpAndSettle();

    expect(repo.lastLinkedId, targetCardId);
    expect(find.byKey(const Key('card_id_input')), findsNothing);
  });

  testWidgets(
      'displays ownership error banner and dialog when card belongs to another user',
      (tester) async {
    final repo = _FakePaymentCardRepository()
      ..shouldThrowOwnershipError = true;
    await tester.pumpWidget(buildTestWidget(repo: repo));

    await tester.tap(find.text('Open Sheet'));
    await tester.pumpAndSettle();

    const otherUserCardId = 'c0000000-0000-4000-a000-000000000002';
    await tester.enterText(
        find.byKey(const Key('card_id_input')), otherUserCardId);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('link_card_button')));
    await tester.pumpAndSettle();

    expect(repo.lastLinkedId, otherUserCardId);
    // Dialog and banner are visible
    expect(find.textContaining('This card does not belong to your account.'),
        findsWidgets);
    expect(find.text('ไม่สามารถเชื่อมต่อบัตรได้'), findsOneWidget);
  });
}
