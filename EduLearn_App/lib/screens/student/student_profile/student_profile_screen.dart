import 'package:flutter/material.dart';

import '../../../l10n/core/app_localizations.dart';
import '../../../l10n/getters/student/student_profile_l10n.dart';
import '../../../main.dart';
import '../../../services/auth_service.dart';
import '../../../theme.dart';
import '../../auth/login_screen.dart';

import '../student_support_center_screen/student_support_center_screen.dart';

part 'student_profile_widgets.dart';

class StudentProfileScreen extends StatelessWidget {
  final Map<String, dynamic> student;
  final List<dynamic> assignedSubjects;

  const StudentProfileScreen({
    super.key,
    required this.student,
    required this.assignedSubjects,
  });

  String get fullName => (student['full_name'] ?? '').toString();
  String get academicId => (student['academic_id'] ?? '').toString();
  String? get imageUrl => student['image'] as String?;

  Future<void> _handleLogout(BuildContext context) async {
    final l10n = AppLocalizations.of(context);

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final ThemeData dialogTheme = Theme.of(ctx);
        final bool isDark = dialogTheme.brightness == Brightness.dark;
        final Color titleColor = dialogTheme.colorScheme.onSurface;
        final Color mutedColor =
            dialogTheme.textTheme.bodyMedium?.color?.withValues(alpha: 0.74) ??
                (isDark ? EduTheme.darkTextMuted : EduTheme.textMuted);
        final Color softDanger = isDark
            ? const Color(0xFF3A2227)
            : const Color(0xFFFFF1F1);

        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          backgroundColor: dialogTheme.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: softDanger,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.logout_rounded,
                      color: Colors.redAccent,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  l10n.studentProfileLogoutTitle,
                  style: dialogTheme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.studentProfileLogoutMessage,
                  style: dialogTheme.textTheme.bodyMedium?.copyWith(
                    color: mutedColor,
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: dialogTheme.colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: dialogTheme.colorScheme.primary.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _LogoutHintTitle(),
                      const SizedBox(height: 8),
                      _LogoutHint(
                        text: l10n.studentProfileLogoutHintSession,
                      ),
                      const SizedBox(height: 6),
                      _LogoutHint(
                        text: l10n.studentProfileLogoutHintLogin,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(l10n.studentProfileCancel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(l10n.studentProfileLogout),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
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
    final ThemeData theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final appState = EduLearnApp.of(context);
    final bool isDarkMode = appState.isDarkMode;

    final Color pageBackground = theme.scaffoldBackgroundColor;
    final Color titleColor = theme.colorScheme.onSurface;
    final Color mutedColor =
        theme.textTheme.bodySmall?.color ??
        (isDarkMode ? EduTheme.darkTextMuted : EduTheme.textMuted);
    final Color tileColor = theme.cardColor;
    final Color tileShadowColor = theme.shadowColor.withValues(
      alpha: isDarkMode ? 0.18 : 0.06,
    );
    final Color iconBoxBackground = isDarkMode
        ? EduTheme.darkSurfaceContainer
        : theme.colorScheme.primary.withValues(alpha: 0.08);
    final Color avatarBackground = isDarkMode
        ? EduTheme.darkSurfaceContainer
        : Colors.white;
    final Color logoutBoxColor = isDarkMode
        ? const Color(0xFF2A1C22)
        : const Color(0xFFFFF1F1);
    final Color borderColor = theme.dividerColor.withValues(
      alpha: isDarkMode ? 0.22 : 0.50,
    );

    final String firstLetter =
        fullName.trim().isNotEmpty ? fullName.trim()[0].toUpperCase() : '?';

    return Scaffold(
      backgroundColor: pageBackground,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: pageBackground,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: Text(l10n.studentProfileTitle),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          MediaQuery.of(context).padding.bottom + 44,
        ),
        children: [
          _ProfileHeader(
            fullName: fullName,
            academicId: academicId,
            imageUrl: imageUrl,
            firstLetter: firstLetter,
            avatarBackground: avatarBackground,
            titleColor: titleColor,
            mutedColor: mutedColor,
            tileColor: tileColor,
            shadowColor: tileShadowColor,
            borderColor: borderColor,
            accentSoftColor: iconBoxBackground,
          ),
          const SizedBox(height: 22),
          _SectionTitle(text: l10n.studentProfileTitle, color: titleColor),
          _SettingsTile(
            icon: Icons.person_outline_rounded,
            label: l10n.studentProfileEditProfile,
            tileColor: tileColor,
            shadowColor: tileShadowColor,
            titleColor: titleColor,
            mutedColor: mutedColor,
            iconBoxBackground: iconBoxBackground,
            borderColor: borderColor,
          ),
          const SizedBox(height: 16),
          _SectionTitle(text: l10n.studentProfileAccountSettings, color: titleColor),
          _SettingsTile(
            icon: Icons.email_outlined,
            label: l10n.studentProfileManageEmail,
            tileColor: tileColor,
            shadowColor: tileShadowColor,
            titleColor: titleColor,
            mutedColor: mutedColor,
            iconBoxBackground: iconBoxBackground,
            borderColor: borderColor,
          ),
          _SettingsTile(
            icon: Icons.lock_outline_rounded,
            label: l10n.studentProfileChangePassword,
            tileColor: tileColor,
            shadowColor: tileShadowColor,
            titleColor: titleColor,
            mutedColor: mutedColor,
            iconBoxBackground: iconBoxBackground,
            borderColor: borderColor,
          ),
          _SettingsTile(
            icon: Icons.notifications_none_rounded,
            label: l10n.studentProfileNotificationPreferences,
            tileColor: tileColor,
            shadowColor: tileShadowColor,
            titleColor: titleColor,
            mutedColor: mutedColor,
            iconBoxBackground: iconBoxBackground,
            borderColor: borderColor,
          ),
          const SizedBox(height: 16),
          _SectionTitle(text: l10n.studentProfileThemeLanguage, color: titleColor),
          _DarkModeTile(
            isDarkMode: isDarkMode,
            tileColor: tileColor,
            shadowColor: tileShadowColor,
            titleColor: titleColor,
            mutedColor: mutedColor,
            iconBoxBackground: iconBoxBackground,
            borderColor: borderColor,
            onChanged: (value) {
              EduLearnApp.of(context).toggleTheme(value);
            },
          ),
          _LanguageTile(
            tileColor: tileColor,
            shadowColor: tileShadowColor,
            titleColor: titleColor,
            mutedColor: mutedColor,
            iconBoxBackground: iconBoxBackground,
            borderColor: borderColor,
          ),
          const SizedBox(height: 16),
          _SectionTitle(text: l10n.studentProfileMore, color: titleColor),
          _SettingsTile(
            icon: Icons.info_outline_rounded,
            label: l10n.studentProfileAbout,
            tileColor: tileColor,
            shadowColor: tileShadowColor,
            titleColor: titleColor,
            mutedColor: mutedColor,
            iconBoxBackground: iconBoxBackground,
            borderColor: borderColor,
          ),
          _SettingsTile(
            icon: Icons.help_outline_rounded,
            label: l10n.studentProfileHelpSupport,
            tileColor: tileColor,
            shadowColor: tileShadowColor,
            titleColor: titleColor,
            mutedColor: mutedColor,
            iconBoxBackground: iconBoxBackground,
            borderColor: borderColor,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const StudentSupportCenterScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _LogoutTile(
            logoutBoxColor: logoutBoxColor,
            borderColor: Colors.redAccent.withValues(alpha: 0.14),
            titleColor: Colors.redAccent,
            subtitleColor: mutedColor,
            onTap: () => _handleLogout(context),
          ),
        ],
      ),
    );
  }
}
