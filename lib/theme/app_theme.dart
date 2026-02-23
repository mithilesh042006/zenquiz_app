import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // ─── Color Tokens ───
  static const Color background = Color(0xFF0A0A0A);
  static const Color surface = Color(0xFF1A1A1A);
  static const Color surfaceLight = Color(0xFF2A2A2A);
  static const Color gold = Color(0xFFFFD700);
  static const Color goldDark = Color(0xFFDAA520);
  static const Color goldLight = Color(0xFFFFF1B0);
  static const Color white = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFFB0B0B0);
  static const Color textDim = Color(0xFF707070);
  static const Color error = Color(0xFFFF4444);
  static const Color success = Color(0xFF4CAF50);
  static const Color correct = Color(0xFF00E676);
  static const Color incorrect = Color(0xFFFF5252);

  // ─── Border Radius ───
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;

  // ─── Spacing ───
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;
  static const double spacingXxl = 48.0;

  // ─── ThemeData ───
  static ThemeData get darkTheme {
    final headingFont = GoogleFonts.outfit();
    final bodyFont = GoogleFonts.inter();

    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: gold,
        onPrimary: background,
        secondary: goldDark,
        onSecondary: background,
        surface: surface,
        onSurface: white,
        error: error,
        onError: white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: headingFont.copyWith(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: white,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: BorderSide(color: surfaceLight.withValues(alpha: 0.5)),
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: spacingMd,
          vertical: spacingSm,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: gold,
        foregroundColor: background,
        elevation: 4,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: gold,
          foregroundColor: background,
          padding: const EdgeInsets.symmetric(
            horizontal: spacingLg,
            vertical: spacingMd,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: bodyFont.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: gold,
          side: const BorderSide(color: gold, width: 1.5),
          padding: const EdgeInsets.symmetric(
            horizontal: spacingLg,
            vertical: spacingMd,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: bodyFont.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: gold,
          textStyle: bodyFont.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: gold, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: error, width: 1.5),
        ),
        hintStyle: bodyFont.copyWith(color: textDim),
        labelStyle: bodyFont.copyWith(color: textMuted),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingMd,
          vertical: spacingMd,
        ),
      ),
      textTheme: TextTheme(
        displayLarge: headingFont.copyWith(
          fontSize: 48,
          fontWeight: FontWeight.w700,
          color: white,
        ),
        displayMedium: headingFont.copyWith(
          fontSize: 36,
          fontWeight: FontWeight.w700,
          color: white,
        ),
        displaySmall: headingFont.copyWith(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: white,
        ),
        headlineLarge: headingFont.copyWith(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: white,
        ),
        headlineMedium: headingFont.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: white,
        ),
        headlineSmall: headingFont.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: white,
        ),
        titleLarge: bodyFont.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: white,
        ),
        titleMedium: bodyFont.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: white,
        ),
        titleSmall: bodyFont.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textMuted,
        ),
        bodyLarge: bodyFont.copyWith(fontSize: 16, color: white),
        bodyMedium: bodyFont.copyWith(fontSize: 14, color: textMuted),
        bodySmall: bodyFont.copyWith(fontSize: 12, color: textDim),
        labelLarge: bodyFont.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: gold,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: surfaceLight,
        thickness: 1,
        space: spacingMd,
      ),
      iconTheme: const IconThemeData(color: textMuted, size: 24),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceLight,
        labelStyle: bodyFont.copyWith(fontSize: 13, color: white),
        selectedColor: gold.withValues(alpha: 0.2),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surface,
        contentTextStyle: bodyFont.copyWith(color: white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
        titleTextStyle: headingFont.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: white,
        ),
      ),
    );
  }
}
