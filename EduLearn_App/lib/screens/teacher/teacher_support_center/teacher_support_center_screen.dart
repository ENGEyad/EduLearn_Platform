import 'package:flutter/material.dart';

import '../../../l10n/core/app_localizations.dart';
import '../../../l10n/getters/teacher/teacher_support_center_l10n.dart';
import '../../../theme.dart';
import '../teacher_contact_us/teacher_contact_us_screen.dart';
import '../teacher_faq/teacher_faq_screen.dart';
import '../teacher_report_issue/teacher_report_issue_screen.dart';

class TeacherSupportCenterScreen extends StatelessWidget {
  final String teacherName;
  final String teacherCode;

  const TeacherSupportCenterScreen({
    super.key,
    required this.teacherName,
    required this.teacherCode,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color borderColor =
        theme.dividerColor.withValues(alpha: isDark ? 0.26 : 0.58);
    final Color softPrimary =
        theme.colorScheme.primary.withValues(alpha: isDark ? 0.18 : 0.08);
    final Color mutedColor = theme.textTheme.bodySmall?.color ??
        (isDark ? EduTheme.darkTextMuted : EduTheme.textMuted);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.teacherSupportCenterTitle),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          MediaQuery.of(context).padding.bottom + 32,
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: borderColor),
              boxShadow: EduTheme.cardShadow(isDark),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: softPrimary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    l10n.teacherSupportCenterHub,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  l10n.teacherSupportCenterHeadline,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.teacherSupportCenterDescription,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: mutedColor,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _TeacherMetaChip(
                      icon: Icons.person_outline_rounded,
                      text: teacherName,
                    ),
                    _TeacherMetaChip(
                      icon: Icons.badge_outlined,
                      text: teacherCode,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Text(
            l10n.teacherSupportCenterChooseNeed,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          _SupportOptionCard(
            icon: Icons.quiz_outlined,
            title: l10n.teacherSupportCenterFaqTitle,
            subtitle: l10n.teacherSupportCenterFaqSubtitle,
            accentColor: theme.colorScheme.primary,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TeacherFaqScreen(
                    teacherName: teacherName,
                    teacherCode: teacherCode,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          _SupportOptionCard(
            icon: Icons.report_problem_outlined,
            title: l10n.teacherSupportCenterReportTitle,
            subtitle: l10n.teacherSupportCenterReportSubtitle,
            accentColor: const Color(0xFFCC7A00),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TeacherReportIssueScreen(
                    teacherName: teacherName,
                    teacherCode: teacherCode,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          _SupportOptionCard(
            icon: Icons.support_agent_rounded,
            title: l10n.teacherSupportCenterContactTitle,
            subtitle: l10n.teacherSupportCenterContactSubtitle,
            accentColor: const Color(0xFF4B7BEC),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TeacherContactUsScreen(
                    teacherName: teacherName,
                    teacherCode: teacherCode,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SupportOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final VoidCallback onTap;

  const _SupportOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final borderColor =
        theme.dividerColor.withValues(alpha: isDark ? 0.28 : 0.55);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor),
            boxShadow: EduTheme.subtleShadow(isDark),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, color: accentColor, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.textTheme.bodySmall?.color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeacherMetaChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _TeacherMetaChip({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            text,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
