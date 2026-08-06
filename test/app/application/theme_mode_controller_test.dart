import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subscription_track/app/application/theme_mode_controller.dart';

void main() {
  group('ThemeModeController Unit Tests', () {
    test('default ThemeMode should be ThemeMode.light', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final themeMode = container.read(themeModeProvider);
      expect(themeMode, ThemeMode.light);
    });

    test('setMode updates ThemeMode state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(themeModeProvider.notifier);

      controller.setMode(ThemeMode.dark);
      expect(container.read(themeModeProvider), ThemeMode.dark);

      controller.setMode(ThemeMode.light);
      expect(container.read(themeModeProvider), ThemeMode.light);
    });
  });
}
