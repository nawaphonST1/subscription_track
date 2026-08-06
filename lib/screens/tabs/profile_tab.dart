import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:subscription_track/core/theme/app_colors.dart';
import 'package:subscription_track/providers/app_flow_provider.dart';
import 'package:subscription_track/providers/auth_provider.dart';
import 'package:subscription_track/providers/main_navigation_provider.dart';
import 'package:subscription_track/router/route_constants.dart';

// สมมติว่าคุณมี authNotifierProvider สำหรับจัดการการล็อกอิน
// import 'package:subscription_track/providers/auth_provider.dart';

class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key, required this.onEditIncome});

  final VoidCallback onEditIncome;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final income = ref.watch(userIncomeProvider);

    return ListView(
      key: const PageStorageKey<String>('profile-tab'),
      padding: const EdgeInsets.all(16),
      children: [
        // --- 1. ข้อมูลผู้ใช้ ---
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
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white),
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

        // --- 2. การตั้งค่าระบบ ---
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
            ],
          ),
        ),
        const SizedBox(height: 16),

        // --- 3. บัญชีที่ผูกไว้ (Linked Payment Methods) ---
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'บัญชีที่ผูกไว้ (ดึงข้อมูลอัตโนมัติ)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.credit_card_rounded, color: Color(0xFF10B981)),
                ),
                title: const Text('K-Web Shopping Card', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('**** **** **** 4321'),
                trailing: TextButton(
                  onPressed: () {},
                  child: const Text('จัดการ'),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFFF59E0B)),
                ),
                title: const Text('TrueMoney Wallet', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('081-XXX-XXXX'),
                trailing: TextButton(
                  onPressed: () {},
                  child: const Text('จัดการ'),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 32),

        // --- 4. ปุ่มออกจากระบบ (Logout) ---
        ElevatedButton(
          onPressed: () async {
            ref.read(onboardingProvider.notifier).setCompleted(false);
            await ref.read(authProvider.notifier).logout();

            if (context.mounted) {
              context.go(RouteConstants.onboarding);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEF4444).withOpacity(0.1), // สีแดงโปร่งแสงให้เข้ากับ Dark Theme
            foregroundColor: const Color(0xFFEF4444),
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: const Color(0xFFEF4444).withOpacity(0.5)),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout_rounded),
              SizedBox(width: 8),
              Text(
                'ออกจากระบบ', 
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
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