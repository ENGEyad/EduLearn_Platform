import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';
import 'api_helpers.dart';

class AuthService {
  static const String pusherApiKey = 'qvgof2dxcwduaq9zvnyq';
  static const String pusherCluster = 'mt1';

  static String get rootUrl => serverRoot;

  static Future<Map<String, dynamic>> authStudent({
    required String fullName,
    required String academicId,
    String? email,
    String? password,
  }) async {
    final url = Uri.parse('$baseUrl/student/auth');

    final response = await http.post(
      url,
      headers: {'Accept': 'application/json'},
      body: {
        'full_name': fullName,
        'academic_id': academicId,
        if (email != null && email.isNotEmpty) 'email': email,
        if (password != null && password.isNotEmpty) 'password': password,
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
        data['student'] is Map<String, dynamic>) {
      await saveSession(data, 'student');
      return data;
    } else {
      final msg = data['message']?.toString() ?? 'Auth failed';
      throw Exception(msg);
    }
  }

  static Future<Map<String, dynamic>> authTeacher({
    required String fullName,
    required String teacherCode,
    String? email,
    String? password,
  }) async {
    final url = Uri.parse('$baseUrl/teacher/auth');
    
    // ✅ DEBUG LOG
    print('📡 AUTH REQUEST: $url');
    print('📡 BODY: {full_name: $fullName, teacher_code: $teacherCode}');

    http.Response? response;
    Map<String, dynamic>? data;

    try {
      response = await http.post(
        url,
        headers: {'Accept': 'application/json'},
        body: {
          'full_name': fullName,
          'teacher_code': teacherCode,
          if (email != null && email.isNotEmpty) 'email': email,
          if (password != null && password.isNotEmpty) 'password': password,
        },
      ).timeout(const Duration(seconds: 10));

      if (response != null) {
        print('📡 RESPONSE STATUS: ${response.statusCode}');
        print('📡 RESPONSE BODY: ${response.body}');

        try {
          data = ApiHelpers.decodeJsonAsMap(response.body);
        } catch (e) {
          print('❌ JSON DECODE ERROR: $e');
          throw Exception('Invalid server response.');
        }
      } else {
        throw Exception('Server did not respond in time.');
      }
    } catch (e) {
      print('❌ AUTH ERROR: $e');
      rethrow;
    }

    if (response != null &&
        response.statusCode >= 200 &&
        response.statusCode < 300 &&
        data != null &&
        data['success'] == true &&
        data['teacher'] is Map<String, dynamic>) {
      await saveSession(data, 'teacher');
      return data;
    } else {
      final msg = data?['message']?.toString() ?? 'Auth failed';
      throw Exception(msg);
    }
  }

  // =================== Session Management ===================

  static Future<void> saveSession(Map<String, dynamic> data, String type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_session', jsonEncode(data));
    await prefs.setString('user_type', type);
  }

  static Future<Map<String, dynamic>?> getSession() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionStr = prefs.getString('user_session');
    if (sessionStr == null) return null;
    try {
      return jsonDecode(sessionStr) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> getUserType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_type');
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_session');
    await prefs.remove('user_type');
  }
}
