import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'api_helpers.dart';

class StudentService {
  static Future<List<dynamic>> fetchStudentSubjects({
    required String academicId,
  }) async {
    final url = Uri.parse('$baseUrl/student/subjects?academic_id=$academicId');

    final response = await http.get(
      url,
      headers: {'Accept': 'application/json'},
    );

    final data = ApiHelpers.decodeJsonAsMap(response.body);

    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        data['success'] == true) {
      return (data['subjects'] as List?) ?? <dynamic>[];
    } else {
      throw Exception(data['message'] ?? 'Failed to load subjects');
    }
  }

  static Future<List<dynamic>> fetchStudentLessonsForSubject({
    required String academicId,
    required int subjectId,
  }) async {
    final url = Uri.parse(
      '$baseUrl/student/lessons?academic_id=$academicId&subject_id=$subjectId',
    );

    final response = await http.get(
      url,
      headers: {'Accept': 'application/json'},
    );

    final data = ApiHelpers.decodeJsonAsMap(response.body);

    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        data['success'] == true) {
      return (data['lessons'] as List?) ?? <dynamic>[];
    } else {
      throw Exception(data['message'] ?? 'Failed to load lessons');
    }
  }

  static Future<Map<String, dynamic>> fetchStudentLessonDetail({
    required String academicId,
    required int lessonId,
  }) async {
    final uri = Uri.parse('$baseUrl/student/lessons/$lessonId')
        .replace(queryParameters: {'academic_id': academicId});

    final response = await http.get(
      uri,
      headers: {'Accept': 'application/json'},
    );

    final data = ApiHelpers.decodeJsonAsMap(response.body);

    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        data['success'] == true) {
      if (data['lesson'] is Map) {
        return Map<String, dynamic>.from(data['lesson'] as Map);
      }
      if (data['data'] is Map) {
        return Map<String, dynamic>.from(data['data'] as Map);
      }
      throw Exception('Invalid lesson detail payload');
    } else {
      throw Exception(data['message'] ?? 'Failed to load lesson detail');
    }
  }

  static Future<void> updateStudentLessonStatus({
    required String academicId,
    required int lessonId,
    required String status,
  }) async {
    final url = Uri.parse('$baseUrl/student/lessons/update-status');

    final response = await http.post(
      url,
      headers: {'Accept': 'application/json'},
      body: {
        'academic_id': academicId,
        'lesson_id': lessonId.toString(),
        'status': status,
      },
    );

    final data = ApiHelpers.decodeJsonAsMap(response.body);

    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to update lesson status');
    }
  }
}
