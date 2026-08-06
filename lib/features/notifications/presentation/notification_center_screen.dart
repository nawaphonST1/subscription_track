import 'package:flutter/material.dart';

class NotificationItem {
  final String id;
  final String type; // 'upcoming_bill', 'unused_warning', 'price_change', 'general'
  final String title;
  final String body;
  final DateTime scheduledAt;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.scheduledAt,
    this.isRead = false,
  });
}

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  late List<NotificationItem> _notifications;
  String _selectedFilter = 'ทั้งหมด'; // 'ทั้งหมด', 'ยังไม่ได้อ่าน', 'อ่านแล้ว'

  @override
  void initState() {
    super.initState();
    _notifications = [
      NotificationItem(
        id: '1',
        type: 'upcoming_bill',
        title: 'Netflix กำลังจะต่ออายุในอีก 3 วัน',
        body: 'ยอดชำระ ฿419.00 จะถูกหักอัตโนมัติผ่านบัตรเครดิตของคุณ',
        scheduledAt: DateTime.now().add(const Duration(days: 3)),
        isRead: false,
      ),
      NotificationItem(
        id: '2',
        type: 'unused_warning',
        title: 'Adobe Creative Cloud ไม่ได้ใช้งานมาระยะหนึ่งแล้ว',
        body: 'เราพบว่าคุณไม่ได้เปิดใช้งานบริการนี้เลยในรอบ 30 วันที่ผ่านมา แนะนำให้ยกเลิกเพื่อประหยัด ฿1,200/เดือน',
        scheduledAt: DateTime.now().subtract(const Duration(hours: 4)),
        isRead: false,
      ),
      NotificationItem(
        id: '3',
        type: 'price_change',
        title: 'ChatGPT Plus แจ้งปรับเปลี่ยนราคา',
        body: 'การแจ้งปรับราคาสำหรับสมาชิกนอกอเมริกา เริ่มมีผลในรอบบิลถัดไป',
        scheduledAt: DateTime.now().subtract(const Duration(days: 1)),
        isRead: true,
      ),
      NotificationItem(
        id: '4',
        type: 'upcoming_bill',
        title: 'Spotify Premium จะต่ออายุพรุ่งนี้',
        body: 'เตรียมเงินสำรองในบัญชี ฿139.00 สำหรับรอบบิลถัดไป',
        scheduledAt: DateTime.now().add(const Duration(days: 1)),
        isRead: true,
      ),
      NotificationItem(
        id: '5',
        type: 'general',
        title: 'ยินดีต้อนรับสู่ Subscription Creep Tracker',
        body: 'เริ่มต้นตั้งค่ารายได้และเปิดแจ้งเตือนสิทธิ์เพื่อความปลอดภัยทางการเงินของคุณ',
        scheduledAt: DateTime.now().subtract(const Duration(days: 3)),
        isRead: true,
      ),
    ];
  }

  List<NotificationItem> get _filteredNotifications {
    if (_selectedFilter == 'ยังไม่ได้อ่าน') {
      return _notifications.where((n) => !n.isRead).toList();
    } else if (_selectedFilter == 'อ่านแล้ว') {
      return _notifications.where((n) => n.isRead).toList();
    }
    return _notifications;
  }

  void _markAllAsRead() {
    setState(() {
      for (var n in _notifications) {
        n.isRead = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ทำเครื่องหมายอ่านแล้วทั้งหมดเรียบร้อย'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _clearAll() {
    setState(() {
      _notifications.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ล้างการแจ้งเตือนทั้งหมดเรียบร้อย'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _dismissNotification(int index, String id) {
    setState(() {
      _notifications.removeWhere((n) => n.id == id);
    });
  }

  void _toggleRead(String id) {
    setState(() {
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        _notifications[index].isRead = !_notifications[index].isRead;
      }
    });
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'upcoming_bill':
        return Icons.calendar_month_rounded;
      case 'unused_warning':
        return Icons.warning_amber_rounded;
      case 'price_change':
        return Icons.trending_up_rounded;
      case 'general':
      default:
        return Icons.notifications_none_rounded;
    }
  }

  Color _getColor(String type) {
    switch (type) {
      case 'upcoming_bill':
        return const Color(0xFFF59E0B); // Amber
      case 'unused_warning':
        return const Color(0xFFEF4444); // Red
      case 'price_change':
        return const Color(0xFF8B5CF6); // Purple
      case 'general':
      default:
        return const Color(0xFF3B82F6); // Blue
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now);

    if (difference.inDays == 0) {
      if (date.day == now.day) {
        return 'วันนี้ - ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} น.';
      } else if (date.day == now.add(const Duration(days: 1)).day) {
        return 'พรุ่งนี้ - ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} น.';
      } else {
        return 'เมื่อวานนี้ - ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} น.';
      }
    } else if (difference.inDays > 0 && difference.inDays <= 7) {
      return 'อีก ${difference.inDays} วันข้างหน้า';
    } else if (difference.inDays < 0 && difference.inDays >= -7) {
      return '${difference.inDays.abs()} วันที่แล้ว';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _filteredNotifications;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0F1D),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'การแจ้งเตือน',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_notifications.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (value) {
                if (value == 'read_all') {
                  _markAllAsRead();
                } else if (value == 'clear_all') {
                  _clearAll();
                }
              },
              color: const Color(0xFF131C2E),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'read_all',
                  child: Row(
                    children: [
                      Icon(Icons.done_all, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text('อ่านทั้งหมดแล้ว', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'clear_all',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 18),
                      SizedBox(width: 8),
                      Text('ล้างทั้งหมด', style: TextStyle(color: Color(0xFFEF4444))),
                    ],
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
            // Filter Selector Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  _buildFilterTab('ทั้งหมด'),
                  const SizedBox(width: 8),
                  _buildFilterTab('ยังไม่ได้อ่าน'),
                  const SizedBox(width: 8),
                  _buildFilterTab('อ่านแล้ว'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Notification List
            Expanded(
              child: filteredList.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF131C2E),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF243049)),
                            ),
                            child: Icon(
                              Icons.notifications_off_outlined,
                              size: 48,
                              color: const Color(0xFF64748B).withOpacity(0.6),
                            ),
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
                            _selectedFilter == 'ทั้งหมด'
                                ? 'กล่องข้อความของคุณไม่มีการแจ้งเตือนใหม่ในขณะนี้'
                                : 'ไม่มีรายการแจ้งเตือนตามตัวกรองที่คุณเลือก',
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: filteredList.length,
                      itemBuilder: (context, index) {
                        final item = filteredList[index];
                        final color = _getColor(item.type);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Dismissible(
                            key: Key(item.id),
                            direction: DismissDirection.endToStart,
                            onDismissed: (direction) {
                              _dismissNotification(index, item.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('ลบการแจ้งเตือนแล้ว'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20.0),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFEF4444).withOpacity(0.3),
                                ),
                              ),
                              child: const Icon(
                                Icons.delete_outline,
                                color: Color(0xFFEF4444),
                                size: 24,
                              ),
                            ),
                            child: InkWell(
                              onTap: () => _toggleRead(item.id),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: item.isRead
                                      ? const Color(0xFF131C2E).withOpacity(0.6)
                                      : const Color(0xFF131C2E),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: item.isRead
                                        ? const Color(0xFF243049).withOpacity(0.5)
                                        : const Color(0xFF243049),
                                    width: 1.5,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Unread indicator dot
                                      if (!item.isRead)
                                        Container(
                                          margin: const EdgeInsets.only(top: 6, right: 8),
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: color,
                                            shape: BoxShape.circle,
                                          ),
                                        )
                                      else
                                        const SizedBox(width: 16),
                                      
                                      // Icon
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: color.withOpacity(0.12),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          _getIcon(item.type),
                                          color: color,
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 14),

                                      // Text Contents
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
                                              _formatDate(item.scheduledAt),
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
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTab(String title) {
    final isSelected = _selectedFilter == title;
    return ChoiceChip(
      label: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF94A3B8),
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedFilter = title;
          });
        }
      },
      selectedColor: const Color(0xFF2563EB),
      backgroundColor: const Color(0xFF131C2E),
      side: BorderSide(
        color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFF243049),
        width: 1.5,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      showCheckmark: false,
    );
  }
}
