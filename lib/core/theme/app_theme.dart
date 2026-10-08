import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get light {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: AppColors.green,
      primary: AppColors.green,
      secondary: AppColors.ink,
      error: AppColors.red,
      surface: AppColors.cream,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.cream,
      fontFamily: 'Roboto',
      splashFactory: InkRipple.splashFactory,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: AppColors.ink,
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontSize: 25,
          letterSpacing: -0.7,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
        titleLarge: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
        titleMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          color: AppColors.ink,
        ),
        bodyMedium: TextStyle(fontSize: 12, color: AppColors.ink),
        bodySmall: TextStyle(fontSize: 10, color: AppColors.muted),
        labelSmall: TextStyle(
          fontSize: 10,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w800,
          color: AppColors.subtleText,
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        contentTextStyle: TextStyle(color: Colors.white, fontSize: 12),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.green,
      ),
      datePickerTheme: const DatePickerThemeData(
        backgroundColor: AppColors.cream,
      ),
      timePickerTheme: const TimePickerThemeData(
        backgroundColor: AppColors.cream,
      ),
    );
  }

  /// Section eyebrow: `WHAT THIS IS`.
  static const TextStyle eyebrow = TextStyle(
    fontSize: 10,
    letterSpacing: 1.2,
    fontWeight: FontWeight.w800,
    color: AppColors.subtleText,
  );

  static const TextStyle rowTitle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
  );

  static const TextStyle rowSubtitle = TextStyle(
    fontSize: 10,
    color: Color(0xFF8A9693),
  );
}
