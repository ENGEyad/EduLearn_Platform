import 'dart:convert';

import 'package:http/http.dart' as http;

class LessonExerciseService {
  LessonExerciseService({
    required this.baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;

    final normalizedPath = path.startsWith('/') ? path : '/$path';

    return Uri.parse('$normalizedBase$normalizedPath').replace(
      queryParameters: query?.map(
        (key, value) => MapEntry(key, value?.toString()),
      ),
    );
  }

  Map<String, String> get _headers => const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

  dynamic _decodeBody(http.Response response) {
    if (response.body.isEmpty) return null;
    return jsonDecode(response.body);
  }

  Map<String, dynamic> _decodeMap(http.Response response) {
    final decoded = _decodeBody(response);
    if (decoded is Map<String, dynamic>) return decoded;
    throw Exception('Invalid response format');
  }

  void _ensureSuccess(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    String message = 'Request failed with status ${response.statusCode}';

    try {
      final decoded = _decodeBody(response);
      if (decoded is Map<String, dynamic>) {
        final apiMessage = decoded['message'];
        final errors = decoded['errors'];

        if (apiMessage is String && apiMessage.trim().isNotEmpty) {
          message = apiMessage;
        } else if (errors is Map) {
          final firstEntry =
              errors.entries.isNotEmpty ? errors.entries.first : null;
          final firstValue = firstEntry?.value;
          if (firstValue is List && firstValue.isNotEmpty) {
            message = firstValue.first.toString();
          }
        }
      }
    } catch (_) {
      // keep generic message
    }

    throw Exception(message);
  }

  Map<String, dynamic>? _extractDataMap(Map<String, dynamic> payload) {
    final data = payload['data'];
    if (data is Map<String, dynamic>) return data;
    return null;
  }

  void dispose() {
    _client.close();
  }

  // ============================================================
  // Teacher APIs
  // ============================================================

  Future<Map<String, dynamic>?> fetchTeacherExerciseDraft({
    required int lessonId,
    required String teacherCode,
  }) async {
    final response = await _client.get(
      _uri(
        '/teacher/lessons/$lessonId/exercise-set/draft',
        {'teacher_code': teacherCode},
      ),
      headers: _headers,
    );

    _ensureSuccess(response);

    final decoded = _decodeMap(response);
    final data = _extractDataMap(decoded);

    return data;
  }

  Future<Map<String, dynamic>> saveTeacherExerciseDraft({
    required int lessonId,
    required String teacherCode,
    String? title,
    String generationSource = 'manual',
    required List<Map<String, dynamic>> questions,
  }) async {
    final payload = <String, dynamic>{
      'teacher_code': teacherCode,
      'title': title,
      'generation_source': generationSource,
      'questions': questions,
    };

    final response = await _client.post(
      _uri('/teacher/lessons/$lessonId/exercise-set/save-draft'),
      headers: _headers,
      body: jsonEncode(payload),
    );

    _ensureSuccess(response);

    final decoded = _decodeMap(response);
    final data = _extractDataMap(decoded);

    if (data != null) return data;

    throw Exception('Exercise draft was not returned by the server.');
  }

  Future<Map<String, dynamic>> publishTeacherExerciseSet({
    required int lessonId,
    required String teacherCode,
  }) async {
    final response = await _client.post(
      _uri('/teacher/lessons/$lessonId/exercise-set/publish'),
      headers: _headers,
      body: jsonEncode({
        'teacher_code': teacherCode,
      }),
    );

    _ensureSuccess(response);

    final decoded = _decodeMap(response);
    final data = _extractDataMap(decoded);

    if (data != null) return data;

    throw Exception('Published version was not returned by the server.');
  }

  Future<Map<String, dynamic>> archiveTeacherExerciseSet({
    required int lessonId,
    required String teacherCode,
  }) async {
    final response = await _client.post(
      _uri('/teacher/lessons/$lessonId/exercise-set/archive'),
      headers: _headers,
      body: jsonEncode({
        'teacher_code': teacherCode,
      }),
    );

    _ensureSuccess(response);

    final decoded = _decodeMap(response);
    final data = _extractDataMap(decoded);

    if (data != null) return data;

    throw Exception('Archived exercise set was not returned by the server.');
  }

  Future<Map<String, dynamic>> unarchiveTeacherExerciseSet({
    required int lessonId,
    required String teacherCode,
  }) async {
    final response = await _client.post(
      _uri('/teacher/lessons/$lessonId/exercise-set/unarchive'),
      headers: _headers,
      body: jsonEncode({
        'teacher_code': teacherCode,
      }),
    );

    _ensureSuccess(response);

    final decoded = _decodeMap(response);
    final data = _extractDataMap(decoded);

    if (data != null) return data;

    throw Exception('Unarchived exercise set was not returned by the server.');
  }

  Future<Map<String, dynamic>> deleteDraftQuestion({
    required int lessonId,
    required String teacherCode,
    required String stableQuestionKey,
  }) async {
    final response = await _client.delete(
      _uri('/teacher/lessons/$lessonId/exercise-set/questions/$stableQuestionKey'),
      headers: _headers,
      body: jsonEncode({
        'teacher_code': teacherCode,
      }),
    );

    _ensureSuccess(response);

    final decoded = _decodeMap(response);
    final data = decoded['data'];

    if (data is Map<String, dynamic>) return data;

    throw Exception('Deleted draft question was not returned by the server.');
  }

  Future<Map<String, dynamic>> restoreDraftQuestion({
    required int lessonId,
    required String teacherCode,
    required String stableQuestionKey,
  }) async {
    final response = await _client.post(
      _uri(
          '/teacher/lessons/$lessonId/exercise-set/questions/$stableQuestionKey/restore'),
      headers: _headers,
      body: jsonEncode({
        'teacher_code': teacherCode,
      }),
    );

    _ensureSuccess(response);

    final decoded = _decodeMap(response);
    final data = decoded['data'];

    if (data is Map<String, dynamic>) return data;

    throw Exception('Restored draft question was not returned by the server.');
  }

  Future<Map<String, dynamic>> archiveDraftQuestion({
    required int lessonId,
    required String teacherCode,
    required String stableQuestionKey,
  }) async {
    final response = await _client.post(
      _uri(
          '/teacher/lessons/$lessonId/exercise-set/questions/$stableQuestionKey/archive'),
      headers: _headers,
      body: jsonEncode({
        'teacher_code': teacherCode,
      }),
    );

    _ensureSuccess(response);

    final decoded = _decodeMap(response);
    final data = decoded['data'];

    if (data is Map<String, dynamic>) return data;

    throw Exception('Archived draft question was not returned by the server.');
  }

  Future<Map<String, dynamic>> unarchiveDraftQuestion({
    required int lessonId,
    required String teacherCode,
    required String stableQuestionKey,
  }) async {
    final response = await _client.post(
      _uri(
          '/teacher/lessons/$lessonId/exercise-set/questions/$stableQuestionKey/unarchive'),
      headers: _headers,
      body: jsonEncode({
        'teacher_code': teacherCode,
      }),
    );

    _ensureSuccess(response);

    final decoded = _decodeMap(response);
    final data = decoded['data'];

    if (data is Map<String, dynamic>) return data;

    throw Exception('Unarchived draft question was not returned by the server.');
  }

  // ============================================================
  // Student APIs
  // ============================================================

  Future<Map<String, dynamic>?> fetchStudentCurrentExerciseBundle({
    required int lessonId,
    required String academicId,
  }) async {
    final response = await _client.get(
      _uri(
        '/student/lessons/$lessonId/exercise-set/current',
        {'academic_id': academicId},
      ),
      headers: _headers,
    );

    _ensureSuccess(response);

    final decoded = _decodeMap(response);
    final data = _extractDataMap(decoded);

    return data;
  }

  Future<Map<String, dynamic>?> fetchLatestStudentAttempt({
    required int lessonId,
    required String academicId,
  }) async {
    final response = await _client.get(
      _uri(
        '/student/lessons/$lessonId/exercise-set/latest-attempt',
        {'academic_id': academicId},
      ),
      headers: _headers,
    );

    _ensureSuccess(response);

    final decoded = _decodeMap(response);
    final data = decoded['data'];

    if (data is Map<String, dynamic>) {
      return data;
    }

    return null;
  }

  Future<Map<String, dynamic>> saveStudentExerciseAnswers({
    required int lessonId,
    required String academicId,
    required List<Map<String, dynamic>> answers,
  }) async {
    final response = await _client.post(
      _uri('/student/lessons/$lessonId/exercise-set/save'),
      headers: _headers,
      body: jsonEncode({
        'academic_id': academicId,
        'answers': answers,
      }),
    );

    _ensureSuccess(response);

    final decoded = _decodeMap(response);
    final data = _extractDataMap(decoded);

    if (data != null) return data;

    throw Exception('Saved attempt data was not returned by the server.');
  }

  Future<Map<String, dynamic>> submitStudentExerciseAnswers({
    required int lessonId,
    required String academicId,
    required List<Map<String, dynamic>> answers,
  }) async {
    final response = await _client.post(
      _uri('/student/lessons/$lessonId/exercise-set/submit'),
      headers: _headers,
      body: jsonEncode({
        'academic_id': academicId,
        'answers': answers,
      }),
    );

    _ensureSuccess(response);

    final decoded = _decodeMap(response);
    final data = _extractDataMap(decoded);

    if (data != null) return data;

    throw Exception('Submitted attempt data was not returned by the server.');
  }

  // ============================================================
  // Payload Builders - Teacher
  // ============================================================

  static Map<String, dynamic> buildDraftOption({
    String? stableOptionKey,
    required String optionText,
    required bool isCorrect,
    required int position,
  }) {
    return {
      if (stableOptionKey != null) 'stable_option_key': stableOptionKey,
      'option_text': optionText,
      'is_correct': isCorrect,
      'position': position,
    };
  }

  static Map<String, dynamic> buildMultipleChoiceQuestion({
    String? stableQuestionKey,
    String origin = 'manual',
    required String questionText,
    required List<Map<String, dynamic>> options,
    double points = 1,
    int position = 1,
    String? explanation,
    bool isActive = true,
    bool isArchived = false,
    Map<String, dynamic>? meta,
  }) {
    return {
      if (stableQuestionKey != null) 'stable_question_key': stableQuestionKey,
      'origin': origin,
      'type': 'multiple_choice',
      'question_text': questionText,
      'points': points,
      'position': position,
      'explanation': explanation,
      'is_active': isActive,
      'is_archived': isArchived,
      'options': options,
      if (meta != null) 'meta': meta,
    };
  }

  static Map<String, dynamic> buildTrueFalseQuestion({
    String? stableQuestionKey,
    String origin = 'manual',
    required String questionText,
    required bool correctIsTrue,
    double points = 1,
    int position = 1,
    String? explanation,
    bool isActive = true,
    bool isArchived = false,
    Map<String, dynamic>? meta,
  }) {
    return {
      if (stableQuestionKey != null) 'stable_question_key': stableQuestionKey,
      'origin': origin,
      'type': 'true_false',
      'question_text': questionText,
      'points': points,
      'position': position,
      'explanation': explanation,
      'is_active': isActive,
      'is_archived': isArchived,
      'options': [
        buildDraftOption(
          optionText: 'صح',
          isCorrect: correctIsTrue,
          position: 1,
        ),
        buildDraftOption(
          optionText: 'خطأ',
          isCorrect: !correctIsTrue,
          position: 2,
        ),
      ],
      if (meta != null) 'meta': meta,
    };
  }

  static Map<String, dynamic> buildShortAnswerQuestion({
    String? stableQuestionKey,
    String origin = 'manual',
    required String questionText,
    required String correctTextAnswer,
    double points = 1,
    int position = 1,
    String? explanation,
    bool isActive = true,
    bool isArchived = false,
    Map<String, dynamic>? meta,
  }) {
    return {
      if (stableQuestionKey != null) 'stable_question_key': stableQuestionKey,
      'origin': origin,
      'type': 'short_answer',
      'question_text': questionText,
      'correct_text_answer': correctTextAnswer,
      'points': points,
      'position': position,
      'explanation': explanation,
      'is_active': isActive,
      'is_archived': isArchived,
      'options': const [],
      if (meta != null) 'meta': meta,
    };
  }

  // ============================================================
  // Payload Builders - Student
  // ============================================================

  static Map<String, dynamic> buildStudentOptionAnswer({
    required String stableQuestionKey,
    required int selectedOptionId,
  }) {
    return {
      'stable_question_key': stableQuestionKey,
      'selected_option_id': selectedOptionId,
    };
  }

  static Map<String, dynamic> buildStudentTextAnswer({
    required String stableQuestionKey,
    required String answerText,
  }) {
    return {
      'stable_question_key': stableQuestionKey,
      'answer_text': answerText,
    };
  }

  // ============================================================
  // Response Helpers
  // ============================================================

  static Map<String, dynamic>? extractExerciseSet(Map<String, dynamic>? bundle) {
    if (bundle == null) return null;
    final value = bundle['exercise_set'];
    return value is Map<String, dynamic> ? value : null;
  }

  static Map<String, dynamic>? extractVersion(Map<String, dynamic>? bundle) {
    if (bundle == null) return null;
    final value = bundle['version'];
    return value is Map<String, dynamic> ? value : null;
  }

  static Map<String, dynamic>? extractLatestAttempt(Map<String, dynamic>? bundle) {
    if (bundle == null) return null;
    final value = bundle['latest_attempt'];
    return value is Map<String, dynamic> ? value : null;
  }

  static Map<String, dynamic>? extractSyncSummary(Map<String, dynamic>? bundle) {
    if (bundle == null) return null;
    final value = bundle['sync_summary'];
    return value is Map<String, dynamic> ? value : null;
  }
}