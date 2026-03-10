import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class HumanChatService {
  static const String chatBaseUrl = '$baseUrl/chat';

  /// Open or create a private conversation
  static Future<Map<String, dynamic>?> openPrivateChat({
    required String teacherCode,
    required String academicId,
    String role = 'student',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$chatBaseUrl/conversations/open'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'teacher_code': teacherCode,
          'academic_id': academicId,
          'as': role,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body)['conversation'];
      }
      return null;
    } catch (e) {
      print('Error opening private chat: $e');
      return null;
    }
  }

  /// Open or create a group chat for a class
  static Future<Map<String, dynamic>?> openGroupChat({
    required String teacherCode,
    required int classSectionId,
    String role = 'student',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$chatBaseUrl/conversations/open-group'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'teacher_code': teacherCode,
          'class_section_id': classSectionId,
          'as': role,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body)['conversation'];
      }
      return null;
    } catch (e) {
      print('Error opening group chat: $e');
      return null;
    }
  }

  /// Fetch all conversations for a student
  static Future<List<dynamic>> getStudentConversations(String academicId) async {
    try {
      final response = await http.get(
        Uri.parse('$chatBaseUrl/conversations/student?academic_id=$academicId'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body)['conversations'];
      }
      return [];
    } catch (e) {
      print('Error fetching student conversations: $e');
      return [];
    }
  }

  /// Fetch messages for a specific conversation
  static Future<List<dynamic>> getMessages(int conversationId, String role, {String? academicId, String? teacherCode}) async {
    try {
      String url = '$chatBaseUrl/conversations/$conversationId/messages?as=$role';
      if (academicId != null) url += '&academic_id=$academicId';
      if (teacherCode != null) url += '&teacher_code=$teacherCode';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return json.decode(response.body)['messages'];
      }
      return [];
    } catch (e) {
      print('Error fetching messages: $e');
      return [];
    }
  }

  /// Send a message
  static Future<bool> sendMessage({
    required int conversationId,
    required String message,
    required String senderType,
    String? academicId,
    String? teacherCode,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$chatBaseUrl/conversations/$conversationId/messages'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'sender_type': senderType,
          'body': message,
          if (academicId != null) 'academic_id': academicId,
          if (teacherCode != null) 'teacher_code': teacherCode,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error sending message: $e');
      return false;
    }
  }
}
