import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subscription_track/core/theme/app_colors.dart';
import 'package:subscription_track/core/theme/app_theme.dart';
import 'package:subscription_track/features/onboarding/presentation/onboarding_data.dart';
import 'package:subscription_track/features/onboarding/presentation/onboarding_page.dart';

void main() {
  testWidgets('keeps branded-dark text colors under the light app theme', (
    tester,
  ) async {
    final page = onboardingPages.first;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: OnboardingPage(data: page)),
      ),
    );

    final title = tester.widget<Text>(find.text(page.title));
    final subtitle = tester.widget<Text>(find.text(page.subtitle));
    expect(title.style?.color, AppColors.textPrimary);
    expect(subtitle.style?.color, AppColors.textSecondary);
  });
}
