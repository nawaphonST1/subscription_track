import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:subscription_track/core/errors/failures.dart';
import 'package:subscription_track/core/security/pin_provider.dart';
import 'package:subscription_track/core/widgets/pin_verification_dialog.dart';

import '../../support/in_memory_pin_repository.dart';

void main() {
  const testValidPin = '123456';
  const testWrongPin = '654321';

  Widget buildTestWidget({
    required InMemoryPinRepository repo,
    required void Function(BuildContext context) onOpen,
  }) {
    return ProviderScope(
      overrides: [
        pinRepositoryProvider.overrideWithValue(repo),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => onOpen(context),
              child: const Text('Open Dialog'),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('returns true on successful PIN verification', (tester) async {
    final repo = InMemoryPinRepository(currentPin: testValidPin);
    bool? dialogResult;

    await tester.pumpWidget(
      buildTestWidget(
        repo: repo,
        onOpen: (context) async {
          dialogResult = await PinVerificationDialog.show(
            context: context,
            title: 'ยืนยันรหัส PIN',
          );
        },
      ),
    );

    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    expect(find.text('ยืนยันรหัส PIN'), findsOneWidget);

    final textField = find.byType(TextField);
    expect(textField, findsOneWidget);

    await tester.enterText(textField, testValidPin);
    await tester.pump();
    await tester.pumpAndSettle();

    expect(repo.verifyCallCount, 1);
    expect(repo.lastVerifiedPin, testValidPin);
    expect(dialogResult, isTrue);
    expect(find.byType(PinVerificationDialog), findsNothing);
  });

  testWidgets('displays error message on wrong PIN and allows retry', (tester) async {
    final repo = InMemoryPinRepository(currentPin: testValidPin);
    bool? dialogResult;

    await tester.pumpWidget(
      buildTestWidget(
        repo: repo,
        onOpen: (context) async {
          dialogResult = await PinVerificationDialog.show(
            context: context,
            title: 'ยืนยันรหัส PIN',
          );
        },
      ),
    );

    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    final textField = find.byType(TextField);

    // Enter wrong PIN
    await tester.enterText(textField, testWrongPin);
    await tester.pump();
    await tester.pumpAndSettle();

    expect(repo.verifyCallCount, 1);
    expect(find.text('รหัส PIN ไม่ถูกต้อง กรุณาลองใหม่อีกครั้ง'), findsOneWidget);
    expect(find.byType(PinVerificationDialog), findsOneWidget);
    expect(dialogResult, isNull);

    // Retry with correct PIN
    await tester.enterText(textField, testValidPin);
    await tester.pump();
    await tester.pumpAndSettle();

    expect(repo.verifyCallCount, 2);
    expect(dialogResult, isTrue);
    expect(find.byType(PinVerificationDialog), findsNothing);
  });

  testWidgets('displays network error message on connection failure', (tester) async {
    final repo = InMemoryPinRepository(
      verifyResult: left(const Failure.networkError()),
    );
    bool? dialogResult;

    await tester.pumpWidget(
      buildTestWidget(
        repo: repo,
        onOpen: (context) async {
          dialogResult = await PinVerificationDialog.show(
            context: context,
            title: 'ยืนยันรหัส PIN',
          );
        },
      ),
    );

    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    final textField = find.byType(TextField);
    await tester.enterText(textField, testValidPin);
    await tester.pump();
    await tester.pumpAndSettle();

    expect(repo.verifyCallCount, 1);
    expect(find.text('ไม่สามารถเชื่อมต่อเครือข่ายได้'), findsOneWidget);
    expect(find.byType(PinVerificationDialog), findsOneWidget);
    expect(dialogResult, isNull);
  });

  testWidgets('returns false when cancel button is clicked', (tester) async {
    final repo = InMemoryPinRepository();
    bool? dialogResult;

    await tester.pumpWidget(
      buildTestWidget(
        repo: repo,
        onOpen: (context) async {
          dialogResult = await PinVerificationDialog.show(
            context: context,
            title: 'ยืนยันรหัส PIN',
          );
        },
      ),
    );

    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('ยกเลิก'));
    await tester.pumpAndSettle();

    expect(repo.verifyCallCount, 0);
    expect(dialogResult, isFalse);
    expect(find.byType(PinVerificationDialog), findsNothing);
  });
}
