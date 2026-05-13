import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'theme.dart';
import 'app_preferences.dart';
import 'l10n/core/app_localizations.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final savedThemeMode = await AppPreferences.getThemeMode();
  final savedLocale = await AppPreferences.getLocale();

  runApp(EduLearnApp(
    initialThemeMode: savedThemeMode,
    initialLocale: savedLocale,
  ));
}

class EduLearnApp extends StatefulWidget {
  final ThemeMode initialThemeMode;
  final Locale initialLocale;

  const EduLearnApp({
    super.key,
    this.initialThemeMode = ThemeMode.light,
    this.initialLocale = const Locale('en'),
  });

  static EduLearnAppState of(BuildContext context) {
    final state = context.findAncestorStateOfType<EduLearnAppState>();
    assert(state != null, 'No EduLearnApp state found in context');
    return state!;
  }

  @override
  State<EduLearnApp> createState() => EduLearnAppState();
}

class EduLearnAppState extends State<EduLearnApp> {
  late ThemeMode _themeMode;
  late Locale _locale;

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;

  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isArabic => _locale.languageCode == 'ar';

  @override
  void initState() {
    super.initState();
    _themeMode = widget.initialThemeMode;
    _locale = widget.initialLocale;
  }

  // =========================
  // THEME
  // =========================
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;

    setState(() {
      _themeMode = mode;
    });

    await AppPreferences.saveThemeMode(mode);
  }

  Future<void> toggleTheme(bool isDark) async {
    await setThemeMode(isDark ? ThemeMode.dark : ThemeMode.light);
  }

  // =========================
  // LANGUAGE
  // =========================
  Future<void> setLocale(Locale locale) async {
    if (_locale.languageCode == locale.languageCode) return;

    setState(() {
      _locale = locale;
    });

    await AppPreferences.saveLanguageCode(locale.languageCode);
  }

  Future<void> changeLanguage(String code) async {
    await setLocale(Locale(code));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EduLearn',
      debugShowCheckedModeBanner: false,

      // THEME
      theme: EduTheme.light(),
      darkTheme: EduTheme.dark(),
      themeMode: _themeMode,

      // LANGUAGE
      locale: _locale,
      supportedLocales: AppLocalizations.supportedLocales,

      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      home: const SplashScreen(),
    );
  }
}