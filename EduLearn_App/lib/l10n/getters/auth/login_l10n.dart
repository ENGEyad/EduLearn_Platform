import '../../core/app_localizations.dart';

extension LoginL10n on AppLocalizations {
  String get loginAppName => getValue('login_app_name');
  String get loginWelcomeBack => getValue('login_welcome_back');
  String get loginDescription => getValue('login_description');
  String get loginAccountType => getValue('login_account_type');
  String get loginStudentRole => getValue('login_student_role');
  String get loginTeacherRole => getValue('login_teacher_role');
  String get loginFullName => getValue('login_full_name');
  String get loginFullNameHint => getValue('login_full_name_hint');
  String get loginFullNameRequired => getValue('login_full_name_required');
  String get loginStudentId => getValue('login_student_id');
  String get loginTeacherCode => getValue('login_teacher_code');
  String get loginStudentIdHint => getValue('login_student_id_hint');
  String get loginTeacherCodeHint => getValue('login_teacher_code_hint');
  String get loginStudentIdRequired => getValue('login_student_id_required');
  String get loginTeacherCodeRequired => getValue('login_teacher_code_required');
  String get loginButton => getValue('login_button');
  String get loginStudentHelper => getValue('login_student_helper');
  String get loginTeacherHelper => getValue('login_teacher_helper');
}
