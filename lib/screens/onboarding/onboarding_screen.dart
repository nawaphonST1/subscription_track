import 'package:flutter/material.dart';
import 'package:subscription_track/core/theme/app_colors.dart';
import 'package:subscription_track/core/theme/app_typography.dart';
import 'package:subscription_track/widgets/common/custom_app_bar.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: CustomAppBar(
        title: 'Welcome',
      ),
      body: Center(
        child: Text(
          'Onboarding Screen',
          style: AppTypography.headingMedium,
        ),
      ),
    );
  }
}
