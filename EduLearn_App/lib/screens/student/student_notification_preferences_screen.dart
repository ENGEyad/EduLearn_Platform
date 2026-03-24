import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class StudentNotificationPreferencesScreen extends StatefulWidget {
  final Map<String, dynamic> student;

  const StudentNotificationPreferencesScreen({super.key, required this.student});

  @override
  State<StudentNotificationPreferencesScreen> createState() => _StudentNotificationsScreenState();
}

class _StudentNotificationsScreenState extends State<StudentNotificationPreferencesScreen> {
  bool isLoading = false;
  bool notificationsEnabled = true; // افتراضي

  @override
  void initState() {
    super.initState();
    notificationsEnabled = widget.student['notifications_enabled'] ?? true;
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() => isLoading = true);
    try {
      final updatedData = await AuthService.authStudent(
        fullName: widget.student['full_name'],
        academicId: widget.student['academic_id'],
        // يمكن إضافة مفتاح notifications_enabled للـ API عند الحاجة
      );
      setState(() => notificationsEnabled = value);
      widget.student.addAll(updatedData['student']);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notification Preferences')),
      body: ListTile(
        title: const Text('Enable Notifications'),
        trailing: Switch(
          value: notificationsEnabled,
          onChanged: isLoading ? null : _toggleNotifications,
        ),
      ),
    );
  }
}