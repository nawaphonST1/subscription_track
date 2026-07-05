import 'package:flutter/material.dart';

class SavingSimulationCard extends StatelessWidget {
  final double monthlySavings;
  final double yearlySavings;
  final VoidCallback onCancelAllAlerted;

  const SavingSimulationCard({
    super.key,
    required this.monthlySavings,
    required this.yearlySavings,
    required this.onCancelAllAlerted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF131C2E), // Card background
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF243049), // Subtle dark borders
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          const Text(
            'เป้าหมายการประหยัด (Saving Simulation)',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          // Monthly Savings Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'เงินประหยัดได้ต่อเดือน:',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 14,
                ),
              ),
              Text(
                '฿${monthlySavings.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Color(0xFF10B981), // Emerald green
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Yearly Savings Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'เงินประหยัดได้ต่อปี:',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 14,
                ),
              ),
              Text(
                '฿${yearlySavings.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Color(0xFF10B981), // Emerald green
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Divider
          Container(
            height: 1,
            color: const Color(0xFF243049),
          ),
          const SizedBox(height: 20),

          // Tip / Financial Knowledge
          const Text(
            'ความรู้ทางการเงิน: Creep เกิดขึ้นตอนชำระเงินตัดอัตโนมัติทีละน้อย แต่รวมกันกลายเป็น 10-20% ของรายได้ต่อเดือน! แนะนำให้ยกเลิกโปรแกรมที่ไม่ได้เปิดใช้งานเกิน 60 วัน',
            style: TextStyle(
              color: Color(0xFF64748B), // Slate/Grey text
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),

          // Action Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: onCancelAllAlerted,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB), // Accent blue
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              icon: const Icon(
                Icons.auto_awesome, // Magic wand-like icon
                size: 18,
              ),
              label: const Text(
                'ยกเลิกรายการแจ้งเตือนทั้งหมด',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
