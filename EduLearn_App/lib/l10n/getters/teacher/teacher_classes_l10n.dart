import '../../core/app_localizations.dart';

extension AppLocalizationsTeacherClasses on AppLocalizations {
  String get myClasses => getValue('my_classes');
  String get assignedClasses => getValue('assigned_classes');
  String get grade => getValue('grade');
  String get section => getValue('section');
  String get secShort => getValue('sec_short');
  String get subject => getValue('subject');

  String studentsCount(int count) {
    return formatValue('students_count', {'count': count.toString()});
  }

  String get noClassesYet => getValue('no_classes_yet');

  String get assignedClassesEmptyMessage {
    return getValue('assigned_classes_empty_message');
  }
}