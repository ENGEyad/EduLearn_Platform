import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EduTheme {
  // =========================
  // Brand Colors
  // =========================
  static const Color primary = Color(0xFF0DA3C6);
  static const Color primaryDark = Color(0xFF0B3A60);

  // =========================
  // Light Theme Colors
  // =========================
  static const Color background = Color(0xFFF5F8FC);
  static const Color surface = Colors.white;
  static const Color cardBackground = Colors.white;
  static const Color textPrimary = primaryDark;
  static const Color textMuted = Color(0xFF8A8FA3);
  static const Color inputBorder = Color(0xFFE1E4F0);

  // =========================
  // Dark Theme Colors
  // =========================
  static const Color darkBackground = Color(0xFF0F1722);
  static const Color darkSurface = Color(0xFF182230);
  static const Color darkCardBackground = Color(0xFF1C2838);
  static const Color darkTextPrimary = Color(0xFFF3F7FF);
  static const Color darkTextMuted = Color(0xFF9EABC0);
  static const Color darkInputBorder = Color(0xFF314156);

  // =========================
  // Shared Helpers
  // =========================
  static BorderRadius get defaultRadius => BorderRadius.circular(16);
  static BorderRadius get buttonRadius => BorderRadius.circular(24);

  static ThemeData light() {
    final base = ThemeData.light();

    return base.copyWith(
      brightness: Brightness.light,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      splashColor: primary.withValues(alpha: 0.08),
      highlightColor: primary.withValues(alpha: 0.04),
      colorScheme: base.colorScheme.copyWith(
        brightness: Brightness.light,
        primary: primary,
        secondary: primary,
        surface: surface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        error: Colors.redAccent,
        onError: Colors.white,
      ),
      textTheme: GoogleFonts.nunitoTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.nunito(color: textPrimary),
        displayMedium: GoogleFonts.nunito(color: textPrimary),
        displaySmall: GoogleFonts.nunito(color: textPrimary),
        headlineLarge: GoogleFonts.nunito(color: textPrimary),
        headlineMedium: GoogleFonts.nunito(color: textPrimary),
        headlineSmall: GoogleFonts.nunito(color: textPrimary),
        titleLarge: GoogleFonts.nunito(
          color: textPrimary,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: GoogleFonts.nunito(
          color: textPrimary,
          fontWeight: FontWeight.w700,
        ),
        titleSmall: GoogleFonts.nunito(
          color: textPrimary,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: GoogleFonts.nunito(
          color: textPrimary,
          fontSize: 16,
        ),
        bodyMedium: GoogleFonts.nunito(
          color: textPrimary,
          fontSize: 14,
        ),
        bodySmall: GoogleFonts.nunito(
          color: textMuted,
          fontSize: 12,
        ),
        labelLarge: GoogleFonts.nunito(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
        labelMedium: GoogleFonts.nunito(
          color: textPrimary,
          fontWeight: FontWeight.w600,
        ),
        labelSmall: GoogleFonts.nunito(
          color: textMuted,
          fontWeight: FontWeight.w600,
        ),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: background,
        foregroundColor: textPrimary,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.nunito(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      cardColor: cardBackground,
      dividerColor: inputBorder,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: defaultRadius,
          borderSide: const BorderSide(color: inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: defaultRadius,
          borderSide: const BorderSide(color: inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: defaultRadius,
          borderSide: const BorderSide(color: primary, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: defaultRadius,
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: defaultRadius,
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.4),
        ),
        hintStyle: GoogleFonts.nunito(
          color: textMuted,
          fontSize: 14,
        ),
        labelStyle: GoogleFonts.nunito(
          color: textPrimary,
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
            borderRadius: buttonRadius,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryDark,
          side: const BorderSide(color: inputBorder),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: defaultRadius,
          ),
          textStyle: GoogleFonts.nunito(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: GoogleFonts.nunito(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primary.withValues(alpha: 0.45);
          }
          return textMuted.withValues(alpha: 0.30);
        }),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primary,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }

  static ThemeData dark() {
    final base = ThemeData.dark();

    return base.copyWith(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      primaryColor: primary,
      splashColor: primary.withValues(alpha: 0.10),
      highlightColor: primary.withValues(alpha: 0.05),
      colorScheme: base.colorScheme.copyWith(
        brightness: Brightness.dark,
        primary: primary,
        secondary: primary,
        surface: darkSurface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: darkTextPrimary,
        error: Colors.redAccent,
        onError: Colors.white,
      ),
      textTheme: GoogleFonts.nunitoTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.nunito(color: darkTextPrimary),
        displayMedium: GoogleFonts.nunito(color: darkTextPrimary),
        displaySmall: GoogleFonts.nunito(color: darkTextPrimary),
        headlineLarge: GoogleFonts.nunito(color: darkTextPrimary),
        headlineMedium: GoogleFonts.nunito(color: darkTextPrimary),
        headlineSmall: GoogleFonts.nunito(color: darkTextPrimary),
        titleLarge: GoogleFonts.nunito(
          color: darkTextPrimary,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: GoogleFonts.nunito(
          color: darkTextPrimary,
          fontWeight: FontWeight.w700,
        ),
        titleSmall: GoogleFonts.nunito(
          color: darkTextPrimary,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: GoogleFonts.nunito(
          color: darkTextPrimary,
          fontSize: 16,
        ),
        bodyMedium: GoogleFonts.nunito(
          color: darkTextPrimary,
          fontSize: 14,
        ),
        bodySmall: GoogleFonts.nunito(
          color: darkTextMuted,
          fontSize: 12,
        ),
        labelLarge: GoogleFonts.nunito(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
        labelMedium: GoogleFonts.nunito(
          color: darkTextPrimary,
          fontWeight: FontWeight.w600,
        ),
        labelSmall: GoogleFonts.nunito(
          color: darkTextMuted,
          fontWeight: FontWeight.w600,
        ),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: darkBackground,
        foregroundColor: darkTextPrimary,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.nunito(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: darkTextPrimary,
        ),
        iconTheme: const IconThemeData(color: darkTextPrimary),
      ),
      cardColor: darkCardBackground,
      dividerColor: darkInputBorder,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: defaultRadius,
          borderSide: const BorderSide(color: darkInputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: defaultRadius,
          borderSide: const BorderSide(color: darkInputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: defaultRadius,
          borderSide: const BorderSide(color: primary, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: defaultRadius,
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: defaultRadius,
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.4),
        ),
        hintStyle: GoogleFonts.nunito(
          color: darkTextMuted,
          fontSize: 14,
        ),
        labelStyle: GoogleFonts.nunito(
          color: darkTextPrimary,
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
            borderRadius: buttonRadius,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkTextPrimary,
          side: const BorderSide(color: darkInputBorder),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: defaultRadius,
          ),
          textStyle: GoogleFonts.nunito(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: GoogleFonts.nunito(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return darkSurface;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primary.withValues(alpha: 0.45);
          }
          return darkTextMuted.withValues(alpha: 0.30);
        }),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkSurface,
        selectedItemColor: primary,
        unselectedItemColor: darkTextMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
}