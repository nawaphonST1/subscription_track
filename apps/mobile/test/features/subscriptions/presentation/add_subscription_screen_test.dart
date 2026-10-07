import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subscription_track/features/profile/application/payment_card_linking_controller.dart';
import 'package:subscription_track/features/profile/domain/payment_card.dart';
import 'package:subscription_track/features/profile/domain/payment_card_repository.dart';
import 'package:subscription_track/features/subscriptions/domain/subscription.dart';
import 'package:subscription_track/features/subscriptions/presentation/add_subscription_screen.dart';

class _FakePaymentCardRepository implements PaymentCardRepository {
  _FakePaymentCardRepository(this.cards);

  final List<PaymentCard> cards;

  @override
  Future<List<PaymentCard>> getLinkedCards() async => cards;

  @override
  Future<List<PaymentCard>> getAvailableCards() async => const [];

  @override
  Future<PaymentCard> linkCard(String id) async =>
      cards.firstWhere((c) => c.id == id);

  @override
  Future<void> deleteCard(String id, {String? pin}) async {}
}

class _Harness {
  _Harness();

  Subscription? result;

  Widget build(List<PaymentCard> cards) {
    return ProviderScope(
      overrides: [
        paymentCardRepositoryProvider.overrideWithValue(
          _FakePaymentCardRepository(cards),
        ),
      ],
      child: MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await Navigator.of(context).push<Subscription>(
                MaterialPageRoute(
                    builder: (_) => const AddSubscriptionScreen()),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
  }
}

Future<void> _openScreen(WidgetTester tester, _Harness harness,
    List<PaymentCard> cards) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(harness.build(cards));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  const testCard = PaymentCard(
    id: 'card-1',
    bankName: 'Kasikornbank',
    last4Digits: '9999',
    creditLimit: 0,
    currentBalance: 15000,
    colorHex: '#1A1F71',
    detectedSubscriptions: [],
  );

  testWidgets(
      'save button is disabled and a warning shown when there are no linked cards',
      (tester) async {
    await _openScreen(tester, _Harness(), const []);

    expect(
      find.text('ยังไม่มีบัตรที่เชื่อมต่อ กรุณาเพิ่มบัตรก่อนสร้างรายการสมัครสมาชิก'),
      findsOneWidget,
    );
    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'บันทึกบริการ'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('payment card selector is required and shows linked cards',
      (tester) async {
    await _openScreen(tester, _Harness(), const [testCard]);

    expect(find.byKey(const Key('payment_card_selector')), findsOneWidget);

    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'บันทึกบริการ'),
    );
    expect(button.onPressed, isNotNull); // enabled once >=1 card exists

    // Form is not valid yet (name/price empty AND no card selected)
    await tester.tap(find.widgetWithText(ElevatedButton, 'บันทึกบริการ'));
    await tester.pumpAndSettle();

    expect(find.text('กรุณาเลือกบัตรที่ใช้ชำระ'), findsOneWidget);
  });

  testWidgets(
      'filling the form and selecting a card pops a Subscription with that paymentCardId',
      (tester) async {
    final harness = _Harness();
    await _openScreen(tester, harness, const [testCard]);

    final nameField = find.byType(TextFormField).first;
    final priceField = find.byType(TextFormField).at(1);
    await tester.enterText(nameField, 'Netflix');
    await tester.enterText(priceField, '419');

    await tester.tap(find.byKey(const Key('payment_card_selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kasikornbank •••• 9999').last);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'บันทึกบริการ'));
    await tester.pumpAndSettle();

    expect(harness.result, isNotNull);
    expect(harness.result!.paymentCardId, 'card-1');
    expect(harness.result!.name, 'Netflix');
    expect(harness.result!.price, 419);
  });
}
