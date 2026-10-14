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
      actionIconTheme: ActionIconThemeData(
        backButtonIconBuilder: (BuildContext context) => const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
      ),
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
      datePickerTheme: DatePickerThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        dividerColor: Colors.transparent,
        headerBackgroundColor: AppColors.green,
        headerForegroundColor: Colors.white,
        headerHeadlineStyle: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5),
        headerHelpStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70),
        weekdayStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.faintText),
        dayStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        dayShape: const WidgetStatePropertyAll<OutlinedBorder>(StadiumBorder()),
        dayForegroundColor: WidgetStateProperty.resolveWith((Set<WidgetState> s) {
          if (s.contains(WidgetState.selected)) return Colors.white;
          if (s.contains(WidgetState.disabled)) return AppColors.faintText;
          return AppColors.ink;
        }),
        dayBackgroundColor: WidgetStateProperty.resolveWith((Set<WidgetState> s) {
          if (s.contains(WidgetState.selected)) return AppColors.green;
          return Colors.transparent;
        }),
        dayOverlayColor: const WidgetStatePropertyAll<Color>(AppColors.greenTint),
        todayForegroundColor: const WidgetStatePropertyAll<Color>(AppColors.green),
        todayBorder: const BorderSide(color: AppColors.green, width: 1.4),
        rangePickerBackgroundColor: Colors.white,
        rangePickerElevation: 0,
        rangePickerHeaderBackgroundColor: AppColors.green,
        rangePickerHeaderForegroundColor: Colors.white,
        rangePickerHeaderHeadlineStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.3),
        rangePickerHeaderHelpStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70),
        rangeSelectionBackgroundColor: AppColors.greenTint,
        rangePickerShape: const RoundedRectangleBorder(),
        yearStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        cancelButtonStyle: ButtonStyle(
          foregroundColor: const WidgetStatePropertyAll<Color>(AppColors.subtleText),
          textStyle: const WidgetStatePropertyAll<TextStyle>(TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        ),
        confirmButtonStyle: ButtonStyle(
          foregroundColor: const WidgetStatePropertyAll<Color>(AppColors.green),
          textStyle: const WidgetStatePropertyAll<TextStyle>(TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
        ),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        dialBackgroundColor: AppColors.greenTint,
        dialHandColor: AppColors.green,
        hourMinuteColor: WidgetStateColor.resolveWith(
          (Set<WidgetState> s) => s.contains(WidgetState.selected) ? AppColors.greenTint : AppColors.line.withValues(alpha: 0.5),
        ),
        hourMinuteTextColor: WidgetStateColor.resolveWith(
          (Set<WidgetState> s) => s.contains(WidgetState.selected) ? AppColors.green : AppColors.ink,
        ),
        dayPeriodColor: WidgetStateColor.resolveWith(
          (Set<WidgetState> s) => s.contains(WidgetState.selected) ? AppColors.green : Colors.transparent,
        ),
        dayPeriodTextColor: WidgetStateColor.resolveWith(
          (Set<WidgetState> s) => s.contains(WidgetState.selected) ? Colors.white : AppColors.subtleText,
        ),
        entryModeIconColor: AppColors.green,
        helpTextStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.subtleText),
        cancelButtonStyle: ButtonStyle(
          foregroundColor: const WidgetStatePropertyAll<Color>(AppColors.subtleText),
          textStyle: const WidgetStatePropertyAll<TextStyle>(TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        ),
        confirmButtonStyle: ButtonStyle(
          foregroundColor: const WidgetStatePropertyAll<Color>(AppColors.green),
          textStyle: const WidgetStatePropertyAll<TextStyle>(TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        barrierColor: const Color(0x8025333B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        titleTextStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.ink),
        contentTextStyle: const TextStyle(fontSize: 12.5, height: 1.5, color: AppColors.subtleText),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.cream,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: AppColors.cream,
        modalBarrierColor: Color(0x8025333B),
        elevation: 0,
        modalElevation: 0,
        dragHandleColor: Color(0xFFD3DDD9),
        dragHandleSize: Size(38, 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
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
