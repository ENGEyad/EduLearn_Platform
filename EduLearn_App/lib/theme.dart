import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EduTheme {
  // الألوان تقريبية مشابهة للتصميم – تقدر تعدلها لاحقًا لو عندك القيم الدقيقة
  static const Color primary = Color(0xFF0DA3C6);      // لون الأزرار الأزرق/تيلي
  static const Color primaryDark = Color(0xFF0B3A60);  // العناوين الداكنة
  static const Color background = Color(0xFFF5F8FC);   // خلفية خفيفة
  static const Color textMuted = Color(0xFF8A8FA3);
  static const Color inputBorder = Color(0xFFE1E4F0);

  static ThemeData light() {
    final base = ThemeData.light();
    return base.copyWith(
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: base.colorScheme.copyWith(
        primary: primary,
        secondary: primary,
      ),
      textTheme: GoogleFonts.nunitoTextTheme(
        base.textTheme,
      ).copyWith(
        bodyMedium: GoogleFonts.nunito(
          color: primaryDark,
          fontSize: 14,
        ),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: background,
        foregroundColor: primaryDark,
        centerTitle: true,
        titleTextStyle: GoogleFonts.nunito(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: primaryDark,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primary, width: 1.4),
        ),
        hintStyle: GoogleFonts.nunito(
          color: textMuted,
          fontSize: 14,
        ),
        labelStyle: GoogleFonts.nunito(
          color: primaryDark,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.nunito(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
    );
  }
}
