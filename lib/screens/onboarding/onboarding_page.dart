import 'package:flutter/material.dart';
import 'package:subscription_track/core/theme/app_typography.dart';
import 'package:subscription_track/screens/onboarding/onboarding_data.dart';

class OnboardingPage extends StatelessWidget {
  final OnboardingPageData data;

  const OnboardingPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(child: Center(child: data.visual)),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: AppTypography.headingLarge,
          ),
          const SizedBox(height: 12),
          Text(
            data.subtitle,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
