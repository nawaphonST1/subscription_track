import 'package:flutter/material.dart';
import 'package:subscription_track/core/theme/app_dark_theme.dart';
import 'package:subscription_track/core/theme/app_light_theme.dart';

abstract final class AppTheme {
  static ThemeData get light => buildLightTheme();
  static ThemeData get dark => buildDarkTheme();
}
