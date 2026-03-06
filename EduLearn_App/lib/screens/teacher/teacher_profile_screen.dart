import 'package:flutter/material.dart';
import '../../theme.dart';

class TeacherProfileScreen extends StatelessWidget {
  final Map<String, dynamic> teacher;      // بيانات الأستاذ كاملة من الـ API
  final List<dynamic> assignments;
  final int totalAssignedStudents;

  const TeacherProfileScreen({
    super.key,
    required this.teacher,
    required this.assignments,
    required this.totalAssignedStudents,
  });

  String get fullName => (teacher['full_name'] ?? '').toString();
  String get teacherCode => (teacher['teacher_code'] ?? '').toString();
  String? get imageUrl => teacher['image'] as String?;

  @override
  Widget build(BuildContext context) {
    final String firstLetter =
        fullName.trim().isNotEmpty ? fullName.trim()[0].toUpperCase() : '?';

    return Scaffold(
      backgroundColor: EduTheme.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: EduTheme.background,
        centerTitle: true,
        title: const Text('Settings'),
        // تبويب رئيسي، لا نستخدم سهم رجوع هنا
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // ===== Header Profile =====
          Column(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.white,
                backgroundImage: (imageUrl != null && imageUrl!.isNotEmpty)
                    ? NetworkImage(imageUrl!)
                    : null,
                child: (imageUrl == null || imageUrl!.isEmpty)
                    ? Text(
                        firstLetter,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: EduTheme.primaryDark,
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 12),
              Text(
                fullName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: EduTheme.primaryDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                teacherCode,
                style: const TextStyle(
                  fontSize: 14,
                  color: EduTheme.textMuted,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          const _SectionTitle('Profile'),
          const _SettingsTile(
            icon: Icons.person_outline_rounded,
            label: 'Edit Profile',
          ),

          const SizedBox(height: 16),

          const _SectionTitle('Account Settings'),
          const _SettingsTile(
            icon: Icons.email_outlined,
            label: 'Manage Email',
          ),
          const _SettingsTile(
            icon: Icons.lock_outline_rounded,
            label: 'Change Password',
          ),
          const _SettingsTile(
            icon: Icons.notifications_none_rounded,
            label: 'Notification Preferences',
          ),

          const SizedBox(height: 16),

          const _SectionTitle('Theme & Language'),
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: _tileBoxDecoration,
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F3FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.dark_mode_outlined,
                    color: EduTheme.primaryDark),
              ),
              title: const Text(
                'Dark Mode',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: EduTheme.primaryDark,
                ),
              ),
              trailing: Switch(
                value: false,
                onChanged: (v) {
                  // لاحقًا: ربط الثيم
                },
              ),
            ),
          ),
          Container(
            decoration: _tileBoxDecoration,
            child: const ListTile(
              leading: _IconBox(icon: Icons.language_rounded),
              title: Text(
                'Language',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: EduTheme.primaryDark,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'English',
                    style: TextStyle(
                      color: EduTheme.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.chevron_right_rounded,
                      color: EduTheme.textMuted),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          const _SectionTitle('More'),
          const _SettingsTile(
            icon: Icons.info_outline_rounded,
            label: 'About EduLearn',
          ),
          const _SettingsTile(
            icon: Icons.help_outline_rounded,
            label: 'Help & Support',
          ),

          const SizedBox(height: 24),

          // Logout
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
                'Logout',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onTap: () {
                // لاحقاً: منطق تسجيل الخروج
              },
            ),
          ),
        ],
      ),
    );
  }
}

const BoxDecoration _tileBoxDecoration = BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.all(Radius.circular(18)),
  boxShadow: [
    BoxShadow(
      color: Color(0x11000000),
      blurRadius: 10,
      offset: Offset(0, 4),
    ),
  ],
);

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

  const _SettingsTile({
    required this.icon,
    required this.label,
  });

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
        onTap: () {
          // لاحقاً: فتح الشاشة المناسبة
        },
      ),
    );
  }
}

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
