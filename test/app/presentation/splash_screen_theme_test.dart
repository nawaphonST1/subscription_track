import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subscription_track/app/presentation/splash_screen.dart';
import 'package:subscription_track/core/theme/app_colors.dart';
import 'package:subscription_track/core/theme/app_theme.dart';

void main() {
  testWidgets('keeps branded-dark contrast under the light app theme', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const SplashScreen()),
    );

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    final title = tester.widget<Text>(find.text('ระบบติดตามการสมัครสมาชิก'));
    expect(scaffold.backgroundColor, AppColors.bgPrimary);
    expect(title.style?.color, Colors.white);
  });
}
