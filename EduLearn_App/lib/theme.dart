import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EduTheme {
  const EduTheme._();

  // =========================
  // Brand Colors
  // =========================
  static const Color primary = Color(0xFF2E7D8E);
  static const Color primaryDark = Color(0xFF215F6D);
  static const Color secondary = Color(0xFF637B82);
  static const Color tertiary = Color(0xFF5E799C);

  // =========================
  // Light Theme Colors
  // =========================
  static const Color background = Color(0xFFF3F7F8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1F333A);
  static const Color textMuted = Color(0xFF667D84);
  static const Color inputBorder = Color(0xFFD8E2E5);
  static const Color softPrimaryBackground = Color(0xFFE6F2F4);
  static const Color softSecondaryBackground = Color(0xFFEEF4F6);
  static const Color surfaceContainerLow = Color(0xFFF7FAFB);
  static const Color surfaceContainer = Color(0xFFF0F5F6);
  static const Color surfaceContainerHigh = Color(0xFFE6EEF0);

  // =========================
  // Dark Theme Colors
  // =========================
  static const Color darkBackground = Color(0xFF0E1518);
  static const Color darkSurface = Color(0xFF152026);
  static const Color darkCardBackground = Color(0xFF1A252C);
  static const Color darkSurfaceContainerLow = Color(0xFF182329);
  static const Color darkSurfaceContainer = Color(0xFF1E2A31);
  static const Color darkSurfaceContainerHigh = Color(0xFF25353E);
  static const Color darkTextPrimary = Color(0xFFF2F7F8);
  static const Color darkTextMuted = Color(0xFF93A6AD);
  static const Color darkInputBorder = Color(0xFF2A3941);

  // =========================
  // Semantic Colors
  // =========================
  static const Color success = Color(0xFF2E7D8E);
  static const Color warning = Color(0xFFB9802E);
  static const Color danger = Color(0xFFD95C5C);
  static const Color info = Color(0xFF5E799C);

  // =========================
  // Spacing & Radii
  // =========================
  static const double spaceXs = 6;
  static const double spaceSm = 10;
  static const double spaceMd = 14;
  static const double spaceLg = 18;
  static const double spaceXl = 24;

  static const BorderRadius radiusSmall = BorderRadius.all(Radius.circular(12));
  static const BorderRadius radiusMedium = BorderRadius.all(Radius.circular(16));
  static const BorderRadius radiusLarge = BorderRadius.all(Radius.circular(20));
  static const BorderRadius radiusXL = BorderRadius.all(Radius.circular(24));
  static const BorderRadius radiusPill = BorderRadius.all(Radius.circular(999));

  static BorderRadius get defaultRadius => radiusMedium;
  static BorderRadius get buttonRadius => radiusLarge;
  static BorderRadius get cardRadius => radiusLarge;

  static LinearGradient pageGradient(bool isDark) {
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: isDark
          ? const [darkBackground, Color(0xFF10191D), darkBackground]
          : const [Color(0xFFF7FAFB), background, Color(0xFFEEF4F6)],
    );
  }

  static List<BoxShadow> cardShadow(bool isDark) {
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.07),
        blurRadius: isDark ? 24 : 20,
        offset: const Offset(0, 10),
      ),
    ];
  }

  static List<BoxShadow> subtleShadow(bool isDark) {
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.14 : 0.05),
        blurRadius: isDark ? 16 : 14,
        offset: const Offset(0, 6),
      ),
    ];
  }

  static TextTheme _textTheme(TextTheme base, Color primaryText, Color mutedText) {
    return GoogleFonts.nunitoTextTheme(base).copyWith(
      displayLarge: GoogleFonts.nunito(
        color: primaryText,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
      ),
      displayMedium: GoogleFonts.nunito(
        color: primaryText,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.6,
      ),
      displaySmall: GoogleFonts.nunito(
        color: primaryText,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
      ),
      headlineLarge: GoogleFonts.nunito(
        color: primaryText,
        fontWeight: FontWeight.w800,
      ),
      headlineMedium: GoogleFonts.nunito(
        color: primaryText,
        fontWeight: FontWeight.w800,
      ),
      headlineSmall: GoogleFonts.nunito(
        color: primaryText,
        fontWeight: FontWeight.w800,
      ),
      titleLarge: GoogleFonts.nunito(
        color: primaryText,
        fontSize: 22,
        fontWeight: FontWeight.w800,
        height: 1.15,
      ),
      titleMedium: GoogleFonts.nunito(
        color: primaryText,
        fontSize: 18,
        fontWeight: FontWeight.w800,
        height: 1.2,
      ),
      titleSmall: GoogleFonts.nunito(
        color: primaryText,
        fontSize: 15,
        fontWeight: FontWeight.w700,
        height: 1.2,
      ),
      bodyLarge: GoogleFonts.nunito(
        color: primaryText,
        fontSize: 16,
        fontWeight: FontWeight.w700,
        height: 1.35,
      ),
      bodyMedium: GoogleFonts.nunito(
        color: primaryText,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.35,
      ),
      bodySmall: GoogleFonts.nunito(
        color: mutedText,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.35,
      ),
      labelLarge: GoogleFonts.nunito(
        color: Colors.white,
        fontWeight: FontWeight.w800,
        fontSize: 15,
      ),
      labelMedium: GoogleFonts.nunito(
        color: primaryText,
        fontWeight: FontWeight.w700,
        fontSize: 13,
      ),
      labelSmall: GoogleFonts.nunito(
        color: mutedText,
        fontWeight: FontWeight.w700,
        fontSize: 11,
      ),
    );
  }

  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    final colorScheme = base.colorScheme.copyWith(
      brightness: Brightness.light,
      primary: primary,
      secondary: secondary,
      tertiary: tertiary,
      surface: surface,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: textPrimary,
      error: danger,
      onError: Colors.white,
      outline: inputBorder,
      outlineVariant: inputBorder.withValues(alpha: 0.8),
    );

    return base.copyWith(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      cardColor: cardBackground,
      dividerColor: inputBorder,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      splashColor: primary.withValues(alpha: 0.08),
      highlightColor: primary.withValues(alpha: 0.04),
      textTheme: _textTheme(base.textTheme, textPrimary, textMuted),
      iconTheme: const IconThemeData(color: textPrimary, size: 22),
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: background,
        foregroundColor: textPrimary,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.nunito(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: textPrimary,
        ),
        iconTheme: const IconThemeData(color: textPrimary, size: 22),
      ),
      cardTheme: CardThemeData(
        color: cardBackground,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(borderRadius: radiusLarge),
        shadowColor: Colors.black.withValues(alpha: 0.08),
        surfaceTintColor: Colors.transparent,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        iconColor: textPrimary,
        textColor: textPrimary,
        shape: const RoundedRectangleBorder(borderRadius: radiusMedium),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: const OutlineInputBorder(
          borderRadius: radiusMedium,
          borderSide: BorderSide(color: inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radiusMedium,
          borderSide: BorderSide(color: inputBorder.withValues(alpha: 0.92)),
        ),
        disabledBorder: const OutlineInputBorder(
          borderRadius: radiusMedium,
          borderSide: BorderSide(color: inputBorder),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: radiusMedium,
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: radiusMedium,
          borderSide: BorderSide(color: danger),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: radiusMedium,
          borderSide: BorderSide(color: danger, width: 1.5),
        ),
        hintStyle: GoogleFonts.nunito(
          color: textMuted,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        labelStyle: GoogleFonts.nunito(
          color: textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: primary.withValues(alpha: 0.55),
          disabledForegroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          textStyle: GoogleFonts.nunito(
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
          shape: const RoundedRectangleBorder(borderRadius: radiusLarge),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.nunito(
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
          shape: const RoundedRectangleBorder(borderRadius: radiusLarge),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: BorderSide(color: inputBorder.withValues(alpha: 0.95)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          shape: const RoundedRectangleBorder(borderRadius: radiusMedium),
          textStyle: GoogleFonts.nunito(
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: GoogleFonts.nunito(
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: cardBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(
          borderRadius: radiusLarge,
          side: BorderSide(color: inputBorder.withValues(alpha: 0.95)),
        ),
        textStyle: GoogleFonts.nunito(
          color: textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardBackground,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: radiusXL),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: radiusXL),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primary.withValues(alpha: 0.35);
          }
          return secondary.withValues(alpha: 0.25);
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: textPrimary,
        contentTextStyle: GoogleFonts.nunito(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: radiusMedium),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: softSecondaryBackground,
        selectedColor: softPrimaryBackground,
        disabledColor: inputBorder.withValues(alpha: 0.5),
        labelStyle: GoogleFonts.nunito(
          color: textPrimary,
          fontWeight: FontWeight.w700,
        ),
        secondaryLabelStyle: GoogleFonts.nunito(
          color: primary,
          fontWeight: FontWeight.w800,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: const RoundedRectangleBorder(
          borderRadius: radiusPill,
          side: BorderSide.none,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: textPrimary,
          shape: const RoundedRectangleBorder(borderRadius: radiusMedium),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface.withValues(alpha: 0.98),
        surfaceTintColor: Colors.transparent,
        height: 82,
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.nunito(
            fontSize: 11.5,
            fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
            color: selected ? primary : textMuted,
          );
        }),
        indicatorColor: primary.withValues(alpha: 0.14),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: selected ? 24 : 22,
            color: selected ? primary : textMuted,
          );
        }),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: textMuted,
        selectedLabelStyle: GoogleFonts.nunito(
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
        unselectedLabelStyle: GoogleFonts.nunito(
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
    );
  }

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    final colorScheme = base.colorScheme.copyWith(
      brightness: Brightness.dark,
      primary: primary,
      secondary: secondary,
      tertiary: tertiary,
      surface: darkSurface,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: darkTextPrimary,
      error: danger,
      onError: Colors.white,
      outline: darkInputBorder,
      outlineVariant: darkInputBorder.withValues(alpha: 0.88),
    );

    return base.copyWith(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      primaryColor: primary,
      scaffoldBackgroundColor: darkBackground,
      canvasColor: darkBackground,
      cardColor: darkCardBackground,
      dividerColor: darkInputBorder,
      shadowColor: Colors.black.withValues(alpha: 0.28),
      splashColor: primary.withValues(alpha: 0.10),
      highlightColor: primary.withValues(alpha: 0.05),
      textTheme: _textTheme(base.textTheme, darkTextPrimary, darkTextMuted),
      iconTheme: const IconThemeData(color: darkTextPrimary, size: 22),
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: darkBackground,
        foregroundColor: darkTextPrimary,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.nunito(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: darkTextPrimary,
        ),
        iconTheme: const IconThemeData(color: darkTextPrimary, size: 22),
      ),
      cardTheme: CardThemeData(
        color: darkCardBackground,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(borderRadius: radiusLarge),
        shadowColor: Colors.black.withValues(alpha: 0.28),
        surfaceTintColor: Colors.transparent,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        iconColor: darkTextPrimary,
        textColor: darkTextPrimary,
        shape: const RoundedRectangleBorder(borderRadius: radiusMedium),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: const OutlineInputBorder(
          borderRadius: radiusMedium,
          borderSide: BorderSide(color: darkInputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radiusMedium,
          borderSide: BorderSide(color: darkInputBorder.withValues(alpha: 0.95)),
        ),
        disabledBorder: const OutlineInputBorder(
          borderRadius: radiusMedium,
          borderSide: BorderSide(color: darkInputBorder),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: radiusMedium,
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: radiusMedium,
          borderSide: BorderSide(color: danger),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: radiusMedium,
          borderSide: BorderSide(color: danger, width: 1.5),
        ),
        hintStyle: GoogleFonts.nunito(
          color: darkTextMuted,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        labelStyle: GoogleFonts.nunito(
          color: darkTextPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: primary.withValues(alpha: 0.55),
          disabledForegroundColor: Colors.white.withValues(alpha: 0.92),
          elevation: 0,
          shadowColor: Colors.transparent,
          textStyle: GoogleFonts.nunito(
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
          shape: const RoundedRectangleBorder(borderRadius: radiusLarge),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.nunito(
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
          shape: const RoundedRectangleBorder(borderRadius: radiusLarge),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkTextPrimary,
          side: BorderSide(color: darkInputBorder.withValues(alpha: 0.98)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          shape: const RoundedRectangleBorder(borderRadius: radiusMedium),
          textStyle: GoogleFonts.nunito(
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: GoogleFonts.nunito(
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: darkCardBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.34),
        shape: RoundedRectangleBorder(
          borderRadius: radiusLarge,
          side: BorderSide(color: darkInputBorder.withValues(alpha: 0.98)),
        ),
        textStyle: GoogleFonts.nunito(
          color: darkTextPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: darkCardBackground,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: radiusXL),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: radiusXL),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return darkSurfaceContainerHigh;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primary.withValues(alpha: 0.45);
          }
          return darkTextMuted.withValues(alpha: 0.26);
        }),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: darkSurfaceContainerLow,
        selectedColor: primary.withValues(alpha: 0.16),
        disabledColor: darkInputBorder.withValues(alpha: 0.5),
        labelStyle: GoogleFonts.nunito(
          color: darkTextPrimary,
          fontWeight: FontWeight.w700,
        ),
        secondaryLabelStyle: GoogleFonts.nunito(
          color: primary,
          fontWeight: FontWeight.w800,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: const RoundedRectangleBorder(
          borderRadius: radiusPill,
          side: BorderSide.none,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: darkTextPrimary,
          shape: const RoundedRectangleBorder(borderRadius: radiusMedium),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: darkSurface.withValues(alpha: 0.98),
        surfaceTintColor: Colors.transparent,
        height: 82,
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.24),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.nunito(
            fontSize: 11.5,
            fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
            color: selected ? primary : darkTextMuted,
          );
        }),
        indicatorColor: primary.withValues(alpha: 0.16),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: selected ? 24 : 22,
            color: selected ? primary : darkTextMuted,
          );
        }),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: darkSurface,
        selectedItemColor: primary,
        unselectedItemColor: darkTextMuted,
        selectedLabelStyle: GoogleFonts.nunito(
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
        unselectedLabelStyle: GoogleFonts.nunito(
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
    );
  }
}
