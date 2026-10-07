import 'package:flutter/material.dart';
import 'package:subscription_track/features/profile/domain/payment_card.dart';

/// บังคับเลือกบัตรที่เชื่อมต่อไว้แล้วก่อนสร้างรายการสมัครสมาชิกใหม่ — backend
/// (`CreateSubscriptionDto.payment_card_id`) ต้องมีบัตรเสมอ จึงไม่ปล่อยให้
/// ส่ง null ไปแล้วให้ backend ตอบ 400 แบบงง ๆ
class PaymentCardSelector extends StatelessWidget {
  const PaymentCardSelector({
    required this.cards,
    required this.selectedCardId,
    required this.onChanged,
    super.key,
  });

  final List<PaymentCard> cards;
  final String? selectedCardId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (cards.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'ยังไม่มีบัตรที่เชื่อมต่อ กรุณาเพิ่มบัตรก่อนสร้างรายการสมัครสมาชิก',
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'บัตรที่ใช้ชำระ',
          style: TextStyle(
            color: theme.textTheme.bodySmall?.color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          key: const Key('payment_card_selector'),
          initialValue: selectedCardId,
          isExpanded: true,
          decoration: const InputDecoration(
            hintText: 'เลือกบัตร',
          ),
          items: [
            for (final card in cards)
              DropdownMenuItem(
                value: card.id,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${card.bankName} •••• ${card.last4Digits}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '฿${card.currentBalance.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
          ],
          onChanged: onChanged,
          validator: (value) =>
              value == null || value.isEmpty ? 'กรุณาเลือกบัตรที่ใช้ชำระ' : null,
        ),
      ],
    );
  }
}
