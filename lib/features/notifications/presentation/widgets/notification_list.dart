import 'package:flutter/material.dart';
import 'package:subscription_track/features/notifications/application/notification_center_controller.dart';
import 'package:subscription_track/features/notifications/domain/app_notification.dart';
import 'package:subscription_track/features/notifications/presentation/notification_ui_extensions.dart';

class NotificationList extends StatelessWidget {
  const NotificationList({
    required this.items,
    required this.filter,
    required this.onToggleRead,
    required this.onDismiss,
    super.key,
  });

  final List<AppNotification> items;
  final NotificationFilter filter;
  final ValueChanged<String> onToggleRead;
  final ValueChanged<String> onDismiss;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return _EmptyState(filter: filter);
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        return Dismissible(
          key: Key(item.id),
          direction: DismissDirection.endToStart,
          onDismissed: (_) => onDismiss(item.id),
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFEF4444).withValues(alpha: 0.3),
              ),
            ),
            child: const Icon(
              Icons.delete_outline,
              color: Color(0xFFEF4444),
              size: 24,
            ),
          ),
          child: _NotificationTile(
            item: item,
            onTap: () => onToggleRead(item.id),
          ),
        );
      },
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item, required this.onTap});

  final AppNotification item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = item.accentColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(
            0xFF131C2E,
          ).withValues(alpha: item.isRead ? 0.6 : 1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(
              0xFF243049,
            ).withValues(alpha: item.isRead ? 0.5 : 1),
            width: 1.5,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 16,
              child: item.isRead
                  ? null
                  : Padding(
                      padding: const EdgeInsets.only(top: 6, right: 8),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Icon(item.icon, color: accent, size: 22),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      color: item.isRead
                          ? const Color(0xFF94A3B8)
                          : Colors.white,
                      fontWeight: item.isRead
                          ? FontWeight.normal
                          : FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.body,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formatNotificationDate(item.scheduledAt),
                    style: const TextStyle(
                      color: Color(0xFF475569),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filter});

  final NotificationFilter filter;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.notifications_off_outlined,
            size: 56,
            color: Color(0x9964748B),
          ),
          const SizedBox(height: 20),
          const Text(
            'ไม่มีการแจ้งเตือน',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            filter == NotificationFilter.all
                ? 'ไม่มีการแจ้งเตือนใหม่ในขณะนี้'
                : 'ไม่มีรายการตามตัวกรองที่เลือก',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
          ),
        ],
      ),
    );
  }
}
