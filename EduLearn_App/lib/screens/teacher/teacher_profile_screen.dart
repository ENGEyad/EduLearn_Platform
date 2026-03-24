import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme.dart';
import '../auth/login_screen.dart';
import 'teacher_edit_profile_screen.dart';
import 'teacher_manage_email_screen.dart';
import 'teacher_change_password_screen.dart';
import 'teacher_notification_preferences_screen.dart';
import '../../services/api_config.dart';
import '../../services/api_helpers.dart';

class TeacherProfileScreen extends StatelessWidget {
  final Map<String, dynamic> teacher;
  final List<dynamic> assignments;
  final int totalAssignedStudents;

  const TeacherProfileScreen({
    super.key,
    required this.teacher,
    required this.assignments,
    required this.totalAssignedStudents,
  });

  static const String pusherApiKey = 'qvgof2dxcwduaq9zvnyq';
  static const String pusherCluster = 'mt1';
  static String get rootUrl => serverRoot;

  Future<void> _handleLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Logout'),
            content: const Text('Are you sure you want to log out?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Logout'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      await logout();
      if (!context.mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final fullName = teacher['full_name']?.toString() ?? 'Teacher';
    final teacherCode = teacher['teacher_code']?.toString() ?? 'N/A';
    final String firstLetter =
        fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';

    return Scaffold(
      backgroundColor: EduTheme.background,
      appBar: AppBar(
        backgroundColor: EduTheme.background,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: EduTheme.primaryDark,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.white,
              child: Text(
                firstLetter,
                style: const TextStyle(
                  fontSize: 50,
                  fontWeight: FontWeight.w800,
                  color: EduTheme.primaryDark,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              fullName,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: EduTheme.primaryDark,
              ),
            ),
          ),
          Center(
            child: Text(
              'Teacher Code: $teacherCode',
              style: const TextStyle(color: EduTheme.textMuted),
            ),
          ),
          const SizedBox(height: 40),

          const _SectionTitle('Profile'),
          _SettingsTile(
            icon: Icons.person_outline_rounded,
            label: 'Edit Profile',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TeacherEditProfileScreen(teacher: teacher),
                ),
              );
            },
          ),

          const SizedBox(height: 16),
          const _SectionTitle('Account'),
          _SettingsTile(
            icon: Icons.email_outlined,
            label: 'Manage Email',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TeacherManageEmailScreen(teacher: teacher),
                ),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.lock_outline_rounded,
            label: 'Change Password',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TeacherChangePasswordScreen(teacher: teacher),
                ),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.notifications_none_rounded,
            label: 'Notification Preferences',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => TeacherNotificationPreferencesScreen(
                        teacher: teacher,
                      ),
                ),
              );
            },
          ),

          const SizedBox(height: 32),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1F1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: ListTile(
              leading: const Icon(
                Icons.logout_rounded,
                color: Colors.redAccent,
              ),
              title: const Text(
                'Log Out',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onTap: () => _handleLogout(context),
            ),
          ),
        ],
      ),
    );
  }

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

  static Future<void> saveSession(
    Map<String, dynamic> data,
    String type,
  ) async {
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

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 16,
          color: EduTheme.primaryDark,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _SettingsTile({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: _tileBoxDecoration,
      child: ListTile(
        leading: _IconBox(icon: icon),
        title: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: EduTheme.primaryDark,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: EduTheme.textMuted,
        ),
        onTap: onTap,
      ),
    );
  }
}

const BoxDecoration _tileBoxDecoration = BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.all(Radius.circular(18)),
  boxShadow: [
    BoxShadow(color: Color(0x11000000), blurRadius: 10, offset: Offset(0, 4)),
  ],
);

class _IconBox extends StatelessWidget {
  final IconData icon;
  const _IconBox({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFFE8F3FF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: EduTheme.primaryDark),
    );
  }
}

// ==================== Teacher Actions ====================

extension TeacherActions on TeacherProfileScreen {
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
      final msg =
          data['message']?.toString() ?? 'Failed to update teacher profile';
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
      final msg =
          data['message']?.toString() ?? 'Failed to update teacher email';
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
      body: {'current_password': currentPassword, 'new_password': newPassword},
    );

    final data = ApiHelpers.decodeJsonAsMap(response.body);

    if (!(response.statusCode >= 200 &&
        response.statusCode < 300 &&
        data['success'] == true)) {
      final msg =
          data['message']?.toString() ?? 'Failed to change teacher password';
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
      final msg =
          data['message']?.toString() ??
          'Failed to update teacher notifications';
      throw Exception(msg);
    }
  }
}

// ==================== Student Actions ====================

extension StudentActions on TeacherProfileScreen {
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
      final msg =
          data['message']?.toString() ?? 'Failed to update student profile';
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
      final msg =
          data['message']?.toString() ?? 'Failed to update student email';
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
      body: {'current_password': currentPassword, 'new_password': newPassword},
    );

    final data = ApiHelpers.decodeJsonAsMap(response.body);

    if (!(response.statusCode >= 200 &&
        response.statusCode < 300 &&
        data['success'] == true)) {
      final msg =
          data['message']?.toString() ?? 'Failed to change student password';
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
      final msg =
          data['message']?.toString() ??
          'Failed to update student notifications';
      throw Exception(msg);
    }
  }
}
