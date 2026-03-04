// ============================================================
// THEME - Futuristic design system inspired by Spotify Wrapped
// Supports: Dark, Light, High Contrast, Large Text
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ---- Color Palette ----
class AppColors {
  AppColors._();

  // Primary neon gradient colors
  static const Color neonRed = Color(0xFFFF2D55);
  static const Color neonOrange = Color(0xFFFF6B35);
  static const Color neonPurple = Color(0xFF7B2FBE);
  static const Color neonBlue = Color(0xFF2979FF);
  static const Color neonCyan = Color(0xFF00E5FF);
  static const Color neonGreen = Color(0xFF00E676);
  static const Color neonPink = Color(0xFFE040FB);

  // Background colors (dark theme)
  static const Color darkBg = Color(0xFF050A1A);
  static const Color darkSurface = Color(0xFF0D1B2A);
  static const Color darkCard = Color(0xFF132133);
  static const Color darkDivider = Color(0xFF1E3A5F);

  // Background colors (light theme)
  static const Color lightBg = Color(0xFFF0F4FF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFE8EFFF);

  // Text colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0C4DE);
  static const Color textMuted = Color(0xFF607D9E);

  // Gradient stops for hero background
  static const List<Color> heroGradient = [
    Color(0xFF050A1A),
    Color(0xFF0A1628),
    Color(0xFF150825),
    Color(0xFF0A1628),
  ];

  // Glassmorphism
  static const Color glassWhite = Color(0x1AFFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);
  static const Color glassBlur = Color(0x0DFFFFFF);

  // High contrast overrides
  static const Color hcBackground = Color(0xFF000000);
  static const Color hcSurface = Color(0xFF1A1A1A);
  static const Color hcText = Color(0xFFFFFF00);
  static const Color hcAccent = Color(0xFF00FF00);
  static const Color hcBorder = Color(0xFFFFFFFF);
}

// ---- Text Styles ----
class AppTextStyles {
  AppTextStyles._();

  static TextStyle displayHero({double scale = 1.0}) =>
      GoogleFonts.montserrat(
        fontSize: 42 * scale,
        fontWeight: FontWeight.w900,
        letterSpacing: -1.5,
        height: 1.1,
        color: AppColors.textPrimary,
      );

  static TextStyle headline1({double scale = 1.0}) =>
      GoogleFonts.montserrat(
        fontSize: 28 * scale,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        color: AppColors.textPrimary,
      );

  static TextStyle headline2({double scale = 1.0}) =>
      GoogleFonts.montserrat(
        fontSize: 22 * scale,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  static TextStyle headline3({double scale = 1.0}) =>
      GoogleFonts.montserrat(
        fontSize: 18 * scale,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle body({double scale = 1.0}) =>
      GoogleFonts.inter(
        fontSize: 14 * scale,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.6,
      );

  static TextStyle bodyBold({double scale = 1.0}) =>
      GoogleFonts.inter(
        fontSize: 14 * scale,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle caption({double scale = 1.0}) =>
      GoogleFonts.inter(
        fontSize: 12 * scale,
        fontWeight: FontWeight.w400,
        color: AppColors.textMuted,
        letterSpacing: 0.4,
      );

  static TextStyle statNumber({double scale = 1.0}) =>
      GoogleFonts.montserrat(
        fontSize: 36 * scale,
        fontWeight: FontWeight.w900,
        color: AppColors.textPrimary,
      );

  static TextStyle button({double scale = 1.0}) =>
      GoogleFonts.montserrat(
        fontSize: 15 * scale,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      );
}

// ---- Theme Data Factory ----
class AppTheme {
  AppTheme._();

  static ThemeData dark({bool highContrast = false, bool largeText = false}) {
    final double textScale = largeText ? 1.2 : 1.0;
    final Color bg = highContrast ? AppColors.hcBackground : AppColors.darkBg;
    final Color surface = highContrast ? AppColors.hcSurface : AppColors.darkSurface;
    final Color primary = highContrast ? AppColors.hcAccent : AppColors.neonRed;
    final Color text = highContrast ? AppColors.hcText : AppColors.textPrimary;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.dark(
        primary: primary,
        secondary: AppColors.neonBlue,
        surface: surface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: text,
        error: AppColors.neonRed,
      ),
      textTheme: _buildTextTheme(text, textScale),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: text,
        titleTextStyle: AppTextStyles.headline3(scale: textScale).copyWith(color: text),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.darkDivider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.darkDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.neonRed, width: 2),
        ),
        labelStyle: AppTextStyles.body(scale: textScale).copyWith(color: AppColors.textMuted),
        hintStyle: AppTextStyles.body(scale: textScale).copyWith(color: AppColors.textMuted),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: AppTextStyles.button(scale: textScale),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: primary.withOpacity(0.3),
        labelStyle: AppTextStyles.caption(scale: textScale).copyWith(color: text),
        side: BorderSide(color: AppColors.darkDivider),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? primary : AppColors.textMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? primary.withOpacity(0.3) : surface,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? primary : Colors.transparent,
        ),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: BorderSide(color: AppColors.textMuted),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    );
  }

  static ThemeData light({bool highContrast = false, bool largeText = false}) {
    final double textScale = largeText ? 1.2 : 1.0;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBg,
      colorScheme: ColorScheme.light(
        primary: AppColors.neonRed,
        secondary: AppColors.neonBlue,
        surface: AppColors.lightSurface,
        onPrimary: Colors.white,
        onSurface: Colors.black87,
      ),
      textTheme: _buildTextTheme(Colors.black87, textScale),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightSurface,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
    );
  }

  static TextTheme _buildTextTheme(Color textColor, double scale) {
    return TextTheme(
      displayLarge: AppTextStyles.displayHero(scale: scale).copyWith(color: textColor),
      headlineLarge: AppTextStyles.headline1(scale: scale).copyWith(color: textColor),
      headlineMedium: AppTextStyles.headline2(scale: scale).copyWith(color: textColor),
      headlineSmall: AppTextStyles.headline3(scale: scale).copyWith(color: textColor),
      bodyLarge: AppTextStyles.bodyBold(scale: scale).copyWith(color: textColor),
      bodyMedium: AppTextStyles.body(scale: scale).copyWith(color: textColor),
      bodySmall: AppTextStyles.caption(scale: scale).copyWith(color: textColor),
      labelLarge: AppTextStyles.button(scale: scale).copyWith(color: textColor),
    );
  }
}

// ---- Gradient Presets ----
class AppGradients {
  AppGradients._();

  static const LinearGradient primary = LinearGradient(
    colors: [AppColors.neonRed, AppColors.neonPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient blue = LinearGradient(
    colors: [AppColors.neonBlue, AppColors.neonCyan],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient success = LinearGradient(
    colors: [AppColors.neonGreen, AppColors.neonCyan],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warning = LinearGradient(
    colors: [AppColors.neonOrange, AppColors.neonRed],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient hero = LinearGradient(
    colors: [Color(0xFF0D1B2A), Color(0xFF150825), Color(0xFF0A1628)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const RadialGradient glowRed = RadialGradient(
    colors: [Color(0x44FF2D55), Color(0x00FF2D55)],
    radius: 0.8,
  );

  static const RadialGradient glowBlue = RadialGradient(
    colors: [Color(0x442979FF), Color(0x002979FF)],
    radius: 0.8,
  );
}
