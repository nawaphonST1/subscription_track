import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subscription_track/core/network/network_status.dart';

/// แบนเนอร์แสดงสถานะเครือข่ายและการเชื่อมต่อเซิร์ฟเวอร์
///
/// แสดงผลแบบ Animated ซ่อนเมื่อสถานะ online และจะเลื่อนลงมาแสดงอย่างเด่นชัดเมื่อ:
/// 1. ไม่มีการเชื่อมต่ออินเทอร์เน็ต (noInternet)
/// 2. เซิร์ฟเวอร์กำลังปิดปรับปรุง (serverMaintenance)
/// 3. ไม่สามารถติดต่อเซิร์ฟเวอร์ได้ (serverUnreachable)
class ConnectivityStatusBanner extends ConsumerWidget {
  const ConnectivityStatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivity = ref.watch(networkStatusProvider);
    final notifier = ref.read(networkStatusProvider.notifier);

    if (connectivity.isOnline) {
      return const SizedBox.shrink();
    }

    final isMaintenance = connectivity.isMaintenance;
    final isNoInternet = connectivity.isNoInternet;

    final Color backgroundColor;
    final Color foregroundColor;
    final IconData iconData;
    final String title;
    final String message;

    if (isNoInternet) {
      backgroundColor = const Color(0xFFDC2626); // Red 600
      foregroundColor = Colors.white;
      iconData = Icons.wifi_off_rounded;
      title = 'ไม่มีการเชื่อมต่ออินเทอร์เน็ต';
      message = connectivity.message ??
          'กรุณาเชื่อมต่อ Wi-Fi หรือ Cellular เพื่อใช้งานระบบอย่างต่อเนื่อง';
    } else if (isMaintenance) {
      backgroundColor = const Color(0xFF6366F1); // Indigo 500
      foregroundColor = Colors.white;
      iconData = Icons.construction_rounded;
      title = 'เซิร์ฟเวอร์กำลังปิดปรับปรุง';
      message = connectivity.message ??
          'เซิร์ฟเวอร์กำลังปิดปรับปรุงชั่วคราว กรุณาลองใหม่อีกครั้งในภายหลัง';
    } else {
      backgroundColor = const Color(0xFFD97706); // Amber 600
      foregroundColor = Colors.white;
      iconData = Icons.cloud_off_rounded;
      title = 'ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้';
      message = connectivity.message ??
          'กรุณาตรวจสอบว่าเซิร์ฟเวอร์กำลังทำงานอยู่ หรือลองใหม่อีกครั้ง';
    }

    return Material(
      color: backgroundColor,
      elevation: 3,
      child: SafeArea(
        bottom: false,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(iconData, color: foregroundColor, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: foregroundColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      message,
                      style: TextStyle(
                        color: foregroundColor.withAlpha(230),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (connectivity.isChecking)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
                  ),
                )
              else
                TextButton.icon(
                  onPressed: () => notifier.checkStatus(),
                  icon: Icon(Icons.refresh_rounded, size: 16, color: foregroundColor),
                  label: Text(
                    'ลองใหม่',
                    style: TextStyle(
                      color: foregroundColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white.withAlpha(35),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

bool _isNoInternetDialogShowing = false;

/// แสดงหน้าต่างเด้งเตือน (Dialog) ให้ผู้ใช้เชื่อมต่ออินเทอร์เน็ตก่อนเข้าใช้งาน
Future<void> showNoInternetDialog(BuildContext context, WidgetRef ref) {
  if (_isNoInternetDialogShowing) return Future.value();

  WidgetsBinding.instance.addPostFrameCallback((_) async {
    if (!context.mounted || _isNoInternetDialogShowing) return;
    _isNoInternetDialogShowing = true;
    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (dialogContext) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.wifi_off_rounded, color: Color(0xFFEF4444), size: 28),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'ไม่มีการเชื่อมต่ออินเทอร์เน็ต',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            content: const Text(
              'กรุณาเชื่อมต่อ Wi-Fi หรือ Cellular ก่อนเข้าใช้งาน เพื่อให้สามารถใช้งานระบบและซิงค์ข้อมูลได้อย่างต่อเนื่อง',
              style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('ปิด', style: TextStyle(color: Colors.grey)),
              ),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  ref.read(networkStatusProvider.notifier).checkStatus();
                },
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('ลองใหม่อีกครั้ง'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                ),
              ),
            ],
          );
        },
      );
    } finally {
      _isNoInternetDialogShowing = false;
    }
  });

  return Future.value();
}
