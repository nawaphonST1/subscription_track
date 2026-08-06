import 'package:flutter/material.dart';
import 'package:subscription_track/core/theme/app_colors.dart';

class ProfileSettingsCard extends StatelessWidget {
  const ProfileSettingsCard({
    required this.income,
    required this.onEditIncome,
    required this.onOpenPinSettings,
    super.key,
  });

  final double income;
  final VoidCallback onEditIncome;
  final VoidCallback onOpenPinSettings;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          ListTile(
            key: const Key('profile-income-setting'),
            onTap: onEditIncome,
            leading: const Icon(
              Icons.account_balance_wallet_rounded,
              color: AppColors.primary,
            ),
            title: const Text('รายได้ต่อเดือน'),
            subtitle: const Text('ใช้คำนวณ Creep Risk'),
            trailing: Text(
              '฿${income.toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            key: const Key('pin-setting'),
            onTap: onOpenPinSettings,
            leading: const Icon(Icons.shield_rounded, color: AppColors.warning),
            title: const Text('รหัส PIN ความปลอดภัย'),
            subtitle: const Text('ยังไม่เปิดใช้งานใน MVP'),
            trailing: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}

Future<void> showPinSettingsInfoDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('ตั้งค่ารหัส PIN'),
      content: const Text(
        'ระบบ PIN ยังไม่ถูกเปิดใช้ใน MVP '
        'และจะพัฒนาตาม Security Blueprint เมื่อมี sensitive action',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('เข้าใจแล้ว'),
        ),
      ],
    ),
  );
}
