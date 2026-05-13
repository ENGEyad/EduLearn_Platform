import 'package:dio/dio.dart';
import 'api_client.dart';
// import 'api_helpers.dart';

class StudentActivitiesPage {
  final List<Map<String, dynamic>> activities;
  final int? nextCursor;

  const StudentActivitiesPage({
    required this.activities,
    required this.nextCursor,
  });
}

class StudentService {
  static Future<List<dynamic>> fetchStudentSubjects() async {
    try {
      final response = await ApiClient.instance.get('/student/subjects');
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true) {
        return (data['subjects'] as List?) ?? [];
      } else {
        throw Exception(data['message'] ?? 'Failed to load subjects');
      }
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Network error');
    }
  }

  static Future<List<dynamic>> fetchStudentTeachers() async {
    try {
      final response = await ApiClient.instance.get('/student/teachers');
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true) {
        return (data['teachers'] as List?) ?? [];
      } else {
        throw Exception(data['message'] ?? 'Failed to load teachers');
      }
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Network error');
    }
  }

  static Future<List<dynamic>> fetchStudentLessonsForSubject({
    required int subjectId,
  }) async {
    try {
      final response = await ApiClient.instance.get('/student/lessons',
          queryParameters: {'subject_id': subjectId});
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true) {
        return (data['lessons'] as List?) ?? [];
      } else {
        throw Exception(data['message'] ?? 'Failed to load lessons');
      }
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Network error');
    }
  }

  static Future<Map<String, dynamic>> fetchStudentLessonDetail({
    required int lessonId,
  }) async {
    try {
      final response = await ApiClient.instance.get('/student/lessons/$lessonId');
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true) {
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
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Network error');
    }
  }

  static Future<void> updateStudentLessonStatus({
    required int lessonId,
    required String status,
  }) async {
    try {
      final response = await ApiClient.instance.post('/student/lessons/update-status',
          data: {
            'lesson_id': lessonId,
            'status': status,
          });
      final data = response.data as Map<String, dynamic>;
      if (data['success'] != true) {
        throw Exception(data['message'] ?? 'Failed to update lesson status');
      }
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Network error');
    }
  }

  static Future<Map<String, dynamic>> saveStudentLessonProgress({
    required int lessonId,
    required int timeSpentSeconds,
    required String status,
    int? lastBlockIndex,
    double? lastScrollOffset,
    bool markOpened = false,
  }) async {
    try {
      final body = <String, dynamic>{
        'time_spent_seconds': timeSpentSeconds,
        'status': status,
        'mark_opened': markOpened ? '1' : '0',
        if (lastBlockIndex != null) 'last_block_index': lastBlockIndex,
        if (lastScrollOffset != null) 'last_scroll_offset': lastScrollOffset,
      };
      final response = await ApiClient.instance.post(
          '/student/lessons/$lessonId/progress',
          data: body);
      final data = response.data as Map<String, dynamic>;
      if (data['success'] != true) {
        throw Exception(data['message'] ?? 'Failed to save lesson progress');
      }
      return data;
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Network error');
    }
  }

  static Future<Map<String, dynamic>> fetchStudentProgressOverview() async {
    try {
      final response = await ApiClient.instance.get('/student/progress/overview');
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true) {
        final dynamic payload = data['data'] ?? data['overview'] ?? data['progress'];
        if (payload is Map<String, dynamic>) {
          return payload;
        }
        if (payload is Map) {
          return Map<String, dynamic>.from(payload);
        }
        final fallback = Map<String, dynamic>.from(data);
        fallback.remove('success');
        return fallback;
      } else {
        throw Exception(data['message'] ?? 'Failed to load progress overview');
      }
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Network error');
    }
  }

  static Future<Map<String, dynamic>> fetchStudentSubjectProgress({
    required int subjectId,
  }) async {
    try {
      final response = await ApiClient.instance.get('/student/subjects/$subjectId/progress');
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true) {
        final payload = data['data'];
        if (payload is Map<String, dynamic>) {
          return payload;
        }
        if (payload is Map) {
          return Map<String, dynamic>.from(payload);
        }
        throw Exception('Invalid subject progress payload');
      } else {
        throw Exception(data['message'] ?? 'Failed to load subject progress');
      }
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Network error');
    }
  }

  static Future<StudentActivitiesPage> fetchStudentActivities({
    int limit = 10,
    int? beforeId,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': limit,
        if (beforeId != null) 'before_id': beforeId,
      };
      final response = await ApiClient.instance.get('/student/activities',
          queryParameters: queryParams);
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true) {
        final List<Map<String, dynamic>> activities = (data['activities'] as List?)
                ?.whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList() ??
            [];
        final int? nextCursor = data['next_cursor'] is int ? data['next_cursor'] as int : null;
        return StudentActivitiesPage(activities: activities, nextCursor: nextCursor);
      } else {
        throw Exception(data['message'] ?? 'Failed to load activities');
      }
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Network error');
    }
  }
}