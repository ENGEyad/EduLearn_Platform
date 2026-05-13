// import 'dart:convert';
import 'package:dio/dio.dart';
import 'api_client.dart';
import 'api_helpers.dart';

class LessonService {
  static Exception _buildApiException(Map<String, dynamic> data, String fallbackMessage) {
    final message = (data['message'] ?? fallbackMessage).toString().trim();
    final error = (data['error'] ?? '').toString().trim();
    return error.isNotEmpty ? Exception('$message\n$error') : Exception(message);
  }

  // =============== رفع ميديا الدرس (بدون teacher_code) ===============
  static Future<Map<String, dynamic>> uploadLessonMedia({
    required String filePath,
  }) async {
    final url = '/teacher/lessons/media';
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });

    try {
      final response = await ApiClient.instance.post(
        url,
        data: formData,
        options: Options(headers: {'Accept': 'application/json'}),
      );
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true) {
        final rawPath = (data['media_path'] ?? data['path'] ?? '').toString().trim();
        final rawUrl = (data['media_url'] ?? data['url'] ?? '').toString().trim();

        String mediaPath = '';
        if (rawPath.isNotEmpty) {
          mediaPath = rawPath;
        } else if (rawUrl.isNotEmpty) {
          mediaPath = ApiHelpers.extractMediaPath(rawUrl);
        }
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
      } else {
        throw _buildApiException(data, 'Media upload failed');
      }
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Network error');
    }
  }

  // =============== AI Lesson Source ===============
  static Future<Map<String, dynamic>> getActiveLessonAiSource({
    required int lessonId,
  }) async {
    try {
      final response = await ApiClient.instance.get('/teacher/lessons/ai/source/$lessonId');
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true) {
        return data;
      } else {
        throw _buildApiException(data, 'Failed to load AI source');
      }
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Network error');
    }
  }

  static Future<Map<String, dynamic>> replaceLessonAiSourceWithText({
    required int lessonId,
    required String sourceText,
  }) async {
    try {
      final response = await ApiClient.instance.post(
        '/teacher/lessons/ai/source/$lessonId/replace',
        data: {'source_text': sourceText},
      );
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true && data['source'] is Map) {
        return Map<String, dynamic>.from(data);
      } else {
        throw _buildApiException(data, 'Failed to save AI source');
      }
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Network error');
    }
  }

  static Future<Map<String, dynamic>> replaceLessonAiSourceWithPdf({
    required int lessonId,
    required String filePath,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });
      final response = await ApiClient.instance.post(
        '/teacher/lessons/ai/source/$lessonId/replace',
        data: formData,
        options: Options(headers: {'Accept': 'application/json'}),
      );
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true && data['source'] is Map) {
        return Map<String, dynamic>.from(data);
      } else {
        throw _buildApiException(data, 'Failed to save AI source');
      }
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Network error');
    }
  }

  static Future<Map<String, dynamic>> generateAiLessonBlocksFromExistingSource({
    required int lessonId,
    required String instructionKey,
  }) async {
    try {
      final response = await ApiClient.instance.post(
        '/teacher/lessons/ai/generate-blocks',
        data: {
          'lesson_id': lessonId,
          'instruction_key': instructionKey,
          'source_mode': 'existing',
        },
      );
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true) {
        return data;
      } else {
        throw _buildApiException(data, 'Failed to generate AI blocks');
      }
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Network error');
    }
  }

  static Future<Map<String, dynamic>> generateAiLessonBlocksFromText({
    required int lessonId,
    required String instructionKey,
    required String sourceText,
  }) async {
    try {
      final response = await ApiClient.instance.post(
        '/teacher/lessons/ai/generate-blocks',
        data: {
          'lesson_id': lessonId,
          'instruction_key': instructionKey,
          'source_mode': 'new_or_replace',
          'source_text': sourceText,
        },
      );
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true) {
        return data;
      } else {
        throw _buildApiException(data, 'Failed to generate AI blocks');
      }
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Network error');
    }
  }

  static Future<Map<String, dynamic>> generateAiLessonBlocksFromPdf({
    required int lessonId,
    required String instructionKey,
    required String filePath,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
        'lesson_id': lessonId,
        'instruction_key': instructionKey,
        'source_mode': 'new_or_replace',
      });
      final response = await ApiClient.instance.post(
        '/teacher/lessons/ai/generate-blocks',
        data: formData,
        options: Options(headers: {'Accept': 'application/json'}),
      );
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true) {
        return data;
      } else {
        throw _buildApiException(data, 'Failed to generate AI blocks');
      }
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Network error');
    }
  }

  static Future<Map<String, dynamic>> rewriteAiLessonBlock({
    required int lessonId,
    required String stableKey,
    required String currentBody,
    required String instructionKey,
  }) async {
    try {
      final response = await ApiClient.instance.post(
        '/teacher/lessons/ai/rewrite-block',
        data: {
          'lesson_id': lessonId,
          'stable_key': stableKey,
          'current_body': currentBody,
          'instruction_key': instructionKey,
        },
      );
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true) {
        return data;
      } else {
        throw _buildApiException(data, 'Failed to rewrite AI block');
      }
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Network error');
    }
  }

  // =============== Class Modules ===============
  static Future<List<dynamic>> fetchLessonModules({
    required String teacherCode,
    required int assignmentId,
    required int classSectionId,
    required int subjectId,
  }) async {
    try {
      final response = await ApiClient.instance.get('/teacher/class-modules', queryParameters: {
        'teacher_code': teacherCode,
        'assignment_id': assignmentId,
        'class_section_id': classSectionId,
        'subject_id': subjectId,
      });
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true) {
        return (data['modules'] as List?) ?? [];
      } else {
        throw Exception(data['message'] ?? 'Failed to load lesson modules');
      }
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Network error');
    }
  }

  static Future<Map<String, dynamic>> createLessonModule({
    required String teacherCode,
    required int assignmentId,
    required int classSectionId,
    required int subjectId,
    required String title,
  }) async {
    try {
      final response = await ApiClient.instance.post('/teacher/class-modules', data: {
        'teacher_code': teacherCode,
        'assignment_id': assignmentId,
        'class_section_id': classSectionId,
        'subject_id': subjectId,
        'title': title,
      });
      final data = response.data as Map<String, dynamic>;
      if ((response.statusCode ?? 0) >= 201 && data['success'] == true) {
        return (data['module'] as Map<String, dynamic>?) ?? {};
      } else {
        throw Exception(data['message'] ?? 'Failed to create lesson module');
      }
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Network error');
    }
  }

  static Future<void> updateLessonModule({
    required int moduleId,
    required String title,
    int? position,
  }) async {
    try {
      final response = await ApiClient.instance.put('/teacher/class-modules/$moduleId', data: {
        'title': title,
        if (position != null) 'position': position,
      });
      final data = response.data as Map<String, dynamic>;
      if (data['success'] != true) {
        throw Exception(data['message'] ?? 'Failed to update lesson module');
      }
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Network error');
    }
  }

  static Future<void> deleteLessonModule({
    required int moduleId,
  }) async {
    try {
      final response = await ApiClient.instance.delete('/teacher/class-modules/$moduleId');
      final data = response.data as Map<String, dynamic>;
      if (data['success'] != true) {
        throw Exception(data['message'] ?? 'Failed to delete lesson module');
      }
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Network error');
    }
  }

  static Future<List<dynamic>> fetchLessonsForModule({
    required int moduleId,
  }) async {
    try {
      final response = await ApiClient.instance.get('/teacher/class-modules/$moduleId/lessons');
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true) {
        return (data['lessons'] as List?) ?? [];
      } else {
        throw Exception(data['message'] ?? 'Failed to load module lessons');
      }
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Network error');
    }
  }

  // =============== Lessons CRUD (بدون teacher_code) ===============
  static Future<Map<String, dynamic>> saveLesson({
    required String teacherCode,
    required int assignmentId,
    required int classModuleId,
    required int classSectionId,
    required int subjectId,
    int? lessonId,
    required String title,
    required bool publish,
    required List<Map<String, dynamic>> blocks,
  }) async {
    final normalizedBlocks = blocks.asMap().entries.map((entry) {
      final i = entry.key;
      final b = entry.value;
      final block = Map<String, dynamic>.from(b);
      final type = (block['type'] ?? '').toString();

      final isMedia = type == 'image' || type == 'video' || type == 'audio' || type == 'file';

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
      } else {
        block['media_path'] = null;
      }

      block.remove('module_id');
      block.remove('topic_id');

      if (block['position'] == null) {
        block['position'] = i + 1;
      }

      block['stable_key'] = (block['stable_key'] ?? '').toString().trim().isNotEmpty
          ? block['stable_key']
          : null;

      block['created_origin'] = (block['created_origin'] ?? '').toString().trim().isNotEmpty
          ? block['created_origin']
          : 'manual';

      block['last_edit_origin'] = (block['last_edit_origin'] ?? '').toString().trim().isNotEmpty
          ? block['last_edit_origin']
          : block['created_origin'];

      block['ai_source_id'] = (block['ai_source_id'] is int)
          ? block['ai_source_id']
          : (block['ai_source_id'] is num)
              ? (block['ai_source_id'] as num).toInt()
              : null;

      block['ai_last_run_id'] = (block['ai_last_run_id'] is int)
          ? block['ai_last_run_id']
          : (block['ai_last_run_id'] is num)
              ? (block['ai_last_run_id'] as num).toInt()
              : null;

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
      'blocks': normalizedBlocks,
    };

    try {
      final response = await ApiClient.instance.post('/teacher/lessons/save', data: payload);
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true) {
        if (data['lesson'] is Map) return Map<String, dynamic>.from(data);
        if (data['lesson_id'] != null) return Map<String, dynamic>.from(data);
        throw Exception('Invalid save response payload');
      } else {
        throw Exception(data['message'] ?? 'Lesson save failed');
      }
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Network error');
    }
  }

  static Future<Map<String, dynamic>> fetchLessonDetail({
    required String teacherCode,
    required int lessonId,
  }) async {
    try {
      final response = await ApiClient.instance.get('/teacher/lessons/$lessonId', queryParameters: {
        'teacher_code': teacherCode,
      });
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true && data['lesson'] is Map) {
        return Map<String, dynamic>.from(data['lesson'] as Map);
      } else {
        throw Exception(data['message'] ?? 'Failed to load lesson detail');
      }
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Network error');
    }
  }

  static Future<List<dynamic>> fetchTeacherLessons({
    required String teacherCode,
    int? assignmentId,
    int? classSectionId,
    int? subjectId,
    int? classModuleId,
  }) async {
    final queryParams = <String, dynamic>{
      'teacher_code': teacherCode,
      if (assignmentId != null) 'assignment_id': assignmentId,
      if (classSectionId != null) 'class_section_id': classSectionId,
      if (subjectId != null) 'subject_id': subjectId,
      if (classModuleId != null) 'class_module_id': classModuleId,
    };
    try {
      final response = await ApiClient.instance.get('/teacher/lessons', queryParameters: queryParams);
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true) {
        return (data['lessons'] as List?) ?? [];
      } else {
        throw Exception(data['message'] ?? 'Failed to load teacher lessons');
      }
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Network error');
    }
  }

  static Future<void> deleteLesson({
    required String teacherCode,
    required int lessonId,
  }) async {
    try {
      final response = await ApiClient.instance.delete('/teacher/lessons/$lessonId', queryParameters: {
        'teacher_code': teacherCode,
      });
      final data = response.data as Map<String, dynamic>;
      if (data['success'] != true) {
        throw Exception(data['message'] ?? 'Failed to delete lesson');
      }
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Network error');
    }
  }

  static Future<void> deleteLessons({
    required String teacherCode,
    required List<int> lessonIds,
  }) async {
    try {
      final response = await ApiClient.instance.post('/teacher/lessons/bulk-delete', data: {
        'teacher_code': teacherCode,
        'lesson_ids': lessonIds,
      });
      final data = response.data as Map<String, dynamic>;
      if (data['success'] != true) {
        throw Exception(data['message'] ?? 'Failed to delete lessons');
      }
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Network error');
    }
  }
}