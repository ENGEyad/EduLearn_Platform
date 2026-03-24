import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import 'student_edit_profile_screen.dart';
import 'student_manage_email_screen.dart';
import 'student_change_password_screen.dart';
import 'student_notification_preferences_screen.dart';
import '../../services/api_config.dart';
import '../../services/api_helpers.dart';



class StudentProfileScreen extends StatelessWidget {
  final Map<String, dynamic> student;

  const StudentProfileScreen({super.key, required this.student});

  Future<void> _handleLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AuthService.logout();
      if (!context.mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final fullName = student['full_name']?.toString() ?? 'Student';
    final academicId = student['academic_id']?.toString() ?? 'N/A';
    final String firstLetter = fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';

    return Scaffold(
      backgroundColor: EduTheme.background,
      appBar: AppBar(
        backgroundColor: EduTheme.background,
        elevation: 0,
        title: const Text('Profile', style: TextStyle(color: EduTheme.primaryDark, fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // ===== Header =====
          Center(
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.white,
              child: Text(firstLetter,
                  style: const TextStyle(fontSize: 50, fontWeight: FontWeight.w800, color: EduTheme.primaryDark)),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(fullName,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: EduTheme.primaryDark)),
          ),
          Center(
            child: Text('Academic ID: $academicId', style: const TextStyle(color: EduTheme.textMuted)),
          ),
          const SizedBox(height: 40),

          // ===== Profile Settings =====
          const _SectionTitle('Profile'),
          _SettingsTile(
            icon: Icons.person_outline_rounded,
            label: 'Edit Profile',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StudentEditProfileScreen(student: student),
                ),
              );
            },
          ),

          const SizedBox(height: 16),
          const _SectionTitle('Account Settings'),
          _SettingsTile(
            icon: Icons.email_outlined,
            label: 'Manage Email',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                 builder: (_) => StudentManageEmailScreen(student: student),
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
                  builder: (_) => StudentChangePasswordScreen(student: student),
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
                  builder: (_) => StudentNotificationPreferencesScreen(student: student),
                ),
              );
            },
          ),

          const SizedBox(height: 32),

          // ===== Logout =====
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1F1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              title: const Text('Log Out',
                  style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700)),
              onTap: () => _handleLogout(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(text,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: EduTheme.primaryDark)),
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
        title: Text(label,
            style: const TextStyle(fontWeight: FontWeight.w600, color: EduTheme.primaryDark)),
        trailing: const Icon(Icons.chevron_right_rounded, color: EduTheme.textMuted),
        onTap: onTap,
      ),
    );
  }
}

const BoxDecoration _tileBoxDecoration = BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.all(Radius.circular(18)),
  boxShadow: [BoxShadow(color: Color(0x11000000), blurRadius: 10, offset: Offset(0, 4))],
);

class _IconBox extends StatelessWidget {
  final IconData icon;
  const _IconBox({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(color: const Color(0xFFE8F3FF), borderRadius: BorderRadius.circular(14)),
      child: Icon(icon, color: EduTheme.primaryDark),
    );
  }
}