import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../translations/teacher/teacher_profile_translations.dart';
import '../translations/teacher/teacher_main_translations.dart';
import '../translations/teacher/teacher_home_translations.dart';
import '../translations/teacher/teacher_classes_translations.dart';
import '../translations/teacher/class_details_translations.dart';
import '../translations/teacher/teacher_messages_translations.dart';
import '../translations/teacher/lesson_builder_translations.dart';
import '../translations/teacher/lesson_exercises_translations.dart';
import '../translations/teacher/teacher_chat_translations.dart';
import '../translations/teacher/teacher_support_center_translations.dart';

import '../translations/teacher/teacher_report_issue_translations.dart';
import '../translations/teacher/teacher_contact_us_translations.dart';
import '../translations/teacher/teacher_faq_translations.dart';
import '../translations/common/splash_translations.dart';
import '../translations/auth/login_translations.dart';


import '../translations/student/student_home_translations.dart';
import '../translations/student/student_main_translations.dart';
import '../translations/student/student_subjects_translations.dart';
import '../translations/student/student_subject_detail_translations.dart';
import '../translations/student/student_lesson_exercises_translations.dart';
import '../translations/student/student_messages_translations.dart';
import '../translations/student/student_chat_translations.dart';
import '../translations/student/student_support_center_translations.dart';
import '../translations/student/student_report_issue_translations.dart';
import '../translations/student/student_faq_translations.dart';
import '../translations/student/student_contact_us_translations.dart';

import '../translations/student/student_lesson_viewer_translations.dart';
import '../translations/student/student_profile_translations.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    final instance = Localizations.of<AppLocalizations>(
      context,
      AppLocalizations,
    );
    assert(instance != null, 'No AppLocalizations found in context');
    return instance!;
  }

  static const supportedLocales = [
    Locale('en'),
    Locale('ar'),
  ];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> localizedValues = {
    'en': {
      ...profileEn,
      ...teacherMainEn,
      ...teacherHomeEn,
      ...teacherClassesEn,
      ...classDetailsEn,
      ...teacherMessagesEn,
      ...teacherChatEn,
      ...lessonBuilderEn,
      // ...existing maps,
      ...lessonExercisesEn,
      ...teacherSupportCenterEn,
...teacherReportIssueEn,
...teacherContactUsEn,
...teacherFaqEn,
 ...splashEn,
  ...loginEn,
      ...studentLessonExercisesEn,
      ...studentMessagesEn,
      ...studentChatEn,
      ...studentSupportCenterEn,
...studentReportIssueEn,
...studentFaqEn,
...studentContactUsEn,
...studentHomeEn,
...studentMainEn,
...studentSubjectsEn,
...studentSubjectDetailEn,
...studentLessonViewerEn,
...studentProfileEn,

    },
    'ar': {
      ...profileAr,
      ...teacherMainAr,
      ...teacherHomeAr,
      ...teacherClassesAr,
      ...classDetailsAr,
      ...teacherMessagesAr,
      ...teacherChatAr,
       ...lessonBuilderAr,
      //  ...existing maps,
  ...lessonExercisesAr,
  ...teacherSupportCenterAr,
...teacherReportIssueAr,
...teacherContactUsAr,
...teacherFaqAr,
...splashAr,
  ...loginAr,
      ...studentLessonExercisesAr,
      ...studentChatAr,
      ...studentSupportCenterAr,
...studentReportIssueAr,
...studentFaqAr,
...studentContactUsAr,
...studentHomeAr,
...studentMainAr,
...studentSubjectsAr,
...studentSubjectDetailAr,
...studentLessonViewerAr,

...studentProfileAr,


    },
  };

  String getValue(String key) {
    return localizedValues[locale.languageCode]?[key] ??
        localizedValues['en']?[key] ??
        key;
  }

  String formatValue(String key, Map<String, String> params) {
    String value = getValue(key);

    for (final entry in params.entries) {
      value = value.replaceAll('{${entry.key}}', entry.value);
    }

    return value;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'ar'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}