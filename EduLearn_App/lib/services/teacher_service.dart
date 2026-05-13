import 'package:dio/dio.dart';
import 'api_client.dart';
// import 'api_helpers.dart';

class TeacherActivitiesPage {
  final List<Map<String, dynamic>> activities;
  final int? nextCursor;

  const TeacherActivitiesPage({
    required this.activities,
    required this.nextCursor,
  });
}

class TeacherService {
  static Future<List<dynamic>> fetchTeacherAssignments() async {
  try {
    // تغيير المسار من '/teacher/assignments' إلى '/teacher/assignments-summary'
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

  static Future<TeacherActivitiesPage> fetchTeacherActivities({
    int limit = 10,
    int? beforeId,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': limit,
        if (beforeId != null) 'before_id': beforeId,
      };
      final response = await ApiClient.instance.get('/teacher/activities',
          queryParameters: queryParams);
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true) {
        final List<Map<String, dynamic>> activities = (data['activities'] as List?)
                ?.whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList() ??
            [];
        final int? nextCursor = data['next_cursor'] is int ? data['next_cursor'] as int : null;
        return TeacherActivitiesPage(activities: activities, nextCursor: nextCursor);
      } else {
        throw Exception(data['message'] ?? 'Failed to load teacher activities');
      }
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Network error');
    }
  }
}