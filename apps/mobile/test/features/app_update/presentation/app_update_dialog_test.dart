import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subscription_track/features/app_update/domain/app_update_info.dart';
import 'package:subscription_track/features/app_update/presentation/app_update_dialog.dart';

void main() {
  group('AppUpdateDialog Widget Tests', () {
    testWidgets('renders optional update dialog with both action buttons', (tester) async {
      const updateInfo = AppUpdateInfo(
        latestVersion: '1.2.0',
        latestBuildNumber: 2,
        minRequiredVersion: '1.0.0',
        minRequiredBuildNumber: 1,
        downloadUrl: 'https://example.com/app.apk',
        releaseNotes: 'Performance fixes',
        forceUpdate: false,
      );

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AppUpdateDialog(
                updateInfo: updateInfo,
                isForceUpdate: false,
              ),
            ),
          ),
        ),
      );

      expect(find.text('พบเวอร์ชันใหม่'), findsOneWidget);
      expect(find.text('v1.2.0'), findsOneWidget);
      expect(find.text('Performance fixes'), findsOneWidget);
      expect(find.text('ไว้คราวหลัง'), findsOneWidget);
      expect(find.text('อัปเดตตอนนี้'), findsOneWidget);
    });

    testWidgets('renders force update dialog without dismiss button', (tester) async {
      const forceUpdateInfo = AppUpdateInfo(
        latestVersion: '2.0.0',
        latestBuildNumber: 5,
        minRequiredVersion: '2.0.0',
        minRequiredBuildNumber: 5,
        downloadUrl: 'https://example.com/app.apk',
        releaseNotes: 'Critical security update',
        forceUpdate: true,
      );

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AppUpdateDialog(
                updateInfo: forceUpdateInfo,
                isForceUpdate: true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('จำเป็นต้องอัปเดต'), findsOneWidget);
      expect(find.text('v2.0.0'), findsOneWidget);
      expect(find.textContaining('ล้าสมัย ไม่สามารถใช้งานต่อได้'), findsOneWidget);
      // Dismiss button must NOT be present in force update
      expect(find.text('ไว้คราวหลัง'), findsNothing);
      expect(find.text('อัปเดตตอนนี้'), findsOneWidget);
    });

    testWidgets('tapping update starts download progress', (tester) async {
      const updateInfo = AppUpdateInfo(
        latestVersion: '1.1.0',
        latestBuildNumber: 2,
        minRequiredVersion: '1.0.0',
        minRequiredBuildNumber: 1,
        downloadUrl: 'https://example.com/app.apk',
        releaseNotes: 'Notes',
      );

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AppUpdateDialog(
                updateInfo: updateInfo,
                isForceUpdate: false,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('อัปเดตตอนนี้'));
      await tester.pump();

      expect(find.text('กำลังดาวน์โหลดแพ็กเกจ APK...'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      // Finish remaining duration
      await tester.pumpAndSettle();
    });
  });
}
