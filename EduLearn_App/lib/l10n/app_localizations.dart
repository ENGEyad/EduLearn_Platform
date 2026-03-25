import 'package:flutter/material.dart';

/// Centralized localization stub. In a real app, use `flutter_localizations`
/// and `.arb` files to generate this class automatically.
class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  // Translations Map Stub
  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'settings_title': 'Settings',
      'edit_profile': 'Edit Profile',
      'email_address': 'Email Address',
      'change_password': 'Change Password',
      'notifications': 'Notifications',
      'dark_mode': 'Dark Mode',
      'language': 'Language',
      'logout': 'Logout',
      'confirm_logout': 'Are you sure you want to logout?',
      'cancel': 'Cancel',
      'active_classes': 'Active Classes',
      'assigned_students': 'Total Students',
      'enrolled_courses': 'Enrolled Courses',
      'grade': 'Grade',
    },
    'ar': {
      'settings_title': 'الإعدادات',
      'edit_profile': 'تعديل الملف الشخصي',
      'email_address': 'البريد الإلكتروني',
      'change_password': 'تغيير كلمة المرور',
      'notifications': 'الإشعارات',
      'dark_mode': 'الوضع الليلي',
      'language': 'اللغة',
      'logout': 'تسجيل خروج',
      'confirm_logout': 'هل أنت متأكد من تسجيل الخروج؟',
      'cancel': 'إلغاء',
      'active_classes': 'الفصول النشطة',
      'assigned_students': 'إجمالي الطلاب',
      'enrolled_courses': 'المقررات المسجلة',
      'grade': 'المرحلة الدراسية',
    }
  };

  String get(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();
  @override
  bool isSupported(Locale locale) => ['en', 'ar'].contains(locale.languageCode);
  @override
  Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);
  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
