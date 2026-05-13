import 'package:dio/dio.dart';
import 'api_client.dart';

class LessonExerciseService {
  LessonExerciseService();

  // ============================================================
  // Teacher APIs
  // ============================================================

  Future<Map<String, dynamic>?> fetchTeacherExerciseDraft({
    required int lessonId,
  }) async {
    try {
      final response = await ApiClient.instance.get(
        '/teacher/lessons/$lessonId/exercise-set/draft',
      );
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true) {
        return data['data'] as Map<String, dynamic>?;
      }
      throw Exception(data['message'] ?? 'Failed to fetch exercise draft');
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Network error');
    }
  }

  Future<Map<String, dynamic>> saveTeacherExerciseDraft({
    required int lessonId,
    String? title,
    String generationSource = 'manual',
    required List<Map<String, dynamic>> questions,
  }) async {
    final payload = <String, dynamic>{
      'title': title,
      'generation_source': generationSource,
      'questions': questions,
    };
    try {
      final response = await ApiClient.instance.post(
        '/teacher/lessons/$lessonId/exercise-set/save-draft',
        data: payload,
      );
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true) {
        final result = data['data'];
        if (result is Map<String, dynamic>) return result;
        throw Exception('Exercise draft was not returned by the server.');
      }
      throw Exception(data['message'] ?? 'Failed to save exercise draft');
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Network error');
    }
  }

  Future<Map<String, dynamic>> publishTeacherExerciseSet({
    required int lessonId,
  }) async {
    try {
      final response = await ApiClient.instance.post(
        '/teacher/lessons/$lessonId/exercise-set/publish',
      );
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true) {
        final result = data['data'];
        if (result is Map<String, dynamic>) return result;
        throw Exception('Published version was not returned by the server.');
      }
      throw Exception(data['message'] ?? 'Failed to publish exercise set');
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Network error');
    }
  }

  Future<Map<String, dynamic>> archiveTeacherExerciseSet({
    required int lessonId,
  }) async {
    try {
      final response = await ApiClient.instance.post(
        '/teacher/lessons/$lessonId/exercise-set/archive',
      );
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true) {
        final result = data['data'];
        if (result is Map<String, dynamic>) return result;
        throw Exception('Archived exercise set was not returned by the server.');
      }
      throw Exception(data['message'] ?? 'Failed to archive exercise set');
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Network error');
    }
  }

  Future<Map<String, dynamic>> unarchiveTeacherExerciseSet({
    required int lessonId,
  }) async {
    try {
      final response = await ApiClient.instance.post(
        '/teacher/lessons/$lessonId/exercise-set/unarchive',
      );
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true) {
        final result = data['data'];
        if (result is Map<String, dynamic>) return result;
        throw Exception('Unarchived exercise set was not returned by the server.');
      }
      throw Exception(data['message'] ?? 'Failed to unarchive exercise set');
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Network error');
    }
  }

  Future<Map<String, dynamic>> deleteDraftQuestion({
    required int lessonId,
    required String stableQuestionKey,
  }) async {
    try {
      final response = await ApiClient.instance.delete(
        '/teacher/lessons/$lessonId/exercise-set/questions/$stableQuestionKey',
      );
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true) {
        final result = data['data'];
        if (result is Map<String, dynamic>) return result;
        throw Exception('Deleted draft question was not returned by the server.');
      }
      throw Exception(data['message'] ?? 'Failed to delete draft question');
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Network error');
    }
  }

  Future<Map<String, dynamic>> restoreDraftQuestion({
    required int lessonId,
    required String stableQuestionKey,
  }) async {
    try {
      final response = await ApiClient.instance.post(
        '/teacher/lessons/$lessonId/exercise-set/questions/$stableQuestionKey/restore',
      );
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true) {
        final result = data['data'];
        if (result is Map<String, dynamic>) return result;
        throw Exception('Restored draft question was not returned by the server.');
      }
      throw Exception(data['message'] ?? 'Failed to restore draft question');
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Network error');
    }
  }

  Future<Map<String, dynamic>> archiveDraftQuestion({
    required int lessonId,
    required String stableQuestionKey,
  }) async {
    try {
      final response = await ApiClient.instance.post(
        '/teacher/lessons/$lessonId/exercise-set/questions/$stableQuestionKey/archive',
      );
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true) {
        final result = data['data'];
        if (result is Map<String, dynamic>) return result;
        throw Exception('Archived draft question was not returned by the server.');
      }
      throw Exception(data['message'] ?? 'Failed to archive draft question');
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Network error');
    }
  }

  Future<Map<String, dynamic>> unarchiveDraftQuestion({
    required int lessonId,
    required String stableQuestionKey,
  }) async {
    try {
      final response = await ApiClient.instance.post(
        '/teacher/lessons/$lessonId/exercise-set/questions/$stableQuestionKey/unarchive',
      );
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true) {
        final result = data['data'];
        if (result is Map<String, dynamic>) return result;
        throw Exception('Unarchived draft question was not returned by the server.');
      }
      throw Exception(data['message'] ?? 'Failed to unarchive draft question');
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Network error');
    }
  }

  // ============================================================
  // Student APIs
  // ============================================================

  Future<Map<String, dynamic>?> fetchStudentCurrentExerciseBundle({
    required int lessonId,
  }) async {
    try {
      final response = await ApiClient.instance.get(
        '/student/lessons/$lessonId/exercise-set/current',
      );
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true) {
        return data['data'] as Map<String, dynamic>?;
      }
      throw Exception(data['message'] ?? 'Failed to fetch current exercise bundle');
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Network error');
    }
  }

  Future<Map<String, dynamic>?> fetchLatestStudentAttempt({
    required int lessonId,
  }) async {
    try {
      final response = await ApiClient.instance.get(
        '/student/lessons/$lessonId/exercise-set/latest-attempt',
      );
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true) {
        final result = data['data'];
        if (result is Map<String, dynamic>) return result;
        return null;
      }
      throw Exception(data['message'] ?? 'Failed to fetch latest attempt');
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Network error');
    }
  }

  Future<Map<String, dynamic>> saveStudentExerciseAnswers({
    required int lessonId,
    required List<Map<String, dynamic>> answers,
    int timeSpentSeconds = 0,
  }) async {
    try {
      final response = await ApiClient.instance.post(
        '/student/lessons/$lessonId/exercise-set/save',
        data: {
          'answers': answers,
          'time_spent_seconds': timeSpentSeconds,
        },
      );
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true) {
        final result = data['data'];
        if (result is Map<String, dynamic>) return result;
        throw Exception('Saved attempt data was not returned by the server.');
      }
      throw Exception(data['message'] ?? 'Failed to save exercise answers');
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Network error');
    }
  }

  Future<Map<String, dynamic>> submitStudentExerciseAnswers({
    required int lessonId,
    required List<Map<String, dynamic>> answers,
    int timeSpentSeconds = 0,
  }) async {
    try {
      final response = await ApiClient.instance.post(
        '/student/lessons/$lessonId/exercise-set/submit',
        data: {
          'answers': answers,
          'time_spent_seconds': timeSpentSeconds,
        },
      );
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true) {
        final result = data['data'];
        if (result is Map<String, dynamic>) return result;
        throw Exception('Submitted attempt data was not returned by the server.');
      }
      throw Exception(data['message'] ?? 'Failed to submit exercise answers');
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Network error');
    }
  }

  // ============================================================
  // Payload Builders - Teacher (static, unchanged)
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
    String? trueOptionStableKey,
    String? falseOptionStableKey,
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
          stableOptionKey: trueOptionStableKey,
          optionText: 'صح',
          isCorrect: correctIsTrue,
          position: 1,
        ),
        buildDraftOption(
          stableOptionKey: falseOptionStableKey,
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
  // Payload Builders - Student (static, unchanged)
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
  // Response Helpers (static, unchanged)
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

  static List<Map<String, dynamic>> extractVersionItems(Map<String, dynamic>? bundle) {
    final version = extractVersion(bundle);
    if (version == null) return [];
    final items = version['items'];
    if (items is! List) return [];
    return items.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static List<Map<String, dynamic>> extractAttemptAnswers(Map<String, dynamic>? attempt) {
    if (attempt == null) return [];
    final answers = attempt['answers'];
    if (answers is! List) return [];
    return answers.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static List<Map<String, dynamic>> extractQuestionOptions(Map<String, dynamic>? question) {
    if (question == null) return [];
    final options = question['options'];
    if (options is! List) return [];
    return options.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  // ============================================================
  // Student Screen Helpers (static, unchanged)
  // ============================================================

  static String questionStableKey(Map<String, dynamic>? question) {
    return (question?['stable_question_key'] ?? '').toString();
  }

  static String questionType(Map<String, dynamic>? question) {
    return (question?['type'] ?? '').toString();
  }

  static String questionChangeStatus(Map<String, dynamic>? question) {
    return (question?['change_status_from_previous'] ?? 'unchanged').toString();
  }

  static bool isQuestionActive(Map<String, dynamic>? question) {
    return (question?['is_active'] ?? true) == true;
  }

  static bool isQuestionNew(Map<String, dynamic>? question) {
    return questionChangeStatus(question) == 'new';
  }

  static bool isQuestionUpdated(Map<String, dynamic>? question) {
    return questionChangeStatus(question) == 'updated';
  }

  static bool isQuestionRestored(Map<String, dynamic>? question) {
    return questionChangeStatus(question) == 'restored';
  }

  static bool isQuestionDeleted(Map<String, dynamic>? question) {
    return questionChangeStatus(question) == 'deleted' || !isQuestionActive(question);
  }

  static String answerState(Map<String, dynamic>? answer) {
    return (answer?['answer_state'] ?? 'active').toString();
  }

  static bool isAnswerReadonly(Map<String, dynamic>? answer) {
    return answerState(answer) == 'readonly_history';
  }

  static bool isAnswerNeedsReanswer(Map<String, dynamic>? answer) {
    return answerState(answer) == 'needs_reanswer';
  }

  static bool isAnswerDeletedQuestion(Map<String, dynamic>? answer) {
    return answerState(answer) == 'deleted_question';
  }

  static bool attemptHasPendingChanges(Map<String, dynamic>? attempt) {
    return (attempt?['has_pending_changes'] ?? false) == true;
  }

  static String attemptStatus(Map<String, dynamic>? attempt) {
    return (attempt?['status'] ?? '').toString();
  }

  static bool attemptIsLocked(Map<String, dynamic>? attempt) {
    final status = attemptStatus(attempt);
    final pendingChanges = attemptHasPendingChanges(attempt);
    return (status == 'graded' || status == 'submitted') && !pendingChanges;
  }

  static Map<String, dynamic>? findAnswerForQuestion({
    required Map<String, dynamic>? attempt,
    required Map<String, dynamic>? question,
  }) {
    final stableKey = questionStableKey(question);
    if (stableKey.isEmpty) return null;
    final answers = extractAttemptAnswers(attempt);
    for (final answer in answers) {
      if ((answer['stable_question_key'] ?? '').toString() == stableKey) {
        return answer;
      }
    }
    return null;
  }

  static bool shouldQuestionBeEditable({
    required Map<String, dynamic>? question,
    required Map<String, dynamic>? attempt,
  }) {
    if (isQuestionDeleted(question)) return false;
    final answer = findAnswerForQuestion(attempt: attempt, question: question);
    if (isAnswerReadonly(answer)) return false;
    if (isAnswerDeletedQuestion(answer)) return false;
    return true;
  }

  static bool shouldShowQuestionFeedback({
    required Map<String, dynamic>? question,
    required Map<String, dynamic>? attempt,
  }) {
    final answer = findAnswerForQuestion(attempt: attempt, question: question);
    if (answer == null) return false;
    final feedback = answer['feedback_snapshot'];
    if (feedback is! Map<String, dynamic>) return false;
    return isAnswerReadonly(answer);
  }

  static String? feedbackExplanation(Map<String, dynamic>? answer) {
    final feedback = answer?['feedback_snapshot'];
    if (feedback is Map<String, dynamic>) {
      final value = feedback['explanation'];
      if (value == null) return null;
      final text = value.toString().trim();
      return text.isEmpty ? null : text;
    }
    return null;
  }

  static String? feedbackCorrectTextAnswer(Map<String, dynamic>? answer) {
    final feedback = answer?['feedback_snapshot'];
    if (feedback is Map<String, dynamic>) {
      final value = feedback['correct_text_answer'];
      if (value == null) return null;
      final text = value.toString().trim();
      return text.isEmpty ? null : text;
    }
    return null;
  }

  static bool answerIsCorrect(Map<String, dynamic>? answer) {
    return (answer?['is_correct'] ?? false) == true;
  }

  static double answerAwardedPoints(Map<String, dynamic>? answer) {
    final value = answer?['awarded_points'];
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  static int readInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  static double readDouble(dynamic value, {double fallback = 0}) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  static String questionChangeLabel(String changeStatus) {
    switch (changeStatus) {
      case 'new':
        return 'جديد';
      case 'updated':
        return 'تم التعديل';
      case 'restored':
        return 'تمت الاستعادة';
      case 'deleted':
        return 'محذوف';
      default:
        return 'ثابت';
    }
  }

  static bool hasAnySubmittableQuestion({
    required List<Map<String, dynamic>> questions,
    required Map<String, dynamic>? attempt,
  }) {
    for (final question in questions) {
      if (shouldQuestionBeEditable(question: question, attempt: attempt)) {
        return true;
      }
    }
    return false;
  }

  static bool hasAnyPendingQuestionNeedingAnswer({
    required List<Map<String, dynamic>> questions,
    required Map<String, dynamic>? attempt,
  }) {
    for (final question in questions) {
      final answer = findAnswerForQuestion(attempt: attempt, question: question);
      if (isAnswerNeedsReanswer(answer)) {
        return true;
      }
    }
    return false;
  }
}