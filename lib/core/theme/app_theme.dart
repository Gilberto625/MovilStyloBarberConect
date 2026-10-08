import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Brand tokens from FrontStyloBarberConect docs / Angular panels.
class AppColors {
  AppColors._();

  // Guest / landing
  static const guestBg = Color(0xFF0A100E);
  static const guestCard = Color(0xFF0E1612);
  static const guestCardProduct = Color(0xFF0C120F);

  // Authenticated panels
  static const panelBg = Color(0xFF0D0D0D);
  static const panelCard = Color(0xFF141414);

  static const gold = Color(0xFFD4AF37);
  static const goldDark = Color(0xFFB8941F);
  static const goldSoft = Color(0xFFE2C76B);
  static const onGold = Color(0xFF0A120E);

  static const museum = Color(0xFF718F83);
  static const text = Color(0xFFEBF0E7);
  static const textPanel = Color(0xFFF5F4EF);
  static const ok = Color(0xFF34D66B);
  static const warn = Color(0xFFE2B35A);
  static const crit = Color(0xFFF45B5B);
  static const border = Color(0xFF3D4F49);
}

class AppTheme {
  AppTheme._();

  static ThemeData guest() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.guestBg,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.gold,
        secondary: AppColors.museum,
        surface: AppColors.guestCard,
        onPrimary: AppColors.onGold,
        onSurface: AppColors.text,
        error: AppColors.crit,
      ),
    );
    return _withFonts(base);
  }

  static ThemeData panel() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.panelBg,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.gold,
        secondary: AppColors.museum,
        surface: AppColors.panelCard,
        onPrimary: AppColors.onGold,
        onSurface: AppColors.textPanel,
        error: AppColors.crit,
      ),
    );
    return _withFonts(base);
  }

  static ThemeData _withFonts(ThemeData base) {
    final display = GoogleFonts.frauncesTextTheme(base.textTheme).apply(
      bodyColor: base.colorScheme.onSurface,
      displayColor: base.colorScheme.onSurface,
    );
    final body = GoogleFonts.manropeTextTheme(base.textTheme).apply(
      bodyColor: base.colorScheme.onSurface,
      displayColor: base.colorScheme.onSurface,
    );
    return base.copyWith(
      textTheme: body.copyWith(
        displayLarge: display.displayLarge,
        displayMedium: display.displayMedium,
        displaySmall: display.displaySmall,
        headlineLarge: display.headlineLarge,
        headlineMedium: display.headlineMedium,
        headlineSmall: display.headlineSmall,
        titleLarge: display.titleLarge,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.fraunces(
          color: base.colorScheme.onSurface,
          fontSize: 22,
          fontWeight: FontWeight.w500,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(48, 48),
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.onGold,
          textStyle: GoogleFonts.manrope(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: AppColors.gold,
          side: const BorderSide(color: AppColors.gold),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: base.colorScheme.surface,
        labelStyle: TextStyle(
          color: base.colorScheme.onSurface.withValues(alpha: 0.7),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.gold, width: 1.4),
        ),
      ),
      cardTheme: CardThemeData(
        color: base.colorScheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
    );
  }
}
