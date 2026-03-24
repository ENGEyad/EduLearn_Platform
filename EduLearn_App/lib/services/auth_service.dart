import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';
import 'api_helpers.dart';

class AuthService {
  static const String pusherApiKey = 'qvgof2dxcwduaq9zvnyq';
  static const String pusherCluster = 'mt1';

  static String get rootUrl => serverRoot;

  // ==================== Authentication ====================

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

    final response = await http.post(
      url,
      headers: {'Accept': 'application/json'},
      body: {
        'full_name': fullName,
        'teacher_code': teacherCode,
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
        data['teacher'] is Map<String, dynamic>) {
      await saveSession(data, 'teacher');
      return data;
    } else {
      final msg = data['message']?.toString() ?? 'Auth failed';
      throw Exception(msg);
    }
  }

  // ==================== Session Management ====================

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

// ==================== Teacher Actions ====================

extension TeacherActions on AuthService {
  static Future<Map<String, dynamic>> updateTeacherProfile({
    required int teacherId,
    String? fullName,
    String? phone,
    String? specialization,
  }) async {
    final url = Uri.parse('$baseUrl/teacher/update/$teacherId');

    final response = await http.put(
      url,
      headers: {'Accept': 'application/json'},
      body: {
        if (fullName != null) 'full_name': fullName,
        if (phone != null) 'phone': phone,
        if (specialization != null) 'specialization': specialization,
      },
    );

    final data = ApiHelpers.decodeJsonAsMap(response.body);

    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        data['success'] == true) {
      return data['teacher'] as Map<String, dynamic>;
    } else {
      final msg = data['message']?.toString() ?? 'Failed to update teacher profile';
      throw Exception(msg);
    }
  }

  static Future<Map<String, dynamic>> updateTeacherEmail({
    required int teacherId,
    required String email,
  }) async {
    final url = Uri.parse('$baseUrl/teacher/update-email/$teacherId');

    final response = await http.put(
      url,
      headers: {'Accept': 'application/json'},
      body: {'email': email},
    );

    final data = ApiHelpers.decodeJsonAsMap(response.body);

    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        data['success'] == true) {
      return data['teacher'] as Map<String, dynamic>;
    } else {
      final msg = data['message']?.toString() ?? 'Failed to update teacher email';
      throw Exception(msg);
    }
  }

  static Future<void> changeTeacherPassword({
    required int teacherId,
    required String currentPassword,
    required String newPassword,
  }) async {
    final url = Uri.parse('$baseUrl/teacher/change-password/$teacherId');

    final response = await http.post(
      url,
      headers: {'Accept': 'application/json'},
      body: {
        'current_password': currentPassword,
        'new_password': newPassword,
      },
    );

    final data = ApiHelpers.decodeJsonAsMap(response.body);

    if (!(response.statusCode >= 200 &&
        response.statusCode < 300 &&
        data['success'] == true)) {
      final msg = data['message']?.toString() ?? 'Failed to change teacher password';
      throw Exception(msg);
    }
  }

  static Future<Map<String, dynamic>> updateTeacherNotifications({
    required int teacherId,
    required Map<String, dynamic> notifications,
  }) async {
    final url = Uri.parse('$baseUrl/teacher/update-notifications/$teacherId');

    final response = await http.put(
      url,
      headers: {'Accept': 'application/json'},
      body: notifications.map((key, value) => MapEntry(key, value.toString())),
    );

    final data = ApiHelpers.decodeJsonAsMap(response.body);

    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        data['success'] == true) {
      return data['teacher'] as Map<String, dynamic>;
    } else {
      final msg = data['message']?.toString() ?? 'Failed to update teacher notifications';
      throw Exception(msg);
    }
  }
}

// ==================== Student Actions ====================

extension StudentActions on AuthService {
  static Future<Map<String, dynamic>> updateStudentProfile({
    required int studentId,
    String? fullName,
    String? phone,
  }) async {
    final url = Uri.parse('$baseUrl/student/update/$studentId');

    final response = await http.put(
      url,
      headers: {'Accept': 'application/json'},
      body: {
        if (fullName != null) 'full_name': fullName,
        if (phone != null) 'phone': phone,
      },
    );

    final data = ApiHelpers.decodeJsonAsMap(response.body);

    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        data['success'] == true) {
      return data['student'] as Map<String, dynamic>;
    } else {
      final msg = data['message']?.toString() ?? 'Failed to update student profile';
      throw Exception(msg);
    }
  }

  static Future<Map<String, dynamic>> updateStudentEmail({
    required int studentId,
    required String email,
  }) async {
    final url = Uri.parse('$baseUrl/student/update-email/$studentId');

    final response = await http.put(
      url,
      headers: {'Accept': 'application/json'},
      body: {'email': email},
    );

    final data = ApiHelpers.decodeJsonAsMap(response.body);

    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        data['success'] == true) {
      return data['student'] as Map<String, dynamic>;
    } else {
      final msg = data['message']?.toString() ?? 'Failed to update student email';
      throw Exception(msg);
    }
  }

  static Future<void> changeStudentPassword({
    required int studentId,
    required String currentPassword,
    required String newPassword,
  }) async {
    final url = Uri.parse('$baseUrl/student/change-password/$studentId');

    final response = await http.post(
      url,
      headers: {'Accept': 'application/json'},
      body: {
        'current_password': currentPassword,
        'new_password': newPassword,
      },
    );

    final data = ApiHelpers.decodeJsonAsMap(response.body);

    if (!(response.statusCode >= 200 &&
        response.statusCode < 300 &&
        data['success'] == true)) {
      final msg = data['message']?.toString() ?? 'Failed to change student password';
      throw Exception(msg);
    }
  }

  static Future<Map<String, dynamic>> updateStudentNotifications({
    required int studentId,
    required Map<String, dynamic> notifications,
  }) async {
    final url = Uri.parse('$baseUrl/student/update-notifications/$studentId');

    final response = await http.put(
      url,
      headers: {'Accept': 'application/json'},
      body: notifications.map((key, value) => MapEntry(key, value.toString())),
    );

    final data = ApiHelpers.decodeJsonAsMap(response.body);

    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        data['success'] == true) {
      return data['student'] as Map<String, dynamic>;
    } else {
      final msg = data['message']?.toString() ?? 'Failed to update student notifications';
      throw Exception(msg);
    }
  }
}