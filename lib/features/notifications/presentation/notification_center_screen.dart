import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subscription_track/core/theme/app_colors.dart';
import 'package:subscription_track/features/notifications/application/notification_center_controller.dart';
import 'package:subscription_track/features/notifications/presentation/widgets/notification_filter_bar.dart';
import 'package:subscription_track/features/notifications/presentation/widgets/notification_list.dart';

enum _NotificationMenuAction { markAllRead, clearAll }

class NotificationCenterScreen extends ConsumerWidget {
  const NotificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationCenterProvider);
    final controller = ref.read(notificationCenterProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'การแจ้งเตือน',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          if (state.items.isNotEmpty)
            PopupMenuButton<_NotificationMenuAction>(
              icon: const Icon(Icons.more_vert),
              color: theme.cardColor,
              onSelected: (action) => _handleAction(
                context: context,
                controller: controller,
                action: action,
              ),
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: _NotificationMenuAction.markAllRead,
                  child: _MenuItem(
                    icon: Icons.done_all,
                    label: 'อ่านทั้งหมดแล้ว',
                    color: theme.textTheme.bodyLarge?.color ?? Colors.black,
                  ),
                ),
                const PopupMenuItem(
                  value: _NotificationMenuAction.clearAll,
                  child: _MenuItem(
                    icon: Icons.delete_outline,
                    label: 'ล้างทั้งหมด',
                    color: AppColors.danger,
                  ),
                ),
              ],
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            NotificationFilterBar(
              selected: state.filter,
              onSelected: controller.selectFilter,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: NotificationList(
                items: state.visibleItems,
                filter: state.filter,
                onToggleRead: controller.toggleRead,
                onDismiss: (id) {
                  controller.dismiss(id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('ลบการแจ้งเตือนแล้ว')),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleAction({
    required BuildContext context,
    required NotificationCenterController controller,
    required _NotificationMenuAction action,
  }) {
    final message = switch (action) {
      _NotificationMenuAction.markAllRead => 'ทำเครื่องหมายอ่านแล้วทั้งหมด',
      _NotificationMenuAction.clearAll => 'ล้างการแจ้งเตือนทั้งหมดแล้ว',
    };
    switch (action) {
      case _NotificationMenuAction.markAllRead:
        controller.markAllAsRead();
      case _NotificationMenuAction.clearAll:
        controller.clearAll();
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: color, size: 18),
      const SizedBox(width: 8),
      Text(label, style: TextStyle(color: color)),
    ],
  );
}
