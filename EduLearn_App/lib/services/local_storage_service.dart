import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static const String _themeKey = 'isDarkMode';
  static const String _localeKey = 'languageCode';

  final SharedPreferences _prefs;

  LocalStorageService(this._prefs);

  static Future<LocalStorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalStorageService(prefs);
  }

  bool get isDarkMode => _prefs.getBool(_themeKey) ?? false;

  Future<void> setDarkMode(bool isDark) async {
    await _prefs.setBool(_themeKey, isDark);
  }

  String get languageCode => _prefs.getString(_localeKey) ?? 'en';

  Future<void> setLanguageCode(String code) async {
    await _prefs.setString(_localeKey, code);
  }
}
