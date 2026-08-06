import 'package:flutter/material.dart';
import 'package:subscription_track/core/theme/app_colors.dart';
import 'package:subscription_track/core/theme/app_typography.dart';

TextTheme _buildDarkTextTheme() {
  const color = AppColors.textPrimary;
  return TextTheme(
    displayLarge: AppTypography.displayLarge.copyWith(color: color),
    displayMedium: AppTypography.displayMedium.copyWith(color: color),
    headlineLarge: AppTypography.headingLarge.copyWith(color: color),
    headlineMedium: AppTypography.headingMedium.copyWith(color: color),
    headlineSmall: AppTypography.headingSmall.copyWith(color: color),
    bodyLarge: AppTypography.bodyLarge.copyWith(color: color),
    bodyMedium: AppTypography.bodyMedium.copyWith(color: color),
    bodySmall: AppTypography.bodySmall.copyWith(
      color: color.withValues(alpha: 0.7),
    ),
    labelLarge: AppTypography.labelLarge.copyWith(color: color),
    labelMedium: AppTypography.labelMedium.copyWith(
      color: color.withValues(alpha: 0.7),
    ),
  );
}

ThemeData buildDarkTheme() {
  const colorScheme = ColorScheme.dark(
    primary: AppColors.primary,
    secondary: AppColors.primaryLight,
    surface: AppColors.bgSecondary,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: AppColors.textPrimary,
    error: AppColors.danger,
    onError: Colors.white,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: colorScheme,
    textTheme: _buildDarkTextTheme(),
    scaffoldBackgroundColor: AppColors.bgPrimary,
    canvasColor: AppColors.bgPrimary,
    cardColor: AppColors.bgSecondary,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bgSecondary,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: true,
    ),
    cardTheme: CardThemeData(
      color: AppColors.bgSecondary,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.divider,
      thickness: 1,
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: AppColors.textPrimary,
      textColor: AppColors.textPrimary,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.bgTertiary,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.danger, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.bgSecondary,
      modalBackgroundColor: AppColors.bgSecondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.bgSecondary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
}
