import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import '../config/config.dart';

class AIService {
  static String get baseUrl => AppConfig.aiBaseUrl;

  /// Uploads a PDF file to the AI backend for extraction and chunking
  static Future<Map<String, dynamic>?> uploadPDF(PlatformFile file) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload-pdf/'),
      );
      
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path!,
          filename: file.name,
        ),
      );

      print('Uploading file to AI server: ${file.name}');
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Upload successful: ${data['message']}');
        return data;
      } else {
        print('Failed to upload PDF. Status Code: ${response.statusCode}');
        print('Response Body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception during PDF upload: $e');
      return null;
    }
  }

  /// Sends a chat message to the AI Tutor
  static Future<Map<String, dynamic>?> sendChatMessage(String message, {String? sessionId}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chat/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'message': message,
          if (sessionId != null) 'session_id': sessionId,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Failed to get response from AI. Status Code: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Exception during chat request: $e');
      return null;
    }
  }

  /// Fetches adaptive exercises from Dashboard API (which uses AI)
  static Future<Map<String, dynamic>?> getAdaptiveExercises(int studentId, String topic) async {
    try {
      // Use dashboard API because it tracks database history
      final String dashboardUrl = "${AppConfig.baseUrl}/api/ai/adaptive-exercises";
      final response = await http.post(
        Uri.parse(dashboardUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'student_id': studentId,
          'topic': topic,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Error fetching adaptive exercises: $e');
      return null;
    }
  }

  /// Submits student response to a generated exercise
  static Future<bool> submitResponse({
    required int studentId,
    required int exerciseId,
    required String answer,
    double? timeTaken,
  }) async {
    try {
      final String dashboardUrl = "${AppConfig.baseUrl}/api/ai/submit-response";
      final response = await http.post(
        Uri.parse(dashboardUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'student_id': studentId,
          'exercise_id': exerciseId,
          'answer': answer,
          'time_taken': timeTaken,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error submitting response: $e');
      return false;
    }
  }
  /// Generates a daily analytical report for a teacher
  static Future<Map<String, dynamic>?> getTeacherDailyReport({
    required String teacherName,
    required Map<String, dynamic> classStats,
    required List<Map<String, dynamic>> studentIssues,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/teacher-daily-report/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'teacher_name': teacherName,
          'class_stats': classStats,
          'student_issues': studentIssues,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Failed to get teacher report. Status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Exception during teacher report request: $e');
      return null;
    }
  }
}
