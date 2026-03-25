import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_models.dart';
import '../../providers/app_settings_provider.dart';
import '../../l10n/app_localizations.dart';
import 'placeholder_screens.dart';
import 'widgets/settings_section.dart';

class StudentSettingsScreen extends StatelessWidget {
  final StudentModel student;

  const StudentSettingsScreen({Key? key, required this.student}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final themeMode = context.watch<AppSettingsProvider>();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(l10n.get('settings_title')),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.only(top: 20, bottom: 40),
        children: [
          // Section A: User Identity Header
          _buildProfileHeader(context, l10n),
          
          const SizedBox(height: 32),

          // Section B: Account Settings
          SettingsSection(
            title: 'Account',
            children: [
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(l10n.get('edit_profile')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditProfileScreen())),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.email_outlined),
                title: Text(l10n.get('email_address')),
                subtitle: Text(student.email),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ManageEmailScreen())),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: Text(l10n.get('change_password')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChangePasswordScreen())),
              ),
            ],
          ),

          // Section C: Application Settings
          SettingsSection(
            title: 'Application',
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.dark_mode_outlined),
                title: Text(l10n.get('dark_mode')),
                value: themeMode.isDarkMode,
                onChanged: (val) => context.read<AppSettingsProvider>().toggleTheme(val),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.language),
                title: Text(l10n.get('language')),
                subtitle: Text(themeMode.locale.languageCode == 'ar' ? 'العربية' : 'English (US)'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  final newLang = themeMode.locale.languageCode == 'ar' ? 'en' : 'ar';
                  context.read<AppSettingsProvider>().setLocale(Locale(newLang));
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.notifications_none),
                title: Text(l10n.get('notifications')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NotificationPreferencesScreen())),
              ),
            ],
          ),

          // Section D: Session Management
          SettingsSection(
            title: 'Session',
            children: [
              ListTile(
                leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
                title: Text(l10n.get('logout'), style: TextStyle(color: Theme.of(context).colorScheme.error)),
                onTap: () => _handleLogout(context, l10n),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, AppLocalizations l10n) {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundImage: student.imageUrl != null 
            ? NetworkImage(student.imageUrl!) 
            : const AssetImage('assets/avatar_placeholder.png') as ImageProvider,
        ),
        const SizedBox(height: 16),
        Text(
          student.fullName,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          '${student.studentId} • ${student.gradeLevel ?? l10n.get('grade')}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
        ),
        const SizedBox(height: 16),
        if (student.enrolledCourses != null)
          _buildStatBadge(context, '${student.enrolledCourses!.length}', l10n.get('enrolled_courses')),
      ],
    );
  }

  Widget _buildStatBadge(BuildContext context, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSecondaryContainer)),
          Text(label, style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSecondaryContainer)),
        ],
      ),
    );
  }

  void _handleLogout(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.get('logout')),
        content: Text(l10n.get('confirm_logout')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.get('cancel')),
          ),
          FilledButton(
            onPressed: () {
              // 1. Clear secure storage / sessions
              // 2. Clear routing stack
              // Navigator.pushAndRemoveUntil(context, LoginRoute(), (route) => false);
            },
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: Text(l10n.get('logout')),
          ),
        ],
      ),
    );
  }
}
