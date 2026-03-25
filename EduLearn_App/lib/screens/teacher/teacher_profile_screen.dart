import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../main.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';

class TeacherProfileScreen extends StatelessWidget {
  final Map<String, dynamic> teacher; // بيانات الأستاذ كاملة من الـ API
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

  Future<void> _handleLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
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
    final theme = Theme.of(context);
    final appState = EduLearnApp.of(context);
    final isDarkMode = appState.isDarkMode;

    final Color pageBackground = theme.scaffoldBackgroundColor;
    final Color titleColor = theme.colorScheme.onSurface;
    final Color mutedColor =
        theme.textTheme.bodySmall?.color ??
        (isDarkMode ? EduTheme.darkTextMuted : EduTheme.textMuted);
    final Color tileColor = theme.cardColor;
    final Color tileShadowColor =
        isDarkMode
            ? Colors.black.withValues(alpha: 0.18)
            : const Color(0x11000000);
    final Color iconBoxBackground =
        isDarkMode ? EduTheme.darkSurface : const Color(0xFFE8F3FF);
    final Color avatarBackground =
        isDarkMode ? EduTheme.darkSurface : Colors.white;
    final Color logoutBoxColor =
        isDarkMode
            ? const Color(0xFF2A1C22)
            : const Color(0xFFFFF1F1);

    final String firstLetter =
        fullName.trim().isNotEmpty ? fullName.trim()[0].toUpperCase() : '?';

    return Scaffold(
      backgroundColor: pageBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: pageBackground,
        centerTitle: true,
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          Column(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: avatarBackground,
                backgroundImage:
                    (imageUrl != null && imageUrl!.isNotEmpty)
                        ? NetworkImage(imageUrl!)
                        : null,
                child:
                    (imageUrl == null || imageUrl!.isEmpty)
                        ? Text(
                          firstLetter,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: titleColor,
                          ),
                        )
                        : null,
              ),
              const SizedBox(height: 12),
              Text(
                fullName,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                teacherCode,
                style: TextStyle(fontSize: 14, color: mutedColor),
              ),
            ],
          ),

          const SizedBox(height: 24),

          _SectionTitle(text: 'Profile', color: titleColor),
          _SettingsTile(
            icon: Icons.person_outline_rounded,
            label: 'Edit Profile',
            tileColor: tileColor,
            shadowColor: tileShadowColor,
            titleColor: titleColor,
            mutedColor: mutedColor,
            iconBoxBackground: iconBoxBackground,
          ),

          const SizedBox(height: 16),

          _SectionTitle(text: 'Account Settings', color: titleColor),
          _SettingsTile(
            icon: Icons.email_outlined,
            label: 'Manage Email',
            tileColor: tileColor,
            shadowColor: tileShadowColor,
            titleColor: titleColor,
            mutedColor: mutedColor,
            iconBoxBackground: iconBoxBackground,
          ),
          _SettingsTile(
            icon: Icons.lock_outline_rounded,
            label: 'Change Password',
            tileColor: tileColor,
            shadowColor: tileShadowColor,
            titleColor: titleColor,
            mutedColor: mutedColor,
            iconBoxBackground: iconBoxBackground,
          ),
          _SettingsTile(
            icon: Icons.notifications_none_rounded,
            label: 'Notification Preferences',
            tileColor: tileColor,
            shadowColor: tileShadowColor,
            titleColor: titleColor,
            mutedColor: mutedColor,
            iconBoxBackground: iconBoxBackground,
          ),

          const SizedBox(height: 16),

          _SectionTitle(text: 'Theme & Language', color: titleColor),
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: _tileBoxDecoration(
              tileColor: tileColor,
              shadowColor: tileShadowColor,
            ),
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBoxBackground,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.dark_mode_outlined, color: titleColor),
              ),
              title: Text(
                'Dark Mode',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: titleColor,
                ),
              ),
              trailing: Switch(
                value: isDarkMode,
                onChanged: (v) {
                  EduLearnApp.of(context).toggleTheme(v);
                },
              ),
            ),
          ),
          Container(
            decoration: _tileBoxDecoration(
              tileColor: tileColor,
              shadowColor: tileShadowColor,
            ),
            child: ListTile(
              leading: _IconBox(
                icon: Icons.language_rounded,
                iconColor: titleColor,
                backgroundColor: iconBoxBackground,
              ),
              title: Text(
                'Language',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: titleColor,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'English',
                    style: TextStyle(
                      color: mutedColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right_rounded, color: mutedColor),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          _SectionTitle(text: 'More', color: titleColor),
          _SettingsTile(
            icon: Icons.info_outline_rounded,
            label: 'About EduLearn',
            tileColor: tileColor,
            shadowColor: tileShadowColor,
            titleColor: titleColor,
            mutedColor: mutedColor,
            iconBoxBackground: iconBoxBackground,
          ),
          _SettingsTile(
            icon: Icons.help_outline_rounded,
            label: 'Help & Support',
            tileColor: tileColor,
            shadowColor: tileShadowColor,
            titleColor: titleColor,
            mutedColor: mutedColor,
            iconBoxBackground: iconBoxBackground,
          ),

          const SizedBox(height: 24),

          Container(
            decoration: BoxDecoration(
              color: logoutBoxColor,
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
              onTap: () => _handleLogout(context),
            ),
          ),
        ],
      ),
    );
  }
}

BoxDecoration _tileBoxDecoration({
  required Color tileColor,
  required Color shadowColor,
}) {
  return BoxDecoration(
    color: tileColor,
    borderRadius: const BorderRadius.all(Radius.circular(18)),
    boxShadow: [
      BoxShadow(
        color: shadowColor,
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );
}

class _SectionTitle extends StatelessWidget {
  final String text;
  final Color color;

  const _SectionTitle({
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 16,
          color: color,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color tileColor;
  final Color shadowColor;
  final Color titleColor;
  final Color mutedColor;
  final Color iconBoxBackground;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.tileColor,
    required this.shadowColor,
    required this.titleColor,
    required this.mutedColor,
    required this.iconBoxBackground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: _tileBoxDecoration(
        tileColor: tileColor,
        shadowColor: shadowColor,
      ),
      child: ListTile(
        leading: _IconBox(
          icon: icon,
          iconColor: titleColor,
          backgroundColor: iconBoxBackground,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: titleColor,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: mutedColor,
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
  final Color iconColor;
  final Color backgroundColor;

  const _IconBox({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: iconColor),
    );
  }
}