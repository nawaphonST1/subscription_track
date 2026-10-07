import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subscription_track/core/security/pin_provider.dart';
import 'package:subscription_track/core/widgets/pin_verification_dialog.dart';
import 'package:subscription_track/features/subscriptions/application/subscription_list_controller.dart';
import 'package:subscription_track/features/subscriptions/domain/subscription.dart';
import 'package:subscription_track/features/subscriptions/domain/subscription_repository.dart';
import 'package:subscription_track/features/subscriptions/presentation/subscriptions_tab.dart';

import '../../../support/in_memory_pin_repository.dart';

class _CapturingSubscriptionRepository implements SubscriptionRepository {
  String? deletedId;
  String? deletedPin;

  @override
  Future<List<Subscription>> getSubscriptions() async => [
        const Subscription(
          id: 'sub-test-1',
          name: 'Netflix Premium',
          price: 419,
          category: 'streaming',
        ),
      ];

  @override
  Future<Subscription> getSubscriptionById(String id) async =>
      const Subscription(id: 'sub-test-1', name: 'Netflix Premium', price: 419);

  @override
  Future<void> addSubscription(Subscription subscription) async {}

  @override
  Future<void> updateSubscription(Subscription subscription) async {}

  @override
  Future<void> deleteSubscription(String id, {String? pin}) async {
    deletedId = id;
    deletedPin = pin;
  }

  @override
  Future<void> toggleSelection(String id) async {}
}

void main() {
  const testPin = '482910';

  testWidgets(
      'User enters PIN in verification dialog -> subscription deletion receives that exact PIN',
      (tester) async {
    final pinRepo = InMemoryPinRepository(currentPin: testPin);
    final subRepo = _CapturingSubscriptionRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pinRepositoryProvider.overrideWithValue(pinRepo),
          subscriptionRepositoryProvider.overrideWithValue(subRepo),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SubscriptionsTab(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Verify item is displayed
    expect(find.text('Netflix Premium'), findsOneWidget);

    // 2. Open options menu and tap 'ลบบริการ'
    final popupMenu = find.byType(PopupMenuButton<String>);
    expect(popupMenu, findsOneWidget);
    await tester.tap(popupMenu);
    await tester.pumpAndSettle();

    final deleteMenuItem = find.text('ลบบริการ');
    expect(deleteMenuItem, findsOneWidget);
    await tester.tap(deleteMenuItem);
    await tester.pumpAndSettle();

    // 3. Confirmation dialog opens -> confirm deletion
    expect(find.text('ลบบริการนี้หรือไม่?'), findsOneWidget);
    final confirmButton = find.widgetWithText(FilledButton, 'ลบบริการ');
    expect(confirmButton, findsOneWidget);
    await tester.tap(confirmButton);
    await tester.pumpAndSettle();

    // 4. PIN dialog opens -> enter PIN
    expect(find.text('ยืนยันการลบบริการ'), findsOneWidget);
    final pinTextField = find.descendant(
      of: find.byType(PinVerificationDialog),
      matching: find.byType(TextField),
    );
    expect(pinTextField, findsOneWidget);
    await tester.enterText(pinTextField, testPin);
    await tester.pump();
    await tester.pumpAndSettle();

    // 5. Verify repository received the delete request with the exact entered PIN
    expect(subRepo.deletedId, 'sub-test-1');
    expect(subRepo.deletedPin, testPin);
  });
}
