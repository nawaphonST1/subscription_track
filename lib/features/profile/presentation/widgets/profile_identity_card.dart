import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subscription_track/core/theme/app_colors.dart';
import 'package:subscription_track/features/profile/application/personal_info_controller.dart';

class ProfileIdentityCard extends ConsumerWidget {
  const ProfileIdentityCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final personalInfo = ref.watch(personalInfoProvider);
    final theme = Theme.of(context);
    final initialLetter = personalInfo.firstName.isNotEmpty ? personalInfo.firstName[0].toUpperCase() : 'N';

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
              'คุณ${personalInfo.firstName} ${personalInfo.lastName}',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            Text(
              'nay.subtrack@example.com',
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
