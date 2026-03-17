class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final String? imageUrl;
  final String? preferredLanguage;
  final bool? isDarkMode;
  final Map<String, dynamic>? notificationSettings;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    this.imageUrl,
    this.preferredLanguage,
    this.isDarkMode,
    this.notificationSettings,
  });
}

class Assignment {
  final String id;
  final String name;
  Assignment({required this.id, required this.name});
}

class TeacherModel extends UserModel {
  final String teacherCode;
  final String? subjectSpecialization;
  final String? department;
  final List<Assignment>? assignments;
  final int? totalAssignedStudents;

  TeacherModel({
    required super.id,
    required super.fullName,
    required super.email,
    super.phone,
    super.imageUrl,
    super.preferredLanguage,
    super.isDarkMode,
    super.notificationSettings,
    required this.teacherCode,
    this.subjectSpecialization,
    this.department,
    this.assignments,
    this.totalAssignedStudents,
  });
}

class Course {
  final String id;
  final String title;
  Course({required this.id, required this.title});
}

class StudentModel extends UserModel {
  final String studentId;
  final String? gradeLevel;
  final String? parentName;
  final String? parentPhone;
  final List<Course>? enrolledCourses;

  StudentModel({
    required super.id,
    required super.fullName,
    required super.email,
    super.phone,
    super.imageUrl,
    super.preferredLanguage,
    super.isDarkMode,
    super.notificationSettings,
    required this.studentId,
    this.gradeLevel,
    this.parentName,
    this.parentPhone,
    this.enrolledCourses,
  });
}
