import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'api_helpers.dart';

class TeacherService {
  static Future<List<dynamic>> fetchTeacherAssignments({
    required String teacherCode,
  }) async {
    final url =
        Uri.parse('$baseUrl/teacher/assignments?teacher_code=$teacherCode');

    final response = await http.get(
      url,
      headers: {'Accept': 'application/json'},
    );

    final data = ApiHelpers.decodeJsonAsMap(response.body);

    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        data['success'] == true) {
      return (data['assignments'] as List?) ?? <dynamic>[];
    } else {
      throw Exception(data['message'] ?? 'Failed to load assignments');
    }
  }
}
