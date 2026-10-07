import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:subscription_track/core/errors/failures.dart';
import 'package:subscription_track/core/security/pin_provider.dart';
import 'package:subscription_track/core/widgets/change_pin_dialog.dart';

import '../../support/in_memory_pin_repository.dart';

void main() {
  const testOldPin = '234567';
  const testNewPin = '345678';
  const testWrongPin = '999999';

  Widget buildTestWidget({
    required InMemoryPinRepository repo,
  }) {
    return ProviderScope(
      overrides: [
        pinRepositoryProvider.overrideWithValue(repo),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => ChangePinDialog.show(context),
              child: const Text('Change PIN'),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('completes full PIN change flow successfully', (tester) async {
    final repo = InMemoryPinRepository(currentPin: testOldPin);

    await tester.pumpWidget(buildTestWidget(repo: repo));

    await tester.tap(find.text('Change PIN'));
    await tester.pumpAndSettle();

    // Step 1: verifyOld
    expect(find.text('ยืนยัน PIN เดิม'), findsOneWidget);
    final textField = find.byType(TextField);
    await tester.enterText(textField, testOldPin);
    await tester.pump();
    await tester.pumpAndSettle();

    expect(repo.verifyCallCount, 1);

    // Step 2: enterNew
    expect(find.text('ตั้งค่า PIN ใหม่'), findsOneWidget);
    await tester.enterText(textField, testNewPin);
    await tester.pump();
    await tester.pumpAndSettle();

    // Step 3: confirmNew
    expect(find.text('ยืนยัน PIN ใหม่'), findsOneWidget);
    await tester.enterText(textField, testNewPin);
    await tester.pump();
    await tester.pumpAndSettle();

    expect(repo.changeCallCount, 1);
    expect(repo.lastChangedCurrentPin, testOldPin);
    expect(repo.lastChangedNewPin, testNewPin);
    expect(repo.currentPin, testNewPin);

    expect(find.text('เปลี่ยนรหัส PIN สำเร็จแล้ว'), findsOneWidget);
    expect(find.byType(ChangePinDialog), findsNothing);
  });

  testWidgets('completes PIN change by tapping on-screen keypad buttons', (tester) async {
    final repo = InMemoryPinRepository(currentPin: testOldPin);

    await tester.pumpWidget(buildTestWidget(repo: repo));

    await tester.tap(find.text('Change PIN'));
    await tester.pumpAndSettle();

    Future<void> tapDigits(String pin) async {
      for (final digit in pin.split('')) {
        await tester.tap(find.byKey(Key('pin_key_$digit')));
        await tester.pump();
      }
      await tester.pumpAndSettle();
    }

    // Step 1: old PIN via keypad
    expect(find.text('ยืนยัน PIN เดิม'), findsOneWidget);
    await tapDigits(testOldPin);
    expect(repo.verifyCallCount, 1);

    // Step 2: new PIN via keypad
    expect(find.text('ตั้งค่า PIN ใหม่'), findsOneWidget);
    await tapDigits(testNewPin);

    // Step 3: confirm PIN via keypad
    expect(find.text('ยืนยัน PIN ใหม่'), findsOneWidget);
    await tapDigits(testNewPin);

    expect(repo.changeCallCount, 1);
    expect(repo.currentPin, testNewPin);
    expect(find.text('เปลี่ยนรหัส PIN สำเร็จแล้ว'), findsOneWidget);
    expect(find.byType(ChangePinDialog), findsNothing);
  });

  testWidgets('shows error on wrong old PIN and allows retry', (tester) async {
    final repo = InMemoryPinRepository(currentPin: testOldPin);

    await tester.pumpWidget(buildTestWidget(repo: repo));

    await tester.tap(find.text('Change PIN'));
    await tester.pumpAndSettle();

    // Step 1: enter wrong old PIN
    final textField = find.byType(TextField);
    await tester.enterText(textField, testWrongPin);
    await tester.pump();
    await tester.pumpAndSettle();

    expect(repo.verifyCallCount, 1);
    expect(find.text('รหัส PIN เดิมไม่ถูกต้อง'), findsOneWidget);
    expect(find.text('ยืนยัน PIN เดิม'), findsOneWidget);

    // Retry with correct old PIN
    await tester.enterText(textField, testOldPin);
    await tester.pump();
    await tester.pumpAndSettle();

    expect(repo.verifyCallCount, 2);
    expect(find.text('ตั้งค่า PIN ใหม่'), findsOneWidget);
  });

  testWidgets('shows error on confirmation mismatch and resets to enter new', (tester) async {
    final repo = InMemoryPinRepository(currentPin: testOldPin);

    await tester.pumpWidget(buildTestWidget(repo: repo));

    await tester.tap(find.text('Change PIN'));
    await tester.pumpAndSettle();

    final textField = find.byType(TextField);

    // Step 1: old PIN
    await tester.enterText(textField, testOldPin);
    await tester.pumpAndSettle();

    // Step 2: enter new PIN
    await tester.enterText(textField, testNewPin);
    await tester.pumpAndSettle();

    // Step 3: enter mismatch PIN
    await tester.enterText(textField, testWrongPin);
    await tester.pumpAndSettle();

    expect(find.text('PINs do not match. Please try again.'), findsOneWidget);
    expect(find.text('ตั้งค่า PIN ใหม่'), findsOneWidget);
    expect(repo.changeCallCount, 0);
  });

  testWidgets('rejects weak PIN pattern (repeated digits or 123456) in step 2', (tester) async {
    final repo = InMemoryPinRepository(currentPin: testOldPin);

    await tester.pumpWidget(buildTestWidget(repo: repo));

    await tester.tap(find.text('Change PIN'));
    await tester.pumpAndSettle();

    final textField = find.byType(TextField);

    // Step 1: old PIN
    await tester.enterText(textField, testOldPin);
    await tester.pumpAndSettle();

    // Step 2: enter weak PIN 111111
    await tester.enterText(textField, '111111');
    await tester.pumpAndSettle();

    expect(
      find.text('PIN is too weak. Please avoid sequential (123456) or repeated numbers (111111).'),
      findsOneWidget,
    );
    expect(find.text('ตั้งค่า PIN ใหม่'), findsOneWidget);

    // Step 2 retry: enter weak sequential PIN 123456
    await tester.enterText(textField, '123456');
    await tester.pumpAndSettle();

    expect(
      find.text('PIN is too weak. Please avoid sequential (123456) or repeated numbers (111111).'),
      findsOneWidget,
    );
    expect(find.text('ตั้งค่า PIN ใหม่'), findsOneWidget);
  });

  testWidgets('displays error on network failure during changePin', (tester) async {
    final repo = InMemoryPinRepository(
      currentPin: testOldPin,
      changeResult: left(const Failure.networkError()),
    );

    await tester.pumpWidget(buildTestWidget(repo: repo));

    await tester.tap(find.text('Change PIN'));
    await tester.pumpAndSettle();

    final textField = find.byType(TextField);

    // Step 1: old PIN
    await tester.enterText(textField, testOldPin);
    await tester.pumpAndSettle();

    // Step 2: enter new PIN
    await tester.enterText(textField, testNewPin);
    await tester.pumpAndSettle();

    // Step 3: confirm new PIN
    await tester.enterText(textField, testNewPin);
    await tester.pump();
    await tester.pumpAndSettle();

    expect(repo.changeCallCount, 1);
    expect(find.text('ไม่สามารถเชื่อมต่อเครือข่ายได้'), findsOneWidget);
    expect(find.byType(ChangePinDialog), findsOneWidget);
  });
}
