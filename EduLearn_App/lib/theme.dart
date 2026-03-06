import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EduTheme {
  // ── Core Palette ──────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF0DA3C6); // teal-blue
  static const Color primaryLight = Color(0xFF3BC4E2);
  static const Color primaryDark = Color(0xFF0B3A60);
  static const Color accent = Color(0xFF7C4DFF); // violet accent
  static const Color accentWarm = Color(0xFFFF6B6B); // coral accent

  static const Color background = Color(0xFFF4F7FC);
  static const Color surfaceWhite = Colors.white;
  static const Color textMuted = Color(0xFF8A8FA3);
  static const Color inputBorder = Color(0xFFE1E4F0);

  // ── Subject Card Palette ──────────────────────────────────────────────────
  static const List<Color> subjectCardColors = [
    Color(0xFF0DA3C6),
    Color(0xFF7C4DFF),
    Color(0xFFFF6B6B),
    Color(0xFF26C97B),
    Color(0xFFFF9F43),
    Color(0xFF54A0FF),
    Color(0xFFEE5A24),
    Color(0xFF00D2D3),
    Color(0xFFF368E0),
    Color(0xFF01CBC6),
    Color(0xFF6C5CE7),
    Color(0xFFFF9FF3),
  ];

  // ── Gradients ─────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0DA3C6), Color(0xFF0B5FBF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF0B3A60), Color(0xFF0DA3C6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF0F5FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF7C4DFF), Color(0xFF3BC4E2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Shadows ───────────────────────────────────────────────────────────────
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: const Color(0xFF0DA3C6).withValues(alpha: 0.08),
      blurRadius: 20,
      offset: const Offset(0, 6),
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> elevatedShadow = [
    BoxShadow(
      color: const Color(0xFF0DA3C6).withValues(alpha: 0.20),
      blurRadius: 32,
      offset: const Offset(0, 12),
    ),
  ];

  // ── Theme ─────────────────────────────────────────────────────────────────
  static ThemeData light() {
    final base = ThemeData.light();
    return base.copyWith(
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: base.colorScheme.copyWith(
        primary: primary,
        secondary: accent,
        surface: surfaceWhite,
      ),
      textTheme: GoogleFonts.nunitoTextTheme(base.textTheme).copyWith(
        bodyMedium: GoogleFonts.nunito(
          color: primaryDark,
          fontSize: 14,
        ),
        bodySmall: GoogleFonts.nunito(
          color: textMuted,
          fontSize: 12,
        ),
        titleLarge: GoogleFonts.nunito(
          color: primaryDark,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
        titleMedium: GoogleFonts.nunito(
          color: primaryDark,
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: background,
        foregroundColor: primaryDark,
        centerTitle: true,
        titleTextStyle: GoogleFonts.nunito(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: primaryDark,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: inputBorder, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: accentWarm, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: accentWarm, width: 1.8),
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
          elevation: 0,
          textStyle: GoogleFonts.nunito(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFEBF5FF),
        labelStyle: GoogleFonts.nunito(
          color: primary,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primary,
        unselectedItemColor: textMuted,
        selectedLabelStyle: GoogleFonts.nunito(
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
        unselectedLabelStyle: GoogleFonts.nunito(
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
        showUnselectedLabels: true,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
