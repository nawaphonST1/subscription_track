import 'package:flutter/material.dart';
import 'package:subscription_track/screens/onboarding/onboarding_visuals.dart';

class OnboardingPageData {
  final Widget visual;
  final String title;
  final String subtitle;

  const OnboardingPageData({
    required this.visual,
    required this.title,
    required this.subtitle,
  });
}

final List<OnboardingPageData> onboardingPages = [
  const OnboardingPageData(
    visual: SubscriptionStackVisual(),
    title: 'All Subscriptions\nIn One Smart Hub',
    subtitle: 'Track your active recurring payments effortlessly and take control of your cash flow.',
  ),
  const OnboardingPageData(
    visual: UnusedAlertVisual(),
    title: 'Spot Wasteful Services\n& Save Hundreds',
    subtitle: 'Our smart engine detects subscriptions you no longer watch or use so you stop paying for ghost apps.',
  ),
  const OnboardingPageData(
    visual: RenewalAlertVisual(),
    title: 'Timely Renewal Alerts\nZero Surprise Charges',
    subtitle: 'Receive automated notifications before every billing date, giving you full control over your money.',
  ),
];
