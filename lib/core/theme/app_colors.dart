import 'package:flutter/material.dart';

/// Colour tokens lifted 1:1 from the CDS workforce design system.
class AppColors {
  const AppColors._();

  static const Color ink = Color(0xFF25333B);
  static const Color green = Color(0xFF1E9E71);
  static const Color deep = Color(0xFF0F7A56);
  static const Color cream = Color(0xFFF7FBF9);
  static const Color peach = Color(0xFFDFF2EA);
  static const Color red = Color(0xFFDD4F45);
  static const Color amber = Color(0xFFDD9142);
  static const Color line = Color(0xFFE4ECE9);
  static const Color muted = Color(0xFF8B9795);
  static const Color blue = Color(0xFF557D8C);
  // Task category pill (2026-10-08 part B): Support.
  static const Color purple = Color(0xFF7A6FB0);

  // Surface tints used by cards, chips and icon wells.
  static const Color greenTint = Color(0xFFDDF3E9);
  static const Color amberTint = Color(0xFFFFF0DD);
  static const Color blueTint = Color(0xFFE4F0F2);
  static const Color redTint = Color(0xFFFBD8D4);
  static const Color purpleTint = Color(0xFFE8E4F5);
  static const Color lateRow = Color(0xFFFFF0EE);
  static const Color lateRowBorder = Color(0xFFF8D6D2);
  static const Color geoChipBg = Color(0xFFE9F7F0);

  static const Color subtleText = Color(0xFF86918F);
  static const Color faintText = Color(0xFFA0AAA7);

  /// The clean white/green-tinted backdrop behind every screen, echoing the
  /// CDS logo's white background with a whisper of brand green.
  static const LinearGradient appBackground = LinearGradient(
    begin: Alignment(-0.6, -1),
    end: Alignment(0.6, 1),
    colors: <Color>[Color(0xFFFFFFFF), cream, peach],
    stops: <double>[0, 0.55, 1],
  );

  /// Frosted white card fill.
  static const LinearGradient cardFill = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xEBFFFFFF), Color(0xBDFFFFFF)],
  );

  static const Color cardSolid = Color(0xC7FFFFFF);
  static const Color cardSoft = Color(0x99FFFFFF);

  static List<BoxShadow> get softShadow => const <BoxShadow>[
    BoxShadow(
      color: Color(0x1925333B),
      blurRadius: 32,
      offset: Offset(0, 15),
    ),
  ];

  static List<BoxShadow> get tinyShadow => const <BoxShadow>[
    BoxShadow(
      color: Color(0x1225333B),
      blurRadius: 18,
      offset: Offset(0, 8),
    ),
  ];
}
