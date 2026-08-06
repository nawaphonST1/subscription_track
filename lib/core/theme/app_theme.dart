import 'package:flutter/material.dart';
import 'package:subscription_track/core/theme/app_colors.dart';
import 'package:subscription_track/core/theme/app_typography.dart';

class AppTheme {
  AppTheme._();

  static TextTheme _textTheme(Color color) {
    return TextTheme(
      displayLarge: AppTypography.displayLarge.copyWith(color: color),
      displayMedium: AppTypography.displayMedium.copyWith(color: color),

      headlineLarge: AppTypography.headingLarge.copyWith(color: color),
      headlineMedium: AppTypography.headingMedium.copyWith(color: color),
      headlineSmall: AppTypography.headingSmall.copyWith(color: color),

      bodyLarge: AppTypography.bodyLarge.copyWith(color: color),
      bodyMedium: AppTypography.bodyMedium.copyWith(color: color),

      bodySmall: AppTypography.bodySmall.copyWith(
        color: color.withOpacity(.7),
      ),

      labelLarge: AppTypography.labelLarge.copyWith(color: color),

      labelMedium: AppTypography.labelMedium.copyWith(
        color: color.withOpacity(.7),
      ),
    );
  }

  // ==========================
  // LIGHT
  // ==========================

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ),

      textTheme: _textTheme(Colors.black87),

      scaffoldBackgroundColor: const Color(0xffF4F6F9),

      canvasColor: const Color(0xffF4F6F9),

      cardColor: Colors.white,

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        centerTitle: true,
        elevation: 0,
        titleTextStyle: AppTypography.headingMedium.copyWith(
          color: Colors.black87,
        ),
      ),

      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: Color(0xffE5E7EB),
        thickness: 1,
      ),

      listTileTheme: const ListTileThemeData(
        iconColor: Colors.black87,
        textColor: Colors.black87,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade100,

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
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  // ==========================
  // DARK
  // ==========================

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
      ),

      textTheme: _textTheme(AppColors.textPrimary),

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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
      ),

      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.textPrimary,
        textColor: AppColors.textPrimary,
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
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}