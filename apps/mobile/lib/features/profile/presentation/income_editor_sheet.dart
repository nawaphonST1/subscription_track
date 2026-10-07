import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subscription_track/features/auth/application/auth_provider.dart';
import 'package:subscription_track/features/auth/domain/credit_card.dart';
import 'package:subscription_track/features/profile/application/payment_card_linking_controller.dart';
import 'package:subscription_track/features/profile/application/user_income_controller.dart';
import 'package:subscription_track/features/profile/domain/payment_card.dart';

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
    final displayIncome = ref.watch(effectiveIncomeProvider);
    final user = ref.watch(authProvider).value;
    final linkedCardsAsync = ref.watch(linkedPaymentCardsProvider);
    final linkedCards = linkedCardsAsync.value ?? const <PaymentCard>[];
    final legacyCards = user?.creditCards ?? const <CreditCard>[];

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
                  'สรุปรายได้จากบัตรชำระเงิน',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'คำนวณอัตโนมัติจากผลรวมยอดเงินคงเหลือในบัตรชำระเงินที่ผูกไว้ '
            'เพื่อใช้ประเมินความเสี่ยง Creep Risk และภาพรวมการเงิน',
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
              text: displayIncome.toStringAsFixed(0),
            ),
            decoration: const InputDecoration(
              prefixText: '฿ ',
              labelText: 'รายได้รวมต่อเดือน (คำนวณจากบัตรที่ผูกไว้)',
              suffixIcon: Icon(Icons.lock_outline_rounded, size: 20),
              helperText: 'ดึงข้อมูลจากบัตรที่ผูกไว้ในระบบ ไม่อนุญาตให้แก้ไขโดยตรง',
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'รายการบัตรที่ผูกไว้ในระบบ:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 8),
          if (linkedCardsAsync.isLoading && linkedCards.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20.0),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (linkedCards.isEmpty && legacyCards.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'ไม่พบบัตรชำระเงินในระบบ',
                      style: TextStyle(color: theme.textTheme.bodySmall?.color),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => ref.refresh(linkedPaymentCardsProvider),
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('โหลดใหม่'),
                  ),
                ],
              ),
            )
          else
            Card(
              clipBehavior: Clip.antiAlias,
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  if (linkedCards.isNotEmpty)
                    for (var i = 0; i < linkedCards.length; i++) ...[
                      if (i > 0) Divider(height: 1, color: theme.dividerColor),
                      _PaymentCardRowTile(card: linkedCards[i]),
                    ]
                  else
                    for (var i = 0; i < legacyCards.length; i++) ...[
                      if (i > 0) Divider(height: 1, color: theme.dividerColor),
                      _CreditCardRowTile(card: legacyCards[i]),
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

class _PaymentCardRowTile extends StatelessWidget {
  const _PaymentCardRowTile({required this.card});

  final PaymentCard card;

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
        card.creditLimit > 0
            ? 'วงเงินคงเหลือ ฿${card.currentBalance.toStringAsFixed(0)} / ฿${card.creditLimit.toStringAsFixed(0)}'
            : 'ยอดเงินในบัตร ฿${card.currentBalance.toStringAsFixed(0)}',
      ),
      trailing: Text(
        '฿${card.currentBalance.toStringAsFixed(0)}',
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
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
