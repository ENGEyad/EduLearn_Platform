import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'api_helpers.dart';

class ChatService {
  static Map<String, String> _headers() => const {
        'Accept': 'application/json',
        'Content-Type': 'application/x-www-form-urlencoded',
      };

  // ===== Teacher =====

  static Future<Map<String, dynamic>> openTeacherConversation({
    required String teacherCode,
    required String academicId,
    int? classSectionId,
    int? subjectId,
  }) async {
    final url = Uri.parse('$baseUrl/chat/conversations/open');

    final body = <String, String>{
      'teacher_code': teacherCode,
      'academic_id': academicId,
      'as': 'teacher',
      if (classSectionId != null) 'class_section_id': classSectionId.toString(),
      if (subjectId != null) 'subject_id': subjectId.toString(),
    };

    final response = await http.post(
      url,
      headers: _headers(),
      body: body,
    );

    late final Map<String, dynamic> data;
    try {
      data = ApiHelpers.decodeJsonAsMap(response.body);
    } catch (_) {
      throw Exception('Invalid server response.');
    }

    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        data['success'] == true &&
        data['conversation'] is Map) {
      return Map<String, dynamic>.from(
          data['conversation'] as Map<dynamic, dynamic>);
    } else {
      final msg = data['message']?.toString() ?? 'Failed to open conversation';
      throw Exception(msg);
    }
  }

  static Future<List<dynamic>> fetchTeacherConversations({
    required String teacherCode,
  }) async {
    final uri =
        Uri.parse('$baseUrl/chat/conversations/teacher?teacher_code=$teacherCode');

    final response = await http.get(
      uri,
      headers: _headers(),
    );

    late final Map<String, dynamic> data;
    try {
      data = ApiHelpers.decodeJsonAsMap(response.body);
    } catch (_) {
      throw Exception('Invalid server response.');
    }

    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        data['success'] == true &&
        data['conversations'] is List) {
      return data['conversations'] as List<dynamic>;
    } else {
      final msg =
          data['message']?.toString() ?? 'Failed to load teacher conversations';
      throw Exception(msg);
    }
  }

  static Future<List<dynamic>> fetchConversationMessagesAsTeacher({
    required int conversationId,
    required String teacherCode,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/chat/conversations/$conversationId/messages'
      '?as=teacher&teacher_code=$teacherCode',
    );

    final response = await http.get(
      uri,
      headers: _headers(),
    );

    late final Map<String, dynamic> data;
    try {
      data = ApiHelpers.decodeJsonAsMap(response.body);
    } catch (_) {
      throw Exception('Invalid server response.');
    }

    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        data['success'] == true &&
        data['messages'] is List) {
      return data['messages'] as List<dynamic>;
    } else {
      final msg = data['message']?.toString() ?? 'Failed to load messages';
      throw Exception(msg);
    }
  }

  static Future<Map<String, dynamic>> sendMessageAsTeacher({
    required int conversationId,
    required String teacherCode,
    required String messageBody,
  }) async {
    final url =
        Uri.parse('$baseUrl/chat/conversations/$conversationId/messages');

    final response = await http.post(
      url,
      headers: _headers(),
      body: {
        'sender_type': 'teacher',
        'teacher_code': teacherCode,
        'body': messageBody,
      },
    );

    late final Map<String, dynamic> data;
    try {
      data = ApiHelpers.decodeJsonAsMap(response.body);
    } catch (_) {
      throw Exception('Invalid server response.');
    }

    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        data['success'] == true &&
        data['message'] is Map) {
      return Map<String, dynamic>.from(
          data['message'] as Map<dynamic, dynamic>);
    } else {
      final msg = data['message']?.toString() ?? 'Failed to send message';
      throw Exception(msg);
    }
  }

  // ===== Student =====

  static Future<Map<String, dynamic>> openStudentConversation({
    required String academicId,
    required String teacherCode,
    int? classSectionId,
    int? subjectId,
  }) async {
    final url = Uri.parse('$baseUrl/chat/conversations/open');

    final body = <String, String>{
      'academic_id': academicId,
      'teacher_code': teacherCode,
      'as': 'student',
      if (classSectionId != null) 'class_section_id': classSectionId.toString(),
      if (subjectId != null) 'subject_id': subjectId.toString(),
    };

    final response = await http.post(
      url,
      headers: _headers(),
      body: body,
    );

    late final Map<String, dynamic> data;
    try {
      data = ApiHelpers.decodeJsonAsMap(response.body);
    } catch (_) {
      throw Exception('Invalid server response.');
    }

    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        data['success'] == true &&
        data['conversation'] is Map) {
      return Map<String, dynamic>.from(
          data['conversation'] as Map<dynamic, dynamic>);
    } else {
      final msg = data['message']?.toString() ?? 'Failed to open conversation';
      throw Exception(msg);
    }
  }

  static Future<List<dynamic>> fetchStudentConversations({
    required String academicId,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/chat/conversations/student?academic_id=$academicId',
    );

    final response = await http.get(
      uri,
      headers: _headers(),
    );

    late final Map<String, dynamic> data;
    try {
      data = ApiHelpers.decodeJsonAsMap(response.body);
    } catch (_) {
      throw Exception('Invalid server response.');
    }

    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        data['success'] == true &&
        data['conversations'] is List) {
      return data['conversations'] as List<dynamic>;
    } else {
      final msg =
          data['message']?.toString() ?? 'Failed to load student conversations';
      throw Exception(msg);
    }
  }

  static Future<List<dynamic>> fetchConversationMessagesAsStudent({
    required int conversationId,
    required String academicId,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/chat/conversations/$conversationId/messages'
      '?as=student&academic_id=$academicId',
    );

    final response = await http.get(
      uri,
      headers: _headers(),
    );

    late final Map<String, dynamic> data;
    try {
      data = ApiHelpers.decodeJsonAsMap(response.body);
    } catch (_) {
      throw Exception('Invalid server response.');
    }

    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        data['success'] == true &&
        data['messages'] is List) {
      return data['messages'] as List<dynamic>;
    } else {
      final msg = data['message']?.toString() ?? 'Failed to load messages';
      throw Exception(msg);
    }
  }

  static Future<Map<String, dynamic>> sendMessageAsStudent({
    required int conversationId,
    required String academicId,
    required String messageBody,
  }) async {
    final url =
        Uri.parse('$baseUrl/chat/conversations/$conversationId/messages');

    final response = await http.post(
      url,
      headers: _headers(),
      body: {
        'sender_type': 'student',
        'academic_id': academicId,
        'body': messageBody,
      },
    );

    late final Map<String, dynamic> data;
    try {
      data = ApiHelpers.decodeJsonAsMap(response.body);
    } catch (_) {
      throw Exception('Invalid server response.');
    }

    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        data['success'] == true &&
        data['message'] is Map) {
      return Map<String, dynamic>.from(
          data['message'] as Map<dynamic, dynamic>);
    } else {
      final msg = data['message']?.toString() ?? 'Failed to send message';
      throw Exception(msg);
    }
  }
}
