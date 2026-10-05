import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subscription_track/core/theme/app_colors.dart';
import 'package:subscription_track/features/app_update/application/app_update_controller.dart';
import 'package:subscription_track/features/app_update/domain/app_update_info.dart';

class AppUpdateDialog extends ConsumerWidget {
  const AppUpdateDialog({
    required this.updateInfo,
    this.isForceUpdate = false,
    super.key,
  });

  final AppUpdateInfo updateInfo;
  final bool isForceUpdate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appUpdateControllerProvider);
    final controller = ref.read(appUpdateControllerProvider.notifier);

    return PopScope(
      canPop: !isForceUpdate && !state.isDownloading,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isForceUpdate
                    ? Colors.red.withAlpha(35)
                    : AppColors.primaryLight.withAlpha(35),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isForceUpdate
                    ? Icons.system_security_update_rounded
                    : Icons.new_releases_rounded,
                color: isForceUpdate ? Colors.red : AppColors.primaryLight,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isForceUpdate ? 'จำเป็นต้องอัปเดต' : 'พบเวอร์ชันใหม่',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withAlpha(50),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'เวอร์ชันปัจจุบัน',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        'v${state.currentVersion}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const Icon(Icons.arrow_forward_rounded, color: Colors.grey),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'เวอร์ชันใหม่',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        'v${updateInfo.latestVersion}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isForceUpdate
                              ? Colors.red
                              : AppColors.primaryLight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (updateInfo.releaseNotes.isNotEmpty) ...[
              const Text(
                'บันทึกการเปลี่ยนแปลง (What\'s New):',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  updateInfo.releaseNotes,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (isForceUpdate) ...[
              const Text(
                '⚠️ เวอร์ชันที่คุณใช้งานล้าสมัย ไม่สามารถใช้งานต่อได้ กรุณาอัปเดตเป็นเวอร์ชันล่าสุดเพื่อความปลอดภัย',
                style: TextStyle(fontSize: 12, color: Colors.redAccent),
              ),
              const SizedBox(height: 8),
            ],
            if (state.isDownloading) ...[
              const Text(
                'กำลังดาวน์โหลดแพ็กเกจ APK...',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: state.downloadProgress,
                backgroundColor: Colors.grey.withAlpha(40),
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${(state.downloadProgress * 100).toInt()}%',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ] else if (state.isDownloadCompleted) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_rounded,
                        color: Colors.green, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'ดาวน์โหลดสำเร็จ พร้อมติดตั้ง',
                        style: TextStyle(fontSize: 13, color: Colors.green),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (!isForceUpdate && !state.isDownloading)
            TextButton(
              onPressed: () {
                controller.dismissUpdate();
                Navigator.of(context).pop();
              },
              child: const Text('ไว้คราวหลัง'),
            ),
          ElevatedButton(
            onPressed: state.isDownloading
                ? null
                : () async {
                    await controller.simulateDownloadAndInstall();
                    if (context.mounted && !isForceUpdate) {
                      Navigator.of(context).pop();
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isForceUpdate ? Colors.red : AppColors.primaryLight,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              state.isDownloading
                  ? 'กำลังเตรียมติดตั้ง...'
                  : state.isDownloadCompleted
                      ? 'กดเพื่อติดตั้ง'
                      : 'อัปเดตตอนนี้',
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> show({
    required BuildContext context,
    required AppUpdateInfo updateInfo,
    bool isForceUpdate = false,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: !isForceUpdate,
      builder: (context) => AppUpdateDialog(
        updateInfo: updateInfo,
        isForceUpdate: isForceUpdate,
      ),
    );
  }
}
