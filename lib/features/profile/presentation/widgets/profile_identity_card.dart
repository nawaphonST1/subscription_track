import 'package:flutter/material.dart';
import 'package:subscription_track/core/theme/app_colors.dart';

class ProfileIdentityCard extends StatelessWidget {
  const ProfileIdentityCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 34,
              backgroundColor: AppColors.primary,
              child: Text(
                'N',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(height: 10),
            Text(
              'คุณเน',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            Text(
              'nay.subtrack@example.com',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
