import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subscription_track/core/theme/app_colors.dart';
import 'package:subscription_track/features/auth/application/auth_provider.dart'; 
import 'package:subscription_track/features/profile/application/personal_info_controller.dart'; 

class ProfileIdentityCard extends ConsumerWidget {
  const ProfileIdentityCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. ดึงอีเมลจากระบบล็อกอิน (เพราะอีเมลเปลี่ยนไม่ได้)
    final user = ref.watch(authProvider).value; 
    final userEmail = user?.email ?? 'no-email@example.com';

    // 2. ดึงชื่อจากข้อมูลส่วนตัว (เพื่อเวลากดเซฟในฟอร์ม ชื่อตรงนี้จะได้เปลี่ยนตาม)
    final personalInfo = ref.watch(personalInfoProvider);
    final userName = '${personalInfo.firstName} ${personalInfo.lastName}'.trim();
    
    // 3. ใช้ตัวอักษรตัวแรกมาแสดงในวงกลม
    final initialLetter = userName.isNotEmpty ? userName[0].toUpperCase() : 'U';
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 34,
              backgroundColor: AppColors.primary,
              child: Text(
                initialLetter,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'คุณ $userName',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            Text(
              userEmail,
              style: TextStyle(
                color: theme.textTheme.bodySmall?.color,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}