import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Legacy color system kept for screens that still import it.
///
/// Updated to match the eduadmin-dashboard Apple-style palette:
///   Primary: #007AFF, Secondary/Warning: #FF9500,
///   Success: #34C759, Danger: #FF3B30,
///   Background: #F5F5F7, Surface: #FFFFFF,
///   Ink: #1D1D1F, Muted: #86868B, Line: #D2D2D7.
class SchoolColors {
  static const background = Color(0xffF5F5F7);
  static const surface = Color(0xffffffff);
  static const primary = Color(0xff007AFF);
  static const primaryDark = Color(0xff0062CC);
  static const secondary = Color(0xffFF9500);
  static const accent = Color(0xffFF9500);
  static const success = Color(0xff34C759);
  static const danger = Color(0xffFF3B30);
  static const ink = Color(0xff1D1D1F);
  static const muted = Color(0xff86868B);
  static const line = Color(0xffD2D2D7);
  static const cardBlue = Color(0xff5AC8FA);
}

class SchoolTheme {
  static ThemeData light(Locale locale) {
    final base = ThemeData(useMaterial3: true, brightness: Brightness.light);
    final textTheme = GoogleFonts.tajawalTextTheme(base.textTheme).apply(
      bodyColor: SchoolColors.ink,
      displayColor: SchoolColors.ink,
      fontFamilyFallback: const ['Roboto', 'Noto Sans Arabic', 'Arial'],
    );

    final scheme = ColorScheme.fromSeed(
      seedColor: SchoolColors.primary,
      brightness: Brightness.light,
      primary: SchoolColors.primary,
      secondary: SchoolColors.secondary,
      surface: SchoolColors.surface,
      error: SchoolColors.danger,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: SchoolColors.background,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: SchoolColors.ink,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: SchoolColors.ink,
        ),
      ),
      cardTheme: const CardThemeData(
        color: SchoolColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: SchoolColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: SchoolColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: SchoolColors.primary, width: 1.4),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          backgroundColor: SchoolColors.primary,
          foregroundColor: Colors.white,
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 8,
          shadowColor: SchoolColors.primary.withValues(alpha: .26),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          foregroundColor: SchoolColors.primary,
          side: const BorderSide(color: SchoolColors.line),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: SchoolColors.primary,
        unselectedItemColor: Color(0xff86868B),
        elevation: 0,
      ),
    );
  }
}

class SchoolGradients {
  static const hero = LinearGradient(
    colors: [Color(0xff47A7FF), Color(0xff007AFF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const promo = LinearGradient(
    colors: [Color(0xff5AC8FA), Color(0xff007AFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const action = LinearGradient(
    colors: [SchoolColors.secondary, SchoolColors.primary],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}
