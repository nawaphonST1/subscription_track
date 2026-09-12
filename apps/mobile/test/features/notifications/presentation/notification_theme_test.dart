import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subscription_track/core/theme/app_theme.dart';
import 'package:subscription_track/features/notifications/application/notification_center_controller.dart';
import 'package:subscription_track/features/notifications/domain/app_notification.dart';
import 'package:subscription_track/features/notifications/presentation/widgets/notification_list.dart';

Widget _lightApp(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(body: child),
);

void main() {
  testWidgets('unread notification title uses readable light-theme text', (
    tester,
  ) async {
    await tester.pumpWidget(
      _lightApp(
        NotificationList(
          items: [
            AppNotification(
              id: 'notification-theme-test',
              title: 'แจ้งเตือนทดสอบ',
              body: 'รายละเอียดแจ้งเตือน',
              scheduledAt: DateTime(2026, 8, 7),
            ),
          ],
          filter: NotificationFilter.all,
          onToggleRead: (_) {},
          onDismiss: (_) {},
        ),
      ),
    );

    final title = tester.widget<Text>(find.text('แจ้งเตือนทดสอบ'));
    expect(title.style?.color, isNot(Colors.white));
  });

  testWidgets('empty state uses readable light-theme text', (tester) async {
    await tester.pumpWidget(
      _lightApp(
        NotificationList(
          items: const [],
          filter: NotificationFilter.all,
          onToggleRead: (_) {},
          onDismiss: (_) {},
        ),
      ),
    );

    final title = tester.widget<Text>(find.text('ไม่มีการแจ้งเตือน'));
    expect(title.style?.color, isNot(Colors.white));
  });
}
