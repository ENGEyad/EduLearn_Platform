import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'api_helpers.dart';

class LessonService {
  // =============== رفع ميديا الدرس ===============

  static Future<Map<String, dynamic>> uploadLessonMedia({
    required String filePath,
  }) async {
    final url = Uri.parse('$baseUrl/teacher/lessons/media');

    final request = http.MultipartRequest('POST', url)
      ..headers['Accept'] = 'application/json'
      ..files.add(await http.MultipartFile.fromPath('file', filePath));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    late final Map<String, dynamic> data;
    try {
      data = ApiHelpers.decodeJsonAsMap(response.body);
    } catch (_) {
      throw Exception('Invalid server response.');
    }

    final okStatus = response.statusCode >= 200 && response.statusCode < 300;
    final okBody = data['success'] == true;

    if (!okStatus || !okBody) {
      final msg = data['message']?.toString() ?? 'Media upload failed';
      throw Exception(msg);
    }

    final rawPath = (data['media_path'] ?? data['path'] ?? '').toString().trim();
    final rawUrl = (data['media_url'] ?? data['url'] ?? '').toString().trim();

    String mediaPath = '';
    if (rawPath.isNotEmpty) {
      mediaPath = rawPath;
    } else if (rawUrl.isNotEmpty) {
      mediaPath = ApiHelpers.extractMediaPath(rawUrl);
    }

    mediaPath = mediaPath.trim();
    mediaPath = mediaPath.replaceFirst(RegExp(r'^/+'), '');
    if (mediaPath.startsWith('storage/')) {
      mediaPath = mediaPath.substring('storage/'.length);
    }

    final String mediaUrl = rawUrl.isNotEmpty
        ? rawUrl
        : (mediaPath.isNotEmpty ? ApiHelpers.buildFullMediaUrl(mediaPath) : '');

    final String? mime = (data['media_mime'] ?? data['mime'])?.toString();

    final int? size = (data['media_size'] is int)
        ? data['media_size'] as int
        : (data['media_size'] is num)
            ? (data['media_size'] as num).toInt()
            : (data['size'] is int)
                ? data['size'] as int
                : (data['size'] is num)
                    ? (data['size'] as num).toInt()
                    : null;

    return {
      ...data,
      'media_path': mediaPath.isNotEmpty ? mediaPath : '',
      'media_url': mediaUrl,
      'media_mime': mime,
      'media_size': size,
    };
  }

  // =============== Class Modules ===============

  static Future<List<dynamic>> fetchLessonModules({
    required String teacherCode,
    required int assignmentId,
    required int classSectionId,
    required int subjectId,
  }) async {
    final queryParams = <String, String>{
      'teacher_code': teacherCode,
      'assignment_id': assignmentId.toString(),
      'class_section_id': classSectionId.toString(),
      'subject_id': subjectId.toString(),
    };

    final uri = Uri.parse('$baseUrl/teacher/class-modules')
        .replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: {'Accept': 'application/json'},
    );

