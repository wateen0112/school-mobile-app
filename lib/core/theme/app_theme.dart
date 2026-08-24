import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Apple-style color system matching the eduadmin-dashboard web app.
///
/// Dashboard source: eduadmin-dashboard/src/index.css
class AppTheme {
  // Text
  static const ink = Color(0xff1D1D1F);
  static const muted = Color(0xff86868B);
  static const mutedLight = Color(0xffD2D2D7);

  // Primary blue scale
  static const seed = Color(0xff007AFF);
  static const primary = Color(0xff007AFF);
  static const primaryLight = Color(0xff47A7FF);
  static const primaryLighter = Color(0xff75BDFF);
  static const primaryPale = Color(0xffE8F4FF);

  // Accents
  static const coral = Color(0xffFF9500);     // CTA / secondary accent
  static const coralDark = Color(0xffCC7700);
  static const honey = Color(0xffFF9500);     // warning
  static const mint = Color(0xff34C759);      // success
  static const accentBlue = Color(0xff5AC8FA);
  static const purple = Color(0xffAF52DE);

  // Surfaces
  static const cloud = Color(0xffE8F4FF);
  static const surface = Color(0xffF5F5F7);
  static const cardSurface = Color(0xffffffff);

  // Semantic
  static const success = Color(0xff34C759);
  static const warning = Color(0xffFF9500);
  static const danger = Color(0xffFF3B30);

  // Borders & shadows
  static const borderColor = Color(0xffD2D2D7);
  static const shadowTint = Color(0xff1D1D1F);

  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryLight, primary, Color(0xff0062CC)],
  );

  static const ctaGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [coral, coralDark],
  );

  static const promoGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xffA3D3FF), primary],
  );

  static const pageGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xffFFFFFF), Color(0xffF5F5F7)],
  );

  static ThemeData light(Locale locale) {
    final base = ThemeData(useMaterial3: true, brightness: Brightness.light);
    final textTheme = GoogleFonts.tajawalTextTheme(base.textTheme).apply(
      bodyColor: ink,
      displayColor: ink,
      fontFamilyFallback: const ['Roboto', 'Noto Sans Arabic', 'Arial'],
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seed,
        brightness: Brightness.light,
        primary: primary,
        secondary: coral,
        surface: surface,
        error: danger,
      ),
      scaffoldBackgroundColor: surface,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: ink,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardSurface,
        elevation: 8,
        shadowColor: shadowTint.withValues(alpha: .08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        labelStyle: const TextStyle(color: muted),
        hintStyle: const TextStyle(color: muted),
        prefixIconColor: primary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(64, 48),
          elevation: 8,
          shadowColor: primary.withValues(alpha: .28),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: borderColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: cardSurface,
        selectedColor: primary.withValues(alpha: .16),
        side: const BorderSide(color: borderColor),
        labelStyle: textTheme.labelLarge?.copyWith(
          color: ink,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      dividerTheme: const DividerThemeData(color: borderColor),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ink,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
    );
  }

  static BoxDecoration softPanel({Gradient? gradient, double radius = 28}) {
    return BoxDecoration(
      color: gradient == null ? cardSurface : null,
      gradient: gradient,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: shadowTint.withValues(alpha: .09),
          blurRadius: 30,
          offset: const Offset(0, 18),
        ),
      ],
    );
  }
}
