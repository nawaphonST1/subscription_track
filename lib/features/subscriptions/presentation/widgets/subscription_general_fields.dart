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
          style: const TextStyle(color: Colors.white),
          decoration: _inputDecoration(label: 'ชื่อบริการ / ร้านค้า'),
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: priceController,
          validator: priceValidator,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
          decoration: _inputDecoration(label: 'ราคา (บาท)').copyWith(
            prefixText: '฿ ',
            prefixStyle: const TextStyle(color: Colors.white, fontSize: 18),
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

  InputDecoration _inputDecoration({required String label}) {
    const border = BorderSide(color: Color(0xFF243049));
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF64748B)),
      floatingLabelStyle: const TextStyle(color: Color(0xFF3B82F6)),
      filled: true,
      fillColor: const Color(0xFF131C2E),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: border,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: border,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF3B82F6)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: Color(0xFF94A3B8),
      fontSize: 14,
      fontWeight: FontWeight.bold,
    ),
  );
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
  Widget build(BuildContext context) => ChoiceChip(
    label: SizedBox(
      height: 36,
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF94A3B8),
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    ),
    selected: selected,
    onSelected: (value) {
      if (value) onSelected();
    },
    selectedColor: const Color(0xFF2563EB),
    backgroundColor: const Color(0xFF131C2E),
    side: BorderSide(
      color: selected ? const Color(0xFF3B82F6) : const Color(0xFF243049),
      width: 1.5,
    ),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    showCheckmark: false,
  );
}
