import '../../core/app_localizations.dart';

extension ClassDetailsL10n on AppLocalizations {
  String get classDetailsStudents => getValue('class_details_students');
  String get classDetailsLessons => getValue('class_details_lessons');
  String get classDetailsGrade => getValue('class_details_grade');
  String get classDetailsSection => getValue('class_details_section');

  String get classDetailsAddUnit => getValue('class_details_add_unit');

  String get classDetailsAddUnitDescription {
    return getValue('class_details_add_unit_description');
  }

  String get classDetailsUnitName => getValue('class_details_unit_name');

  String get classDetailsUnitNameHint {
    return getValue('class_details_unit_name_hint');
  }

  String get classDetailsCancel => getValue('class_details_cancel');
  String get classDetailsSave => getValue('class_details_save');

  String get classDetailsUnitAddedSuccess {
    return getValue('class_details_unit_added_success');
  }

  String get classDetailsUnitNameUpdatedSuccess {
    return getValue('class_details_unit_name_updated_success');
  }

  String get classDetailsUnitDeletedSuccess {
    return getValue('class_details_unit_deleted_success');
  }

  String get classDetailsLessonAddedSuccess {
    return getValue('class_details_lesson_added_success');
  }

  String get classDetailsLessonUpdatedSuccess {
    return getValue('class_details_lesson_updated_success');
  }

  String get classDetailsLessonsDeletedSuccess {
    return getValue('class_details_lessons_deleted_success');
  }

  String get classDetailsRenameUnit {
    return getValue('class_details_rename_unit');
  }

  String get classDetailsDeleteUnitWithLessons {
    return getValue('class_details_delete_unit_with_lessons');
  }

  String get classDetailsConfirmDeletion {
    return getValue('class_details_confirm_deletion');
  }

  String get classDetailsDelete => getValue('class_details_delete');

  String classDetailsDeleteUnitConfirmation(String title) {
    return formatValue(
      'class_details_delete_unit_confirmation',
      {'title': title},
    );
  }

  String classDetailsDeleteSelectedLessonsConfirmation(int count) {
    return formatValue(
      'class_details_delete_selected_lessons_confirmation',
      {'count': count.toString()},
    );
  }

  String get classDetailsSelectUnitFirst {
    return getValue('class_details_select_unit_first');
  }

  String get classDetailsStudentFallback {
    return getValue('class_details_student_fallback');
  }

  String get classDetailsNoStudentsFound {
    return getValue('class_details_no_students_found');
  }

  String get classDetailsNoUnits {
    return getValue('class_details_no_units');
  }

  String get classDetailsNoLessons {
    return getValue('class_details_no_lessons');
  }

  String get classDetailsUnitFallback {
    return getValue('class_details_unit_fallback');
  }

  String classDetailsLessonCount(int count) {
    return formatValue(
      'class_details_lesson_count',
      {'count': count.toString()},
    );
  }

  String get classDetailsDraft => getValue('class_details_draft');
  String get classDetailsPublished => getValue('class_details_published');
}