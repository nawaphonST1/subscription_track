import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import authProvider ของคุณ
import 'package:subscription_track/features/auth/application/auth_provider.dart';

class LinkedAccountsCard extends ConsumerWidget {
  const LinkedAccountsCard({super.key});

  // ฟังก์ชันแปลงโค้ดสี Hex เป็น Color ของ Flutter
  Color _getColorFromHex(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse(hexColor, radix: 16));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    // ดึงข้อมูล User จากระบบ Auth
    final user = ref.watch(authProvider).value;
    final creditCards = user?.creditCards ?? [];

    // ถ้าไม่มีบัตรเครดิตซ่อน Card นี้ไปเลย หรือจะแสดงข้อความว่างๆ ก็ได้
    if (creditCards.isEmpty) {
      return const SizedBox.shrink(); 
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'บัญชีที่ผูกไว้ (ดึงจาก Auth)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          
          // วนลูปสร้างรายการบัตรเครดิตตามข้อมูลที่มีใน User
          ...creditCards.asMap().entries.map((entry) {
            final index = entry.key;
            final card = entry.value;
            
            return Column(
              children: [
                _LinkedAccountTile(
                  icon: Icons.credit_card_rounded,
                  color: _getColorFromHex(card.cardColor),
                  name: card.bankName,
                  detail: '**** **** **** ${card.last4Digits}',
                ),
                // ใส่เส้นคั่น (Divider) ยกเว้นรายการสุดท้าย
                if (index < creditCards.length - 1)
                  Divider(height: 1, color: theme.dividerColor),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _LinkedAccountTile extends StatelessWidget {
  const _LinkedAccountTile({
    required this.icon,
    required this.color,
    required this.name,
    required this.detail,
  });

  final IconData icon;
  final Color color;
  final String name;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: color),
        ),
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(detail),
      trailing: Text(
        '฿', // ปรับให้เข้ากับบริบทว่านี่คือแหล่งเงิน (หรือจะคงคำว่า 'จัดการ' ไว้ก็ได้)
        style: TextStyle(
          color: color, 
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }
}