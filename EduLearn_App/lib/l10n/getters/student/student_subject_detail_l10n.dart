import '../../core/app_localizations.dart';

extension StudentSubjectDetailL10n on AppLocalizations {
  String get studentSubjectDetailYourTeacher {
    return getValue('student_subject_detail_your_teacher');
  }

  String get studentSubjectDetailLessons {
    return getValue('student_subject_detail_lessons');
  }

  String get studentSubjectDetailLesson {
    return getValue('student_subject_detail_lesson');
  }

  String studentSubjectDetailLessonCount(int count) {
    final key = count == 1
        ? 'student_subject_detail_lesson_count_singular'
        : 'student_subject_detail_lesson_count_plural';

    return formatValue(key, {'count': count.toString()});
  }

  String get studentSubjectDetailErrorLoadingLessons {
    return getValue('student_subject_detail_error_loading_lessons');
  }

  String get studentSubjectDetailRetry {
    return getValue('student_subject_detail_retry');
  }

  String get studentSubjectDetailNoLessonsAvailable {
    return getValue('student_subject_detail_no_lessons_available');
  }

  String get studentSubjectDetailNoLessonsInUnit {
    return getValue('student_subject_detail_no_lessons_in_unit');
  }
}
