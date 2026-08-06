import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subscription_track/app/application/theme_mode_controller.dart';
import 'package:subscription_track/core/layout/app_breakpoints.dart';
import 'package:subscription_track/core/theme/app_colors.dart';
import 'package:subscription_track/features/settings/application/notification_reminder_controller.dart';

class SettingsTab extends ConsumerWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reminderEnabled = ref.watch(notificationReminderProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppBreakpoints.settingsMaxWidth,
        ),
        child: ListView(
          key: const PageStorageKey<String>('settings-tab'),
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              clipBehavior: Clip.antiAlias,
              child: SwitchListTile(
                value: reminderEnabled,
                onChanged: (value) => ref
                    .read(notificationReminderProvider.notifier)
                    .update(enabled: value),
                secondary: const Icon(
                  Icons.notifications_active_rounded,
                  color: Color(0xFFA855F7),
                ),
                title: const Text('แจ้งเตือนก่อนตัดเงิน'),
                subtitle: Text(reminderEnabled ? 'เปิดใช้งาน' : 'ปิดอยู่'),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.language_rounded),
                    title: const Text('ภาษา (Language)'),
                    trailing: const Text(
                      'ไทย',
                      style: TextStyle(color: Colors.grey),
                    ),
                    onTap: () => _showComingSoon(context),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.currency_exchange_rounded),
                    title: const Text('สกุลเงินเริ่มต้น'),
                    trailing: const Text(
                      'THB (฿)',
                      style: TextStyle(color: Colors.grey),
                    ),
                    onTap: () => _showComingSoon(context),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: Icon(
                      isDarkMode
                          ? Icons.dark_mode_rounded
                          : Icons.light_mode_rounded,
                    ),
                    title: const Text('โหมดกลางคืน'),
                    subtitle: Text(isDarkMode ? 'เปิดใช้งาน' : 'ปิดอยู่'),
                    value: isDarkMode,
                    onChanged: (value) {
                      ref
                          .read(themeModeProvider.notifier)
                          .setMode(value ? ThemeMode.dark : ThemeMode.light);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                leading: const Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.primaryLight,
                ),
                title: const Text('เกี่ยวกับแอป'),
                subtitle: const Text('Subscription Track v1.0.0'),
                onTap: () => _showComingSoon(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ฟีเจอร์นี้จะเปิดใช้ในเวอร์ชันถัดไป')),
    );
  }
}
