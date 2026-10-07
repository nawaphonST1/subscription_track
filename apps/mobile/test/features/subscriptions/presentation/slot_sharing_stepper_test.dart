import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subscription_track/features/subscriptions/presentation/widgets/slot_sharing_stepper.dart';

void main() {
  Widget buildStepper({
    required int sharedMembers,
    required int maxSlots,
    required double costPerSlot,
    required ValueChanged<int> onChanged,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SlotSharingStepper(
          sharedMembers: sharedMembers,
          maxSlots: maxSlots,
          costPerSlot: costPerSlot,
          accentColor: Colors.blue,
          onChanged: onChanged,
        ),
      ),
    );
  }

  testWidgets('renders nothing when the plan only supports a single slot', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildStepper(
        sharedMembers: 1,
        maxSlots: 1,
        costPerSlot: 419,
        onChanged: (_) {},
      ),
    );

    expect(find.byType(SlotSharingStepper), findsOneWidget);
    expect(find.text('1'), findsNothing);
  });

  testWidgets('shows the Thai cost-per-slot callout only when sharing with others', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildStepper(
        sharedMembers: 1,
        maxSlots: 4,
        costPerSlot: 419,
        onChanged: (_) {},
      ),
    );
    expect(find.textContaining('หารแล้วเหลือเพียง'), findsNothing);

    await tester.pumpWidget(
      buildStepper(
        sharedMembers: 4,
        maxSlots: 4,
        costPerSlot: 104.75,
        onChanged: (_) {},
      ),
    );
    expect(find.textContaining('หารแล้วเหลือเพียง ฿105/คน/เดือน'), findsOneWidget);
  });

  testWidgets('tapping + and - invokes onChanged with the adjusted count', (
    tester,
  ) async {
    int? changedTo;
    await tester.pumpWidget(
      buildStepper(
        sharedMembers: 2,
        maxSlots: 4,
        costPerSlot: 209.5,
        onChanged: (value) => changedTo = value,
      ),
    );

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(changedTo, 3);

    await tester.tap(find.byIcon(Icons.remove));
    await tester.pump();
    expect(changedTo, 1);
  });

  testWidgets('disables the minus button at the lower bound', (tester) async {
    await tester.pumpWidget(
      buildStepper(
        sharedMembers: 1,
        maxSlots: 4,
        costPerSlot: 419,
        onChanged: (_) {},
      ),
    );

    final minusButton = tester.widget<IconButton>(
      find.ancestor(
        of: find.byIcon(Icons.remove),
        matching: find.byType(IconButton),
      ),
    );
    expect(minusButton.onPressed, isNull);
  });
}
