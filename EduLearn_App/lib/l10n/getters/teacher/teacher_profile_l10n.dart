import '../../core/app_localizations.dart';

extension AppLocalizationsProfile on AppLocalizations {
  String get profile => getValue('profile');
  String get editProfile => getValue('edit_profile');
  String get accountSettings => getValue('account_settings');
  String get manageEmail => getValue('manage_email');
  String get changePassword => getValue('change_password');
  String get notificationPreferences => getValue('notification_preferences');
  String get themeLanguage => getValue('theme_language');
  String get language => getValue('language');
  String get appLanguage => getValue('app_language');
  String get darkMode => getValue('dark_mode');
  String get darkActive => getValue('dark_active');
  String get lightActive => getValue('light_active');
  String get more => getValue('more');
  String get helpSupport => getValue('help_support');
  String get about => getValue('about');
  String get logout => getValue('logout');
  String get logoutTitle => getValue('logout_title');
  String get logoutMessage => getValue('logout_message');
  String get beforeContinue => getValue('before_continue');
  String get logoutHintSession => getValue('logout_hint_session');
  String get logoutHintLogin => getValue('logout_hint_login');
  String get logoutSubtitle => getValue('logout_subtitle');
  String get cancel => getValue('cancel');
  String get teacherAccount => getValue('teacher_account');
  String get english => getValue('english');
  String get arabic => getValue('arabic');
  String get chooseLanguage => getValue('choose_language');
  String get selectLanguage => getValue('select_language');
}