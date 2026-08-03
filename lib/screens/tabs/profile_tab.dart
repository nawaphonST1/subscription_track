import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subscription_track/core/theme/app_colors.dart';
import 'package:subscription_track/providers/main_navigation_provider.dart';

class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key, required this.onEditIncome});

  final VoidCallback onEditIncome;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final income = ref.watch(userIncomeProvider);
    final reminderEnabled = ref.watch(notificationReminderProvider);

    return ListView(
      key: const PageStorageKey<String>('profile-tab'),
      padding: const EdgeInsets.all(16),
      children: [
        const Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    'N',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'คุณเน',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                Text(
                  'nay.subtrack@example.com',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
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
                onTap: () => _showPinSettings(context),
                leading: const Icon(
                  Icons.shield_rounded,
                  color: AppColors.warning,
                ),
                title: const Text('รหัส PIN ความปลอดภัย'),
                subtitle: const Text('ใช้ยืนยันก่อนยกเลิกบริการ'),
                trailing: const Icon(Icons.chevron_right_rounded),
              ),
              const Divider(height: 1),
              SwitchListTile(
                key: const Key('notification-reminder-setting'),
                value: reminderEnabled,
                onChanged: (enabled) => ref
                    .read(notificationReminderProvider.notifier)
                    .update(enabled: enabled),
                secondary: const Icon(
                  Icons.notifications_active_rounded,
                  color: Color(0xFFA855F7),
                ),
                title: const Text('แจ้งเตือนก่อนตัดเงิน'),
                subtitle: Text(reminderEnabled ? 'ล่วงหน้า 3 วัน' : 'ปิดอยู่'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showPinSettings(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ตั้งค่ารหัส PIN'),
        content: const Text(
          'การเปลี่ยน PIN จะเชื่อมกับระบบความปลอดภัยเมื่อ backend พร้อมใช้งาน',
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
}
