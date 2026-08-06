import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subscription_track/core/theme/app_colors.dart';
import 'package:subscription_track/core/theme/app_theme.dart';
import 'package:subscription_track/widgets/common/confirmation_dialog.dart';

void main() {
  testWidgets('returns false when the user cancels', (tester) async {
    bool? result;
    await tester.pumpWidget(
      _DialogTestApp(
        onResult: (value) => result = value,
        showDialog: (context) => ConfirmationDialog.show(
          context: context,
          title: 'ยืนยันรายการ',
          message: 'ต้องการดำเนินการต่อหรือไม่?',
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('open-dialog-button')));
    await tester.pumpAndSettle();

    expect(find.text('ยืนยันรายการ'), findsOneWidget);
    expect(find.text('ต้องการดำเนินการต่อหรือไม่?'), findsOneWidget);

    await tester.tap(find.byKey(const Key('confirmation-cancel-button')));
    await tester.pumpAndSettle();

    expect(result, isFalse);
    expect(find.byKey(const Key('confirmation-dialog')), findsNothing);
  });

  testWidgets('uses danger styling and returns true when confirmed', (
    tester,
  ) async {
    bool? result;
    await tester.pumpWidget(
      _DialogTestApp(
        onResult: (value) => result = value,
        showDialog: (context) => ConfirmationDialog.show(
          context: context,
          title: 'ลบบริการ',
          message: 'การดำเนินการนี้ไม่สามารถย้อนกลับได้',
          confirmText: 'ลบถาวร',
          cancelText: 'เก็บไว้',
          isDanger: true,
          icon: Icons.delete_outline_rounded,
          barrierDismissible: false,
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('open-dialog-button')));
    await tester.pumpAndSettle();

    expect(find.text('ลบถาวร'), findsOneWidget);
    expect(find.text('เก็บไว้'), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);

    final confirmButton = tester.widget<FilledButton>(
      find.byKey(const Key('confirmation-confirm-button')),
    );
    expect(
      confirmButton.style?.backgroundColor?.resolve(<WidgetState>{}),
      AppColors.danger,
    );

    await tester.tapAt(const Offset(4, 4));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('confirmation-dialog')), findsOneWidget);
    expect(result, isNull);

    await tester.tap(find.byKey(const Key('confirmation-confirm-button')));
    await tester.pumpAndSettle();

    expect(result, isTrue);
  });
}

class _DialogTestApp extends StatelessWidget {
  const _DialogTestApp({required this.showDialog, required this.onResult});

  final Future<bool> Function(BuildContext context) showDialog;
  final ValueChanged<bool> onResult;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: FilledButton(
              key: const Key('open-dialog-button'),
              onPressed: () async => onResult(await showDialog(context)),
              child: const Text('เปิด Dialog'),
            ),
          ),
        ),
      ),
    );
  }
}
