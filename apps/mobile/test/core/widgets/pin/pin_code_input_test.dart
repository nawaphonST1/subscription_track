import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subscription_track/core/widgets/pin/pin.dart';

void main() {
  group('PinCodeInput Widget Tests', () {
    late TextEditingController controller;
    late FocusNode focusNode;

    setUp(() {
      controller = TextEditingController();
      focusNode = FocusNode();
    });

    tearDown(() {
      controller.dispose();
      focusNode.dispose();
    });

    Widget buildTestWidget({
      bool hasError = false,
      bool isLoading = false,
      bool obscureText = true,
      ValueChanged<String>? onCompleted,
      ValueChanged<String>? onChanged,
      Key? textFieldKey,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: PinCodeInput(
              controller: controller,
              focusNode: focusNode,
              hasError: hasError,
              isLoading: isLoading,
              obscureText: obscureText,
              onCompleted: onCompleted,
              onChanged: onChanged,
              textFieldKey: textFieldKey,
            ),
          ),
        ),
      );
    }

    testWidgets('renders 6 visual boxes and captures text input', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final textFieldFinder = find.byType(TextField);
      expect(textFieldFinder, findsOneWidget);

      // Initially no dots
      expect(find.text('•'), findsNothing);

      // Enter 3 digits
      await tester.enterText(textFieldFinder, '123');
      await tester.pump();

      // Should show 3 bullets
      expect(find.text('•'), findsNWidgets(3));
    });

    testWidgets('fires onCompleted exactly when length reaches 6 digits', (tester) async {
      String? completedPin;
      String? changedPin;

      await tester.pumpWidget(
        buildTestWidget(
          onCompleted: (val) => completedPin = val,
          onChanged: (val) => changedPin = val,
        ),
      );
      await tester.pumpAndSettle();

      final textFieldFinder = find.byType(TextField);

      await tester.enterText(textFieldFinder, '12345');
      await tester.pump();
      expect(changedPin, '12345');
      expect(completedPin, isNull);

      await tester.enterText(textFieldFinder, '123456');
      await tester.pump();
      expect(changedPin, '123456');
      expect(completedPin, '123456');
    });

    testWidgets('displays actual digits when obscureText is false', (tester) async {
      await tester.pumpWidget(buildTestWidget(obscureText: false));
      await tester.pumpAndSettle();

      final textFieldFinder = find.byType(TextField);
      await tester.enterText(textFieldFinder, '482');
      await tester.pump();

      expect(find.text('4'), findsOneWidget);
      expect(find.text('8'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('respects custom textFieldKey for test finding', (tester) async {
      const customKey = Key('custom_pin_key');
      await tester.pumpWidget(buildTestWidget(textFieldKey: customKey));
      await tester.pumpAndSettle();

      expect(find.byKey(customKey), findsOneWidget);
      await tester.enterText(find.byKey(customKey), '999');
      await tester.pump();
      expect(controller.text, '999');
    });
  });

  group('PinNumericKeypad & PinKeypadHelper Tests', () {
    late TextEditingController controller;
    late FocusNode focusNode;

    setUp(() {
      controller = TextEditingController();
      focusNode = FocusNode();
    });

    tearDown(() {
      controller.dispose();
      focusNode.dispose();
    });

    testWidgets('tapping numeric keypad buttons triggers PinKeypadHelper correctly',
        (tester) async {
      String? completedPin;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PinNumericKeypad(
              onDigitTap: (digit) => PinKeypadHelper.handleDigitTap(
                controller: controller,
                focusNode: focusNode,
                digit: digit,
                onCompleted: (val) => completedPin = val,
              ),
              onClearTap: () => PinKeypadHelper.handleClear(
                controller: controller,
                focusNode: focusNode,
              ),
              onBackspaceTap: () => PinKeypadHelper.handleBackspace(
                controller: controller,
                focusNode: focusNode,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap 1, 2, 3
      await tester.tap(find.byKey(const Key('pin_key_1')));
      await tester.tap(find.byKey(const Key('pin_key_2')));
      await tester.tap(find.byKey(const Key('pin_key_3')));
      await tester.pump();
      expect(controller.text, '123');

      // Tap backspace
      await tester.tap(find.byKey(const Key('pin_key_backspace')));
      await tester.pump();
      expect(controller.text, '12');

      // Tap clear
      await tester.tap(find.byKey(const Key('pin_key_clear')));
      await tester.pump();
      expect(controller.text, '');

      // Tap 6 digits to trigger onCompleted
      for (final d in ['9', '8', '7', '6', '5', '4']) {
        await tester.tap(find.byKey(Key('pin_key_$d')));
        await tester.pump();
      }
      expect(controller.text, '987654');
      expect(completedPin, '987654');
    });
  });
}
