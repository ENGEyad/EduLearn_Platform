import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ExerciseLocalStore {
  /// مفتاح الحفظ: نربطه برقم الدرس والطالب لكي لا تختلط الإجابات
  static String _getKey(int lessonId, String academicId) =>
      'exercises_answers_${lessonId}_$academicId';

  /// حفظ إجابة سؤال محدد
  static Future<void> saveAnswer({
    required int lessonId,
    required String academicId,
    required int questionId,
    int? optionId,
    bool? answerBool,
    String? answerText,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getKey(lessonId, academicId);
    
    // جلب الإجابات السابقة
    final raw = prefs.getString(key);
    Map<String, dynamic> answers = {};
    if (raw != null && raw.isNotEmpty) {
      try {
        answers = jsonDecode(raw) as Map<String, dynamic>;
      } catch (_) {}
    }

    // إضافة الإجابة الجديدة
    answers[questionId.toString()] = {
      'question_id': questionId,
      if (optionId != null) 'option_id': optionId,
      if (answerBool != null) 'answer_bool': answerBool,
      if (answerText != null) 'answer_text': answerText,
    };

    // حفظها مرة أخرى
    await prefs.setString(key, jsonEncode(answers));
  }

  /// استرجاع كل إجابات الطالب للدرس الحالي
  static Future<Map<String, dynamic>> getAllAnswers(
    int lessonId,
    String academicId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getKey(lessonId, academicId);
    
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return {};

    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  /// مسح الإجابات للدرس في حال رغب الطالب في إعادة المحاولة
  static Future<void> clearAnswers(int lessonId, String academicId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getKey(lessonId, academicId);
    await prefs.remove(key);
  }
}
