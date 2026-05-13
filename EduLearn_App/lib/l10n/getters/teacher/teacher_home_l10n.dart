import '../../core/app_localizations.dart';

extension AppLocalizationsTeacherHome on AppLocalizations {
  String get teacher => getValue('teacher');

  String welcomeBack(String name) {
    return formatValue('welcome_back', {'name': name});
  }

  String get quickAccess => getValue('quick_access');
  String get quickAccessSubtitle => getValue('quick_access_subtitle');
  String get whatsNew => getValue('whats_new');
  String get whatsNewSubtitle => getValue('whats_new_subtitle');
  String get studentsOverview => getValue('students_overview');
  String get studentsOverviewSubtitle => getValue('students_overview_subtitle');
  String get teacherDashboard => getValue('teacher_dashboard');
  String get heroSummaryLocal => getValue('hero_summary_local');
  String get heroSummaryServer => getValue('hero_summary_server');
  String get heroSummaryDefault => getValue('hero_summary_default');
  String get students => getValue('students');
  String get published => getValue('published');
  String get publishedLessons => getValue('published_lessons');
  String get savedDrafts => getValue('saved_drafts');
  String get continueEditing => getValue('continue_editing');
  String get recentLessonsReady => getValue('recent_lessons_ready');
  String get noPublishedLessonsYet => getValue('no_published_lessons_yet');
  String get draftsSavedOnServer => getValue('drafts_saved_on_server');
  String get noSavedDraftsRightNow => getValue('no_saved_drafts_right_now');
  String get localLessonEditsOnDevice => getValue('local_lesson_edits_on_device');
  String get noLocalContinuationFound => getValue('no_local_continuation_found');
  String get performanceOverview => getValue('performance_overview');
  String get performanceOverviewSubtitle {
    return getValue('performance_overview_subtitle');
  }

  String get todaysFocus => getValue('todays_focus');
  String get focusLocal => getValue('focus_local');
  String get focusServer => getValue('focus_server');
  String get focusDefault => getValue('focus_default');
  String get noLessonsAvailable => getValue('no_lessons_available');
  String get couldNotLoadAllHomeData => getValue('could_not_load_all_home_data');
  String get tryAgain => getValue('try_again');
  String get lessonContextNotAvailable => getValue('lesson_context_not_available');
  String get contextIncomplete => getValue('context_incomplete');

  String get thisLessonNotEnoughContext {
    return getValue('this_lesson_not_enough_context');
  }

  String get publishedStatus => getValue('published_status');
  String get serverDraftStatus => getValue('server_draft_status');
  String get localEditStatus => getValue('local_edit_status');
  String get draftStatus => getValue('draft_status');

  String lessonsCount(int count) {
    final key = count == 1 ? 'lessons_count_singular' : 'lessons_count_plural';
    return formatValue(key, {'count': count.toString()});
  }

  String get sampleActivity1Title => getValue('sample_activity_1_title');
  String get sampleActivity1Subtitle => getValue('sample_activity_1_subtitle');
  String get sampleActivity2Title => getValue('sample_activity_2_title');
  String get sampleActivity2Subtitle => getValue('sample_activity_2_subtitle');
  String get sampleActivity3Title => getValue('sample_activity_3_title');
  String get sampleActivity3Subtitle => getValue('sample_activity_3_subtitle');
  String get metricLessonsCompletion => getValue('metric_lessons_completion');
  String get metricExercisesProgress => getValue('metric_exercises_progress');
  String get metricQuizPerformance => getValue('metric_quiz_performance');
}