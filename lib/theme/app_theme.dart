import 'package:flutter/material.dart';

/// Centralized application theme optimized for Classroom Lectures & Data Show Projectors.
/// Built specifically for elementary children (7-11 years old) with high-contrast,
/// prominent, and large Arabic typography (Noto Naskh Arabic), bold touch targets, and vibrant color coding.
class AppTheme {
  // Brand Palette - High Visibility on Projectors
  static const Color primaryTeal = Color(0xFF00796B); // Deep Emerald Teal
  static const Color primaryDark = Color(0xFF004D40);
  static const Color primaryLight = Color(0xFFE0F2F1);
  
  static const Color accentAmber = Color(0xFFFF8F00); // High-contrast Amber
  static const Color accentOrange = Color(0xFFEF6C00);
  static const Color accentCoral = Color(0xFFE64A19);
  static const Color accentPurple = Color(0xFF6A1B9A);
  static const Color accentBlue = Color(0xFF0D47A1);

  // Linguistic Tag Colors - Distinct & Vivid for Large Screen Distance Reading
  static const Color verbColor = Color(0xFF1565C0); // Bold Royal Blue for Verb (فعل)
  static const Color subjectColor = Color(0xFF2E7D32); // Deep Forest Green for Subject (فاعل)
  static const Color objectColor = Color(0xFFE65100); // Deep Vibrant Orange for Object (مفعول به)
  static const Color particleColor = Color(0xFF7B1FA2); // Purple for Particle (حرف)

  // Backgrounds & High-Contrast Neutrals (anti-glare for projectors)
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF0F172A); // Ultra-high contrast deep slate
  static const Color textMuted = Color(0xFF334155); // Highly legible secondary text
  static const Color successGreen = Color(0xFF1B5E20);
  static const Color errorRed = Color(0xFFB71C1C);
  static const Color cardShadow = Color(0x1E000000);

  /// Human-readable Arabic labels for available font families.
  static String getFontLabel(String fontFamily) {
    switch (fontFamily) {
      case 'NotoNaskhArabic':
        return 'خط النسخ المدرسي (المعتمد في المناهج والكتب المدرسية - موصى به)';
      case 'ReadexPro':
        return 'خط القراءة التعليمي السلس (Readex Pro - مريح ومبسط للأطفال)';
      case 'Amiri':
        return 'خط النسخ الأصيل (أميري - كلاسيكي شديد الوضوح)';
      case 'Cairo':
        return 'الخط الحديث (Cairo)';
      default:
        return fontFamily;
    }
  }

  /// Default theme using the primary school Naskh font.
  static ThemeData get lightTheme => buildTheme();

  /// Builds application theme with the specified Arabic font family.
  /// Designed specifically for elementary children (7-11 years old) with
  /// crystal-clear diacritical marks (Tashkeel) and high visibility on classroom projectors.
  static ThemeData buildTheme({String fontFamily = 'NotoNaskhArabic'}) {
    final fallbacks = const ['NotoNaskhArabic', 'ReadexPro', 'Amiri', 'Segoe UI', 'Arial'];

    TextStyle makeTextStyle({
      required double fontSize,
      FontWeight fontWeight = FontWeight.normal,
      Color color = textDark,
      double height = 1.6,
      TextDecoration? decoration,
    }) {
      return TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: fallbacks,
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        decoration: decoration,
      );
    }

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryTeal,
      scaffoldBackgroundColor: backgroundLight,
      fontFamily: fontFamily,
      fontFamilyFallback: fallbacks,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryTeal,
        primary: primaryTeal,
        secondary: accentAmber,
        tertiary: verbColor,
        surface: surfaceWhite,
        error: errorRed,
      ),
      textTheme: TextTheme(
        displayLarge: makeTextStyle(
          fontSize: 38,
          fontWeight: FontWeight.bold,
          color: textDark,
          height: 1.45,
        ),
        displayMedium: makeTextStyle(
          fontSize: 30,
          fontWeight: FontWeight.bold,
          color: textDark,
          height: 1.5,
        ),
        titleLarge: makeTextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          color: textDark,
          height: 1.55,
        ),
        titleMedium: makeTextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: textDark,
          height: 1.6,
        ),
        bodyLarge: makeTextStyle(
          fontSize: 21,
          fontWeight: FontWeight.w600,
          color: textDark,
          height: 1.85, // Generous line height ensures zero diacritical clipping
        ),
        bodyMedium: makeTextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: textMuted,
          height: 1.75,
        ),
        labelLarge: makeTextStyle(
          fontSize: 19,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          height: 1.5,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryTeal,
        foregroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        titleTextStyle: makeTextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          height: 1.4,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceWhite,
        elevation: 4,
        shadowColor: cardShadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryTeal,
          foregroundColor: Colors.white,
          elevation: 3,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: makeTextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryTeal,
          side: const BorderSide(color: primaryTeal, width: 2.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: makeTextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: primaryTeal,
          ),
        ),
      ),
    );
  }
}
