import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'theme.dart';
import 'screens/splash_screen.dart';
import 'services/local_storage_service.dart';
import 'providers/app_settings_provider.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storageService = await LocalStorageService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppSettingsProvider(storageService)),
      ],
      child: const EduLearnApp(),
    ),
  );
}

class EduLearnApp extends StatelessWidget {
  const EduLearnApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsProvider>();

    return MaterialApp(
      title: 'EduLearn',
      debugShowCheckedModeBanner: false,
      
      // Theming Setup
      themeMode: settings.themeMode,
      theme: EduTheme.light(),
      darkTheme: EduTheme.dark(), 

      // Localization Setup
      locale: settings.locale,
      supportedLocales: const [Locale('en'), Locale('ar')],
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
