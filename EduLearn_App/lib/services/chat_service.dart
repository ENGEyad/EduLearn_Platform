import 'package:dio/dio.dart';
import 'api_client.dart';
// import 'api_helpers.dart';

class ChatMessagePage {
  final List<Map<String, dynamic>> messages;
  final int? nextCursor;

  const ChatMessagePage({
    required this.messages,
    required this.nextCursor,
  });

  factory ChatMessagePage.fromResponse(Map<String, dynamic> data) {
    final rawMessages = data['messages'];
    final parsedMessages = <Map<String, dynamic>>[];

    if (rawMessages is List) {
      for (final item in rawMessages) {
        if (item is Map) {
          parsedMessages.add(Map<String, dynamic>.from(item));
        }
      }
    }

    final rawCursor = data['next_cursor'];
    int? nextCursor;
    if (rawCursor is int) {
      nextCursor = rawCursor;
    } else if (rawCursor is String) {
      nextCursor = int.tryParse(rawCursor);
    }

    return ChatMessagePage(messages: parsedMessages, nextCursor: nextCursor);
  }
}

class ChatService {
  static Future<Map<String, dynamic>> openTeacherConversation({
    required String academicId, // الطرف الآخر
    int? classSectionId,
    int? subjectId,
  }) async {
    try {
      final response = await ApiClient.instance.post('/chat/conversations/open', data: {
        'academic_id': academicId,
        'class_section_id': classSectionId,
        'subject_id': subjectId,
      });
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true && data['conversation'] is Map) {
        return Map<String, dynamic>.from(data['conversation'] as Map);
      }
      throw Exception(data['message'] ?? 'Failed to open conversation');
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Network error');
    }
  }

  static Future<List<dynamic>> fetchTeacherConversations() async {
    try {
      final response = await ApiClient.instance.get('/chat/conversations/teacher');
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true && data['conversations'] is List) {
        return data['conversations'] as List;
      }
      throw Exception(data['message'] ?? 'Failed to load teacher conversations');
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Network error');
    }
  }

  static Future<ChatMessagePage> fetchConversationMessagesAsTeacher({
    required int conversationId,
    int? limit,
    int? beforeId,
  }) async {
    try {
      final query = <String, dynamic>{
        'as': 'teacher',
        if (limit != null) 'limit': limit,
        if (beforeId != null) 'before_id': beforeId,
      };
      final response = await ApiClient.instance.get(
        '/chat/conversations/$conversationId/messages',
        queryParameters: query,
      );
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true && data['messages'] is List) {
        return ChatMessagePage.fromResponse(data);
      }
      throw Exception(data['message'] ?? 'Failed to load messages');
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Network error');
    }
  }

  static Future<Map<String, dynamic>> sendMessageAsTeacher({
    required int conversationId,
    required String messageBody,
  }) async {
    try {
      final response = await ApiClient.instance.post(
        '/chat/conversations/$conversationId/messages',
        data: {
          'sender_type': 'teacher',
          'body': messageBody,
        },
      );
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true && data['message'] is Map) {
        return Map<String, dynamic>.from(data['message'] as Map);
      }
      throw Exception(data['message'] ?? 'Failed to send message');
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Network error');
    }
  }

  static Future<Map<String, dynamic>> openStudentConversation({
    required String teacherCode, // الطرف الآخر
    int? classSectionId,
    int? subjectId,
  }) async {
    try {
      final response = await ApiClient.instance.post('/chat/conversations/open', data: {
        'teacher_code': teacherCode,
        'class_section_id': classSectionId,
        'subject_id': subjectId,
      });
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true && data['conversation'] is Map) {
        return Map<String, dynamic>.from(data['conversation'] as Map);
      }
      throw Exception(data['message'] ?? 'Failed to open conversation');
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Network error');
    }
  }

  static Future<List<dynamic>> fetchStudentConversations() async {
    try {
      final response = await ApiClient.instance.get('/chat/conversations/student');
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true && data['conversations'] is List) {
        return data['conversations'] as List;
      }
      throw Exception(data['message'] ?? 'Failed to load student conversations');
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Network error');
    }
  }

  static Future<ChatMessagePage> fetchConversationMessagesAsStudent({
    required int conversationId,
    int? limit,
    int? beforeId,
  }) async {
    try {
      final query = <String, dynamic>{
        'as': 'student',
        if (limit != null) 'limit': limit,
        if (beforeId != null) 'before_id': beforeId,
      };
      final response = await ApiClient.instance.get(
        '/chat/conversations/$conversationId/messages',
        queryParameters: query,
      );
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true && data['messages'] is List) {
        return ChatMessagePage.fromResponse(data);
      }
      throw Exception(data['message'] ?? 'Failed to load messages');
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Network error');
    }
  }

  static Future<Map<String, dynamic>> sendMessageAsStudent({
    required int conversationId,
    required String messageBody,
  }) async {
    try {
      final response = await ApiClient.instance.post(
        '/chat/conversations/$conversationId/messages',
        data: {
          'sender_type': 'student',
          'body': messageBody,
        },
      );
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true && data['message'] is Map) {
        return Map<String, dynamic>.from(data['message'] as Map);
      }
      throw Exception(data['message'] ?? 'Failed to send message');
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Network error');
    }
  }

  // ========== Status helpers (delivered, read, typing) ==========
  static Future<void> markConversationDeliveredAsTeacher({
    required int conversationId,
  }) async {
    await _postStatus(conversationId, 'delivered', 'teacher');
  }

  static Future<void> markConversationReadAsTeacher({
    required int conversationId,
  }) async {
    await _postStatus(conversationId, 'read', 'teacher');
  }

  static Future<void> markConversationDeliveredAsStudent({
    required int conversationId,
  }) async {
    await _postStatus(conversationId, 'delivered', 'student');
  }

  static Future<void> markConversationReadAsStudent({
    required int conversationId,
  }) async {
    await _postStatus(conversationId, 'read', 'student');
  }

  static Future<void> sendTypingStartAsTeacher({
    required int conversationId,
  }) async {
    await _postStatus(conversationId, 'typing/start', 'teacher');
  }

  static Future<void> sendTypingStopAsTeacher({
    required int conversationId,
  }) async {
    await _postStatus(conversationId, 'typing/stop', 'teacher');
  }

  static Future<void> sendTypingStartAsStudent({
    required int conversationId,
  }) async {
    await _postStatus(conversationId, 'typing/start', 'student');
  }

  static Future<void> sendTypingStopAsStudent({
    required int conversationId,
  }) async {
    await _postStatus(conversationId, 'typing/stop', 'student');
  }

  // Helper داخلي
  static Future<void> _postStatus(int conversationId, String endpoint, String as) async {
    try {
      final response = await ApiClient.instance.post(
        '/chat/conversations/$conversationId/$endpoint',
        data: {'as': as},
      );
      final data = response.data as Map<String, dynamic>;
      if (data['success'] != true) {
        throw Exception(data['message'] ?? 'Failed to update status');
      }
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Network error');
    }
  }
}