import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subscription_track/features/auth/application/auth_provider.dart';
import 'package:subscription_track/features/auth/domain/credit_card.dart';
import 'package:subscription_track/features/profile/application/user_income_controller.dart';

Future<void> showIncomeEditorSheet({
  required BuildContext context,
  required double currentIncome,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _IncomeEditorSheet(),
  );
}

class _IncomeEditorSheet extends ConsumerWidget {
  const _IncomeEditorSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final income = ref.watch(userIncomeProvider);
    final user = ref.watch(authProvider).value;
    final creditCards = user?.creditCards ?? const <CreditCard>[];

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
          const Row(
            children: [
              Icon(
                Icons.credit_card_rounded,
                color: Color(0xFF10B981),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'สรุปรายได้จากบัตรเครดิต',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'คำนวณอัตโนมัติจากผลรวมยอดเงินคงเหลือในบัตรเครดิต (CreditCard Domain) '
            'เพื่อใช้ประเมิน Creep Risk',
            style: TextStyle(
              color: theme.textTheme.bodySmall?.color,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('income-field'),
            readOnly: true,
            controller: TextEditingController(
              text: income.toStringAsFixed(0),
            ),
            decoration: const InputDecoration(
              prefixText: '฿ ',
              labelText: 'รายได้รวมต่อเดือน (คำนวณจากบัตรเครดิต)',
              suffixIcon: Icon(Icons.lock_outline_rounded, size: 20),
              helperText: 'ดึงข้อมูลจาก CreditCard ในระบบ ไม่อนุญาตให้แก้ไขโดยตรง',
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'รายการบัตรเครดิตที่ผูกไว้ (CreditCard Model):',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 8),
          if (creditCards.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Text(
                'ไม่พบบัตรเครดิตในระบบ',
                style: TextStyle(color: theme.textTheme.bodySmall?.color),
              ),
            )
          else
            Card(
              clipBehavior: Clip.antiAlias,
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var i = 0; i < creditCards.length; i++) ...[
                    if (i > 0) Divider(height: 1, color: theme.dividerColor),
                    _CreditCardRowTile(card: creditCards[i]),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 20),
          FilledButton(
            key: const Key('save-income-button'),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('เข้าใจแล้ว'),
          ),
        ],
      ),
    );
  }
}

class _CreditCardRowTile extends StatelessWidget {
  const _CreditCardRowTile({required this.card});

  final CreditCard card;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: const Icon(Icons.credit_card_rounded, color: Color(0xFF10B981)),
      title: Text(
        '${card.bankName} (**** ${card.last4Digits})',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        'วงเงินคงเหลือ ฿${card.currentBalance.toStringAsFixed(0)} / ฿${card.creditLimit.toStringAsFixed(0)}',
      ),
      trailing: Text(
        '฿${card.currentBalance.toStringAsFixed(0)}',
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
    );
  }
}
