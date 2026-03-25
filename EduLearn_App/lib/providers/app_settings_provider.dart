import 'package:flutter/material.dart';
import '../services/local_storage_service.dart';

class AppSettingsProvider extends ChangeNotifier {
  final LocalStorageService _storageService;

  late bool _isDarkMode;
  late Locale _locale;

  AppSettingsProvider(this._storageService) {
    _isDarkMode = _storageService.isDarkMode;
    _locale = Locale(_storageService.languageCode);
  }

  bool get isDarkMode => _isDarkMode;
  Locale get locale => _locale;

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  Future<void> toggleTheme(bool isDark) async {
    _isDarkMode = isDark;
    notifyListeners();
    await _storageService.setDarkMode(isDark);
    _syncPreferenceToServer('isDarkMode', isDark);
  }

  Future<void> setLocale(Locale newLocale) async {
    _locale = newLocale;
    notifyListeners();
    await _storageService.setLanguageCode(newLocale.languageCode);
    _syncPreferenceToServer('language', newLocale.languageCode);
  }

  // Simulated background sync
  Future<void> _syncPreferenceToServer(String key, dynamic value) async {
    // Fire and forget (Background Sync)
    print("Syncing $key: $value to backend...");
    // await ApiService.syncSetting(key, value);
  }
}
