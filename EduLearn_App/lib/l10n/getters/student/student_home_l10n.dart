import '../../core/app_localizations.dart';

extension StudentHomeL10n on AppLocalizations {
  String get studentHomeStudentFallback => getValue('student_home_student_fallback');
  String get studentHomeOverview => getValue('student_home_overview');
  String get studentHomeOverviewSubtitle => getValue('student_home_overview_subtitle');
  String get studentHomeOverallProgress => getValue('student_home_overall_progress');
  String get studentHomeLatestUpdates => getValue('student_home_latest_updates');
  String get studentHomeLatestUpdatesSubtitle => getValue('student_home_latest_updates_subtitle');
  String get studentHomeRecommendedForYou => getValue('student_home_recommended_for_you');
  String get studentHomeRecommendedSubtitle => getValue('student_home_recommended_subtitle');

  String get studentHomeNewLessonPublished => getValue('student_home_new_lesson_published');
  String get studentHomeLessonUpdated => getValue('student_home_lesson_updated');
  String get studentHomeNewExercisesPublished => getValue('student_home_new_exercises_published');
  String get studentHomeExercisesUpdated => getValue('student_home_exercises_updated');
  String get studentHomeLessonCompleted => getValue('student_home_lesson_completed');
  String get studentHomeExerciseSubmitted => getValue('student_home_exercise_submitted');
  String get studentHomeLearningUpdate => getValue('student_home_learning_update');
  String get studentHomeCheckLatestUpdates => getValue('student_home_check_latest_updates');

  String get studentHomeJustNow => getValue('student_home_just_now');

  String studentHomeMinutesAgo(int count) {
    return formatValue('student_home_minutes_ago', {'count': count.toString()});
  }

  String studentHomeHoursAgo(int count) {
    return formatValue('student_home_hours_ago', {'count': count.toString()});
  }

  String studentHomeDaysAgo(int count) {
    return formatValue('student_home_days_ago', {'count': count.toString()});
  }

  String get studentHomeLoadingProgress => getValue('student_home_loading_progress');
  String get studentHomeProgressRefreshConnection => getValue('student_home_progress_refresh_connection');
  String get studentHomeStartLessonsBuildProgress => getValue('student_home_start_lessons_build_progress');

  String studentHomeProgressAcrossSubjects(
    int subjects,
    int lessons,
    int exercises,
  ) {
    return formatValue('student_home_progress_across_subjects', {
      'subjects': subjects.toString(),
      'lessons': lessons.toString(),
      'exercises': exercises.toString(),
    });
  }

  String get studentHomeNoNewUpdatesYet => getValue('student_home_no_new_updates_yet');
  String get studentHomeKeepItUp => getValue('student_home_keep_it_up');

  String get studentHomeOngoingLesson => getValue('student_home_ongoing_lesson');
  String get studentHomePhotosynthesisLesson => getValue('student_home_photosynthesis_lesson');
  String get studentHomeLessonProgress75 => getValue('student_home_lesson_progress_75');
  String get studentHomeContinueLearning => getValue('student_home_continue_learning');

  String get studentHomeExploreRomanEmpire => getValue('student_home_explore_roman_empire');
  String get studentHomeExpandHistoricalKnowledge => getValue('student_home_expand_historical_knowledge');
  String get studentHomePracticeAdvancedAlgebra => getValue('student_home_practice_advanced_algebra');
  String get studentHomeAlgebraPracticeSubtitle => getValue('student_home_algebra_practice_subtitle');
}
