import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SchoolColors {
  static const background = Color(0xfff4f7ff);
  static const surface = Color(0xffffffff);
  static const primary = Color(0xff5f7cf7);
  static const primaryDark = Color(0xff3149d8);
  static const secondary = Color(0xffff704d);
  static const accent = Color(0xffffc84c);
  static const success = Color(0xff2ecc71);
  static const danger = Color(0xffef5350);
  static const ink = Color(0xff20263a);
  static const muted = Color(0xff7b86a6);
  static const line = Color(0xffdfe5f5);
  static const cardBlue = Color(0xff86a6ff);
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
          backgroundColor: SchoolColors.secondary,
          foregroundColor: Colors.white,
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 8,
          shadowColor: SchoolColors.secondary.withValues(alpha: .26),
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
        selectedItemColor: SchoolColors.secondary,
        unselectedItemColor: Color(0xffa9b5d4),
        elevation: 0,
      ),
    );
  }
}

class SchoolGradients {
  static const hero = LinearGradient(
    colors: [Color(0xff9ab6ff), Color(0xff5368ef)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const promo = LinearGradient(
    colors: [Color(0xff86a6ff), Color(0xff4d62f1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const action = LinearGradient(
    colors: [SchoolColors.secondary, SchoolColors.primary],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}
