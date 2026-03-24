import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../services/api_helpers.dart';
import '../../services/api_config.dart';
import 'package:http/http.dart' as http;

/// شاشة تفضيلات الإشعارات للمعلم
class TeacherNotificationPreferencesScreen extends StatefulWidget {
  final Map<String, dynamic> teacher;

  const TeacherNotificationPreferencesScreen({
    super.key,
    required this.teacher,
  });

  @override
  State<TeacherNotificationPreferencesScreen> createState() =>
      _TeacherNotificationPreferencesScreenState();
}

class _TeacherNotificationPreferencesScreenState
    extends State<TeacherNotificationPreferencesScreen> {
  bool newAssignment = true;
  bool newMessage = true;
  bool generalAnnouncements = true;

  @override
  void initState() {
    super.initState();
    // يمكن هنا جلب الإعدادات من الـ API إذا كانت محفوظة مسبقاً
    _loadNotificationPreferences();
  }

  Future<void> _loadNotificationPreferences() async {
    // مثال: جلب الإعدادات من server أو SharedPreferences
    // يمكنك تعديل هذا بما يناسب مشروعك
    final prefs = widget.teacher['notifications'] as Map<String, dynamic>?;
    if (prefs != null) {
      setState(() {
        newAssignment = prefs['new_assignment'] ?? true;
        newMessage = prefs['new_message'] ?? true;
        generalAnnouncements = prefs['general_announcements'] ?? true;
      });
    }
  }

  Future<void> _saveNotificationPreferences() async {
    final teacherId = widget.teacher['id'] as int;
    final Map<String, dynamic> notifications = {
      'new_assignment': newAssignment,
      'new_message': newMessage,
      'general_announcements': generalAnnouncements,
    };

    final url = Uri.parse('$baseUrl/teacher/update-notifications/$teacherId');

    final response = await http.put(
      url,
      headers: {'Accept': 'application/json'},
      body: notifications.map((key, value) => MapEntry(key, value.toString())),
    );

    final data = ApiHelpers.decodeJsonAsMap(response.body);

    if (!(response.statusCode >= 200 &&
        response.statusCode < 300 &&
        data['success'] == true)) {
      final msg = data['message']?.toString() ??
          'Failed to update teacher notifications';
      throw Exception(msg);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preferences updated successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Preferences'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('New Assignment Notifications'),
              value: newAssignment,
              onChanged: (val) {
                setState(() {
                  newAssignment = val;
                });
              },
            ),
            SwitchListTile(
              title: const Text('New Message Notifications'),
              value: newMessage,
              onChanged: (val) {
                setState(() {
                  newMessage = val;
                });
              },
            ),
            SwitchListTile(
              title: const Text('General Announcements'),
              value: generalAnnouncements,
              onChanged: (val) {
                setState(() {
                  generalAnnouncements = val;
                });
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveNotificationPreferences,
              child: const Text('Save Preferences'),
            ),
          ],
        ),
      ),
      backgroundColor: EduTheme.background,
    );
  }
}