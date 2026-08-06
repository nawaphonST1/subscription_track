import 'package:flutter/material.dart';

class LinkedAccountsCard extends StatelessWidget {
  const LinkedAccountsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'บัญชีที่ผูกไว้ (ข้อมูลจำลอง)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          const _LinkedAccountTile(
            icon: Icons.credit_card_rounded,
            color: Color(0xFF10B981),
            name: 'K-Web Shopping Card',
            detail: '**** **** **** 4321',
          ),
          Divider(height: 1, color: theme.dividerColor),
          const _LinkedAccountTile(
            icon: Icons.account_balance_wallet_rounded,
            color: Color(0xFFF59E0B),
            name: 'TrueMoney Wallet',
            detail: '081-XXX-XXXX',
          ),
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
        'จัดการ',
        style: TextStyle(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}
