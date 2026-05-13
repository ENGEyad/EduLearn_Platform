import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';
import 'api_helpers.dart';

class AuthService {
  static const String pusherApiKey = 'qvgof2dxcwduaq9zvnyq';
  static const String pusherCluster = 'mt1';

  static final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static Future<Map<String, dynamic>> authStudent({
    required String fullName,
    required String academicId,
    String? email,
    String? password,
  }) async {
    final url = Uri.parse('$baseUrl/student/auth');
    final body = {
      'full_name': fullName,
      'academic_id': academicId,
    };
    // لا نرسل email/password لأنهما غير مطلوبين وقد يسبب مشكلة
    final response = await http.post(
      url,
      headers: {'Accept': 'application/json'},
      body: body,
    );

    final data = ApiHelpers.decodeJsonAsMap(response.body);

    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        data['success'] == true &&
        data['student'] is Map<String, dynamic> &&
        data['token'] is String) {
      final token = data['token'] as String;
      final student = data['student'] as Map<String, dynamic>;

      await _secureStorage.write(key: 'auth_token', value: token);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', jsonEncode(student));
      await prefs.setString('user_type', 'student');
      return data;
    } else {
      throw Exception(data['message'] ?? 'Auth failed');
    }
  }

  static Future<Map<String, dynamic>> authTeacher({
    required String fullName,
    required String teacherCode,
    String? email,
    String? password,
  }) async {
    final url = Uri.parse('$baseUrl/teacher/auth');
    final body = {
      'full_name': fullName,
      'teacher_code': teacherCode,
    };
    final response = await http.post(
      url,
      headers: {'Accept': 'application/json'},
      body: body,
    );

    final data = ApiHelpers.decodeJsonAsMap(response.body);

    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        data['success'] == true &&
        data['teacher'] is Map<String, dynamic> &&
        data['token'] is String) {
      final token = data['token'] as String;
      final teacher = data['teacher'] as Map<String, dynamic>;

      await _secureStorage.write(key: 'auth_token', value: token);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', jsonEncode(teacher));
      await prefs.setString('user_type', 'teacher');
      return data;
    } else {
      throw Exception(data['message'] ?? 'Auth failed');
    }
  }

  static Future<String?> getToken() async {
    return await _secureStorage.read(key: 'auth_token');
  }

  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final dataStr = prefs.getString('user_data');
    if (dataStr == null) return null;
    try {
      return jsonDecode(dataStr) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> getUserType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_type');
  }

  static Future<void> logout() async {
    await _secureStorage.delete(key: 'auth_token');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data');
    await prefs.remove('user_type');
  }
}