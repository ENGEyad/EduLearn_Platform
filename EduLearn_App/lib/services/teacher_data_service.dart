import 'package:dio/dio.dart';
import 'api_client.dart';
// import 'api_helpers.dart';

class TeacherDataService {
  static Future<List<dynamic>> fetchAssignmentsSummary() async {
    try {
      final response = await ApiClient.instance.get('/teacher/assignments-summary');
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true) {
        return (data['assignments'] as List?) ?? [];
      } else {
        throw Exception(data['message'] ?? 'Failed to load assignments');
      }
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Network error');
    }
  }

  static Future<List<dynamic>> fetchAssignmentStudents({
    required int assignmentId,
  }) async {
    try {
      final response = await ApiClient.instance.get('/teacher/assignment/$assignmentId/students');
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true) {
        return (data['students'] as List?) ?? [];
      } else {
        throw Exception(data['message'] ?? 'Failed to load students');
      }
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Network error');
    }
  }
}