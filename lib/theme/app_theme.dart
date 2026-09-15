import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized application theme and styling for the Arabic Grammar app.
/// Designed specifically for elementary school pupils: high contrast, vibrant yet harmonious
/// colors, rounded playful cards, and elegant Arabic typography using Cairo.
class AppTheme {
  // Brand Palette
  static const Color primaryTeal = Color(0xFF00897B); // Emerald Teal for confidence
  static const Color primaryDark = Color(0xFF004D40);
  static const Color primaryLight = Color(0xFFE0F2F1);
  
  static const Color accentAmber = Color(0xFFFFB300); // Warm Amber for stars/encouragement
  static const Color accentOrange = Color(0xFFFB8C00);
  static const Color accentCoral = Color(0xFFFF7043);
  static const Color accentPurple = Color(0xFF7E57C2);
  static const Color accentBlue = Color(0xFF1E88E5);

  // Linguistic Tag Colors
  static const Color verbColor = Color(0xFF1E88E5); // Blue for Verb (فعل)
  static const Color subjectColor = Color(0xFF43A047); // Green for Subject (فاعل)
  static const Color objectColor = Color(0xFFFB8C00); // Orange for Object (مفعول به)
  static const Color particleColor = Color(0xFF8E24AA); // Purple for Particle (حرف)

  // Backgrounds & Neutrals
  static const Color backgroundLight = Color(0xFFF7FAF9);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF1A2E2B);
  static const Color textMuted = Color(0xFF5A7370);
  static const Color successGreen = Color(0xFF2E7D32);
  static const Color errorRed = Color(0xFFD32F2F);
  static const Color cardShadow = Color(0x14000000);

  /// Light theme definition
  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.cairoTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryTeal,
      scaffoldBackgroundColor: backgroundLight,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryTeal,
        primary: primaryTeal,
        secondary: accentAmber,
        tertiary: accentBlue,
        surface: surfaceWhite,
        error: errorRed,
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: GoogleFonts.cairo(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textDark,
        ),
        displayMedium: GoogleFonts.cairo(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: textDark,
        ),
        titleLarge: GoogleFonts.cairo(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: textDark,
        ),
        titleMedium: GoogleFonts.cairo(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textDark,
        ),
        bodyLarge: GoogleFonts.cairo(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textDark,
          height: 1.6,
        ),
        bodyMedium: GoogleFonts.cairo(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: textMuted,
          height: 1.5,
        ),
        labelLarge: GoogleFonts.cairo(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryTeal,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.cairo(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceWhite,
        elevation: 3,
        shadowColor: cardShadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryTeal,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryTeal,
          side: const BorderSide(color: primaryTeal, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.cairo(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
