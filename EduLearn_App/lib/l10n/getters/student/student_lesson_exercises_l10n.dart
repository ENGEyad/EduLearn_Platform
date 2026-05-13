import '../../core/app_localizations.dart';

extension StudentLessonExercisesL10n on AppLocalizations {
  String get studentLessonExercisesTitle =>
      getValue('student_lesson_exercises_title');
  String get studentLessonExercisesRefresh =>
      getValue('student_lesson_exercises_refresh');

  String get studentLessonExercisesAnswerOneBeforeSaving =>
      getValue('student_lesson_exercises_answer_one_before_saving');
  String get studentLessonExercisesSavedSuccessfully =>
      getValue('student_lesson_exercises_saved_successfully');
  String get studentLessonExercisesAnswerAllBeforeSubmit =>
      getValue('student_lesson_exercises_answer_all_before_submit');
  String get studentLessonExercisesNothingNewToSubmit =>
      getValue('student_lesson_exercises_nothing_new_to_submit');
  String get studentLessonExercisesSubmittedSuccessfully =>
      getValue('student_lesson_exercises_submitted_successfully');

  String get studentLessonExercisesSubmitAnswersTitle =>
      getValue('student_lesson_exercises_submit_answers_title');
  String get studentLessonExercisesSubmitAnswersMessage =>
      getValue('student_lesson_exercises_submit_answers_message');
  String get studentLessonExercisesCancel =>
      getValue('student_lesson_exercises_cancel');
  String get studentLessonExercisesSubmit =>
      getValue('student_lesson_exercises_submit');

  String get studentLessonExercisesUnsavedChangesTitle =>
      getValue('student_lesson_exercises_unsaved_changes_title');
  String get studentLessonExercisesUnsavedChangesMessage =>
      getValue('student_lesson_exercises_unsaved_changes_message');
  String get studentLessonExercisesStay =>
      getValue('student_lesson_exercises_stay');
  String get studentLessonExercisesLeave =>
      getValue('student_lesson_exercises_leave');

  String get studentLessonExercisesChecked =>
      getValue('student_lesson_exercises_checked');
  String get studentLessonExercisesActionRequired =>
      getValue('student_lesson_exercises_action_required');
  String get studentLessonExercisesInProgress =>
      getValue('student_lesson_exercises_in_progress');
  String get studentLessonExercisesNotSubmitted =>
      getValue('student_lesson_exercises_not_submitted');
  String get studentLessonExercisesMultipleChoice =>
      getValue('student_lesson_exercises_multiple_choice');
  String get studentLessonExercisesTrueFalse =>
      getValue('student_lesson_exercises_true_false');
  String get studentLessonExercisesShortAnswer =>
      getValue('student_lesson_exercises_short_answer');
  String get studentLessonExercisesCorrect =>
      getValue('student_lesson_exercises_correct');
  String get studentLessonExercisesIncorrect =>
      getValue('student_lesson_exercises_incorrect');
  String get studentLessonExercisesNeedsAnswer =>
      getValue('student_lesson_exercises_needs_answer');
  String get studentLessonExercisesLocked =>
      getValue('student_lesson_exercises_locked');
  String get studentLessonExercisesNew =>
      getValue('student_lesson_exercises_new');
  String get studentLessonExercisesUpdated =>
      getValue('student_lesson_exercises_updated');
  String get studentLessonExercisesRestored =>
      getValue('student_lesson_exercises_restored');
  String get studentLessonExercisesRemoved =>
      getValue('student_lesson_exercises_removed');

  String get studentLessonExercisesUnableToLoad =>
      getValue('student_lesson_exercises_unable_to_load');
  String get studentLessonExercisesTryAgain =>
      getValue('student_lesson_exercises_try_again');
  String get studentLessonExercisesNoPublished =>
      getValue('student_lesson_exercises_no_published');
  String get studentLessonExercisesNoPublishedMessage =>
      getValue('student_lesson_exercises_no_published_message');
  String get studentLessonExercisesNoVisibleQuestions =>
      getValue('student_lesson_exercises_no_visible_questions');
  String get studentLessonExercisesNoVisibleQuestionsMessage =>
      getValue('student_lesson_exercises_no_visible_questions_message');

  String studentLessonExercisesScore(String score, String total) {
    return formatValue('student_lesson_exercises_score', {
      'score': score,
      'total': total,
    });
  }

  String get studentLessonExercisesNewChangesAvailable =>
      getValue('student_lesson_exercises_new_changes_available');
  String get studentLessonExercisesCorrectCount =>
      getValue('student_lesson_exercises_correct_count');
  String get studentLessonExercisesWrongCount =>
      getValue('student_lesson_exercises_wrong_count');
  String get studentLessonExercisesTotal =>
      getValue('student_lesson_exercises_total');
  String get studentLessonExercisesUpdatedSetTitle =>
      getValue('student_lesson_exercises_updated_set_title');
  String get studentLessonExercisesUpdatedSetMessage =>
      getValue('student_lesson_exercises_updated_set_message');

  String studentLessonExercisesNewCount(int count) {
    return formatValue('student_lesson_exercises_new_count', {
      'count': count.toString(),
    });
  }

  String studentLessonExercisesUpdatedCount(int count) {
    return formatValue('student_lesson_exercises_updated_count', {
      'count': count.toString(),
    });
  }

  String studentLessonExercisesRemovedCount(int count) {
    return formatValue('student_lesson_exercises_removed_count', {
      'count': count.toString(),
    });
  }

  String studentLessonExercisesKeptCount(int count) {
    return formatValue('student_lesson_exercises_kept_count', {
      'count': count.toString(),
    });
  }

  String studentLessonExercisesPoints(String points) {
    return formatValue('student_lesson_exercises_points', {
      'points': points,
    });
  }

  String get studentLessonExercisesWriteYourAnswer =>
      getValue('student_lesson_exercises_write_your_answer');
  String get studentLessonExercisesTypeAnswerHere =>
      getValue('student_lesson_exercises_type_answer_here');
  String get studentLessonExercisesCorrectAnswer =>
      getValue('student_lesson_exercises_correct_answer');
  String get studentLessonExercisesIncorrectAnswer =>
      getValue('student_lesson_exercises_incorrect_answer');
  String get studentLessonExercisesCorrectAnswerLabel =>
      getValue('student_lesson_exercises_correct_answer_label');
  String get studentLessonExercisesExplanationLabel =>
      getValue('student_lesson_exercises_explanation_label');
  String get studentLessonExercisesAttemptLocked =>
      getValue('student_lesson_exercises_attempt_locked');
  String get studentLessonExercisesSave =>
      getValue('student_lesson_exercises_save');
}
