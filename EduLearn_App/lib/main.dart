import 'package:flutter/material.dart';
import 'theme.dart';
import 'app_preferences.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final savedThemeMode = await AppPreferences.getThemeMode();

  runApp(EduLearnApp(initialThemeMode: savedThemeMode));
}

class EduLearnApp extends StatefulWidget {
  final ThemeMode initialThemeMode;

  const EduLearnApp({
    super.key,
    this.initialThemeMode = ThemeMode.light,
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

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.initialThemeMode;
  }

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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EduLearn',
      debugShowCheckedModeBanner: false,
      theme: EduTheme.light(),
      darkTheme: EduTheme.dark(),
      themeMode: _themeMode,
      home: const SplashScreen(),
    );
  }
}