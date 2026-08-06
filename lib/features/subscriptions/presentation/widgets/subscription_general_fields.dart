import 'package:flutter/material.dart';

class SubscriptionGeneralFields extends StatelessWidget {
  const SubscriptionGeneralFields({
    required this.nameController,
    required this.priceController,
    required this.billingPeriod,
    required this.nameValidator,
    required this.priceValidator,
    required this.onBillingPeriodChanged,
    super.key,
  });

  final TextEditingController nameController;
  final TextEditingController priceController;
  final String billingPeriod;
  final FormFieldValidator<String> nameValidator;
  final FormFieldValidator<String> priceValidator;
  final ValueChanged<String> onBillingPeriodChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('กรอกรายละเอียดสัญญา'),
        const SizedBox(height: 16),
        TextFormField(
          controller: nameController,
          validator: nameValidator,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'ชื่อบริการ / ร้านค้า'),
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: priceController,
          validator: priceValidator,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          decoration: const InputDecoration(
            labelText: 'ราคา (บาท)',
            prefixText: '฿ ',
          ),
        ),
        const SizedBox(height: 24),
        const _SectionTitle('รอบชำระเงิน'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _PeriodChip(
                label: 'รายเดือน (Monthly)',
                selected: billingPeriod == 'Monthly',
                onSelected: () => onBillingPeriodChanged('Monthly'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _PeriodChip(
                label: 'รายปี (Yearly)',
                selected: billingPeriod == 'Yearly',
                onSelected: () => onBillingPeriodChanged('Yearly'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: TextStyle(
        color: theme.textTheme.bodySmall?.color,
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ChoiceChip(
      label: SizedBox(
        height: 36,
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? Colors.white
                  : theme.textTheme.bodyMedium?.color,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
      selected: selected,
      onSelected: (value) {
        if (value) onSelected();
      },
      selectedColor: theme.colorScheme.primary,
      backgroundColor: theme.cardColor,
      side: BorderSide(
        color: selected ? theme.colorScheme.primary : theme.dividerColor,
        width: 1.5,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      showCheckmark: false,
    );
  }
}
