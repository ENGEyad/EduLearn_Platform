import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../services/api_client.dart';
import 'teacher_progress_models.dart';

class TeacherProgressService {
  const TeacherProgressService._();

  static Future<TeacherStudentSubjectProgress> fetchStudentSubjectProgress({
    int? studentId,
    String? academicId,
    required int subjectId,
    int? assignmentId,
  }) async {
    if ((studentId == null || studentId <= 0) &&
        (academicId == null || academicId.trim().isEmpty)) {
      throw Exception('student_id or academic_id is required.');
    }

    final query = <String, dynamic>{
      'subject_id': subjectId,
      if (studentId != null && studentId > 0) 'student_id': studentId,
      if (academicId != null && academicId.trim().isNotEmpty)
        'academic_id': academicId.trim(),
      if (assignmentId != null && assignmentId > 0) 'assignment_id': assignmentId,
    };

    try {
      final response = await ApiClient.instance.get(
        '/teacher/progress/student-subject',
        queryParameters: query,
      );
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true && data['data'] is Map) {
        return TeacherStudentSubjectProgress.fromJson(
          Map<String, dynamic>.from(data['data'] as Map),
        );
      }
      throw Exception(data['message'] ?? 'Failed to load student subject progress.');
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Network error');
    }
  }
}