    final data = ApiHelpers.decodeJsonAsMap(response.body);

    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        data['success'] == true) {
      return (data['modules'] as List?) ?? <dynamic>[];
    } else {
      throw Exception(data['message'] ?? 'Failed to load lesson modules');
    }
  }

  static Future<Map<String, dynamic>> createLessonModule({
    required String teacherCode,
    required int assignmentId,
    required int classSectionId,
    required int subjectId,
    required String title,
  }) async {
    final url = Uri.parse('$baseUrl/teacher/class-modules');

    final payload = {
      'teacher_code': teacherCode,
      'assignment_id': assignmentId,
      'class_section_id': classSectionId,
      'subject_id': subjectId,
      'title': title,
    };

    final response = await http.post(
      url,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );

    final data = ApiHelpers.decodeJsonAsMap(response.body);

    if (response.statusCode >= 201 &&
        response.statusCode < 300 &&
        data['success'] == true) {
      return (data['module'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    } else {
      throw Exception(data['message'] ?? 'Failed to create lesson module');
    }
  }

  static Future<void> updateLessonModule({
    required int moduleId,
    required String title,
  }) async {
    final url = Uri.parse('$baseUrl/teacher/class-modules/$moduleId');

    final payload = {'title': title};

    final response = await http.put(
      url,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );

    final data = ApiHelpers.decodeJsonAsMap(response.body);

    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to update lesson module');
    }
  }

  static Future<void> deleteLessonModule({
    required int moduleId,
  }) async {
    final url = Uri.parse('$baseUrl/teacher/class-modules/$moduleId');

    final response = await http.delete(
      url,
      headers: {'Accept': 'application/json'},
    );

    final data = ApiHelpers.decodeJsonAsMap(response.body);

    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to delete lesson module');
    }
  }

  static Future<List<dynamic>> fetchLessonsForModule({
    required int moduleId,
  }) async {
    final url = Uri.parse('$baseUrl/teacher/class-modules/$moduleId/lessons');

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
      throw Exception(data['message'] ?? 'Failed to load module lessons');
    }
  }

  // =============== Lesson Save / Detail / List / Delete ===============

  static Future<Map<String, dynamic>> saveLesson({
    required String teacherCode,
    required int assignmentId,
    required int classModuleId,
    required int classSectionId,
    required int subjectId,
    int? lessonId,
    required String title,
    required bool publish,
    List<Map<String, dynamic>> modules = const [],
    List<Map<String, dynamic>> topics = const [],
    required List<Map<String, dynamic>> blocks,
  }) async {
    final url = Uri.parse('$baseUrl/teacher/lessons/save');

    final normalizedBlocks = blocks.asMap().entries.map((entry) {
      final i = entry.key;
      final b = entry.value;

      final block = Map<String, dynamic>.from(b);
      final type = (block['type'] ?? '').toString();

      final isMedia = type == 'image' || type == 'video' || type == 'audio';

      if (isMedia) {
        final rawPath = (block['media_path'] ?? '').toString();
        final rawUrl = (block['media_url'] ?? '').toString();

        var mediaPath = rawPath.trim();
        if (mediaPath.isEmpty && rawUrl.trim().isNotEmpty) {
          mediaPath = ApiHelpers.extractMediaPath(rawUrl);
        }

        mediaPath = mediaPath.replaceFirst(RegExp(r'^/+'), '');
        if (mediaPath.startsWith('storage/')) {
          mediaPath = mediaPath.substring('storage/'.length);
        }

        block['media_path'] = mediaPath.isNotEmpty ? mediaPath : null;
      }

      block['module_id'] = null;
      block['topic_id'] = null;

      if (block['position'] == null) {
        block['position'] = i + 1;
      }

      return block;
    }).toList();

    final payload = {
      'teacher_code': teacherCode,
      'assignment_id': assignmentId,
      'class_module_id': classModuleId,
      'class_section_id': classSectionId,
      'subject_id': subjectId,
      if (lessonId != null) 'lesson_id': lessonId,
      'title': title,
      'status': publish ? 'published' : 'draft',
      'modules': modules,
      'topics': topics,
      'blocks': normalizedBlocks,
    };

    final response = await http.post(
      url,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );

    final data = ApiHelpers.decodeJsonAsMap(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (data['success'] == true) {
        if (data['lesson'] is Map) return Map<String, dynamic>.from(data);
        if (data['lesson_id'] != null) return Map<String, dynamic>.from(data);
        throw Exception('Invalid save response payload');
      }
      throw Exception(data['message'] ?? 'Lesson save failed');
    } else {
      throw Exception(data['message'] ?? 'Lesson save failed');
    }
  }

  static Future<Map<String, dynamic>> fetchLessonDetail({
    required int lessonId,
    required String teacherCode,
  }) async {
    final uri = Uri.parse('$baseUrl/teacher/lessons/$lessonId')
        .replace(queryParameters: {'teacher_code': teacherCode});

    final response = await http.get(
      uri,
      headers: {'Accept': 'application/json'},
    );

    final data = ApiHelpers.decodeJsonAsMap(response.body);

    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        data['success'] == true &&
        data['lesson'] is Map) {
      return Map<String, dynamic>.from(data['lesson'] as Map);
    } else {
      throw Exception(data['message'] ?? 'Failed to load lesson detail');
    }
  }

  static Future<List<dynamic>> fetchTeacherLessons({
    required String teacherCode,
    int? assignmentId,
    int? classSectionId,
    int? subjectId,
    int? classModuleId,
  }) async {
    final queryParams = <String, String>{
      'teacher_code': teacherCode,
      if (assignmentId != null) 'assignment_id': assignmentId.toString(),
      if (classSectionId != null) 'class_section_id': classSectionId.toString(),
      if (subjectId != null) 'subject_id': subjectId.toString(),
      if (classModuleId != null) 'class_module_id': classModuleId.toString(),
    };

    final uri = Uri.parse('$baseUrl/teacher/lessons')
        .replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: {'Accept': 'application/json'},
    );

    final data = ApiHelpers.decodeJsonAsMap(response.body);

    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        data['success'] == true) {
      return (data['lessons'] as List?) ?? <dynamic>[];
    } else {
      throw Exception(data['message'] ?? 'Failed to load teacher lessons');
    }
  }

  static Future<void> deleteLesson({
    required int lessonId,
    required String teacherCode,
  }) async {
    final uri = Uri.parse('$baseUrl/teacher/lessons/$lessonId')
        .replace(queryParameters: {'teacher_code': teacherCode});

    final response = await http.delete(
      uri,
      headers: {'Accept': 'application/json'},
    );

    final data = ApiHelpers.decodeJsonAsMap(response.body);

    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to delete lesson');
    }
  }

  static Future<void> deleteLessons({
    required String teacherCode,
    required List<int> lessonIds,
  }) async {
    final url = Uri.parse('$baseUrl/teacher/lessons/bulk-delete');

    final payload = {
      'teacher_code': teacherCode,
      'lesson_ids': lessonIds,
    };

    final response = await http.post(
      url,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );

    final data = ApiHelpers.decodeJsonAsMap(response.body);

    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to delete lessons');
    }
  }
}
