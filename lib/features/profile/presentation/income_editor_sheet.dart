import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subscription_track/features/profile/application/user_income_controller.dart';

Future<void> showIncomeEditorSheet({
  required BuildContext context,
  required double currentIncome,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _IncomeEditorSheet(initialIncome: currentIncome),
  );
}

class _IncomeEditorSheet extends ConsumerStatefulWidget {
  const _IncomeEditorSheet({required this.initialIncome});

  final double initialIncome;

  @override
  ConsumerState<_IncomeEditorSheet> createState() => _IncomeEditorSheetState();
}

class _IncomeEditorSheetState extends ConsumerState<_IncomeEditorSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialIncome.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'กำหนดรายได้ต่อเดือน',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'ใช้คำนวณ Creep Risk เท่านั้น '
            'และจะไม่แสดงต่อผู้ใช้อื่น',
            style: TextStyle(
              color: theme.textTheme.bodySmall?.color,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('income-field'),
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              prefixText: '฿ ',
              labelText: 'รายได้ต่อเดือน',
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            key: const Key('save-income-button'),
            onPressed: _save,
            child: const Text('บันทึกข้อมูล'),
          ),
        ],
      ),
    );
  }

  void _save() {
    final income = double.tryParse(_controller.text);
    final didUpdate =
        income != null && ref.read(userIncomeProvider.notifier).update(income);
    if (didUpdate) {
      Navigator.of(context).pop();
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('กรุณากรอกรายได้มากกว่า 0')));
  }
}
