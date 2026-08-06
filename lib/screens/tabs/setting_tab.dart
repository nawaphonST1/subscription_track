import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subscription_track/core/layout/app_breakpoints.dart';
import 'package:subscription_track/core/theme/app_colors.dart';
import 'package:subscription_track/providers/main_navigation_provider.dart';
import 'package:subscription_track/providers/theme_provider.dart';

class SettingTab extends ConsumerWidget {
  const SettingTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reminderEnabled = ref.watch(notificationReminderProvider);
    final themeMode = ref.watch(themeProvider);
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
            // ==========================
            // การแจ้งเตือน
            // ==========================
            Card(
              clipBehavior: Clip.antiAlias,
              child: SwitchListTile(
                secondary: const Icon(
                  Icons.notifications_active_rounded,
                  color: Color(0xFFA855F7),
                ),
                title: const Text('แจ้งเตือนก่อนตัดเงิน'),
                subtitle: Text(
                  reminderEnabled ? 'เปิดใช้งาน' : 'ปิดอยู่',
                ),
                value: reminderEnabled,
                onChanged: (value) {
                  ref
                      .read(notificationReminderProvider.notifier)
                      .update(enabled: value);
                },
              ),
            ),

            const SizedBox(height: 16),

            // ==========================
            // การตั้งค่าทั่วไป
            // ==========================
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
                    onTap: () {
                      // TODO: เปลี่ยนภาษา
                    },
                  ),

                  const Divider(height: 1),

                  ListTile(
                    leading: const Icon(Icons.currency_exchange_rounded),
                    title: const Text('สกุลเงินเริ่มต้น'),
                    trailing: const Text(
                      'THB (฿)',
                      style: TextStyle(color: Colors.grey),
                    ),
                    onTap: () {
                      // TODO: เปลี่ยนสกุลเงิน
                    },
                  ),

                  const Divider(height: 1),

                  SwitchListTile(
                    secondary: Icon(
                      isDarkMode
                          ? Icons.dark_mode_rounded
                          : Icons.light_mode_rounded,
                    ),
                    title: const Text('โหมดกลางคืน'),
                    subtitle: Text(
                      isDarkMode ? 'เปิดใช้งาน' : 'ปิดอยู่',
                    ),
                    value: isDarkMode,
                    onChanged: (value) {
                      ref.read(themeProvider.notifier).setTheme(value);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ==========================
            // เกี่ยวกับแอป
            // ==========================
            Card(
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                leading: const Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.primaryLight,
                ),
                title: const Text('เกี่ยวกับแอป'),
                subtitle: const Text('Subscription Track v1.0.0'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  // TODO: เปิดหน้า About
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}