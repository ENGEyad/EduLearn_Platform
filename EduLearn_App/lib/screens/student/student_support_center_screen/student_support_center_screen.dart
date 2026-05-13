import 'package:flutter/material.dart';

import '../../../l10n/core/app_localizations.dart';
import '../../../l10n/getters/student/student_support_center_l10n.dart';
import '../../../theme.dart';

import '../student_contact_us_screen/student_contact_us_screen.dart';
import '../student_faq_screen/student_faq_screen.dart';
import '../student_report_issue/student_report_issue_screen.dart';

class StudentSupportCenterScreen extends StatelessWidget {
  const StudentSupportCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color titleColor = theme.colorScheme.onSurface;
    final Color mutedColor =
        theme.textTheme.bodySmall?.color ??
        (isDark ? EduTheme.darkTextMuted : EduTheme.textMuted);
    final Color cardColor = theme.cardColor;
    final Color borderColor = theme.dividerColor.withValues(
      alpha: isDark ? 0.24 : 0.52,
    );
    final Color shadowColor = theme.shadowColor.withValues(
      alpha: isDark ? 0.18 : 0.06,
    );
    final Color softPrimary = isDark
        ? EduTheme.darkSurfaceContainer
        : theme.colorScheme.primary.withValues(alpha: 0.08);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        title: Text(l10n.studentSupportCenterTitle),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          MediaQuery.of(context).padding.bottom + 28,
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: softPrimary,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    Icons.support_agent_rounded,
                    color: theme.colorScheme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  l10n.studentSupportCenterHeading,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.studentSupportCenterDescription,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: mutedColor,
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _SupportEntryCard(
            icon: Icons.quiz_outlined,
            title: l10n.studentSupportCenterFaqs,
            subtitle: l10n.studentSupportCenterFaqsSubtitle,
            accentColor: theme.colorScheme.primary,
            cardColor: cardColor,
            borderColor: borderColor,
            shadowColor: shadowColor,
            iconBoxColor: softPrimary,
            titleColor: titleColor,
            subtitleColor: mutedColor,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const StudentFaqScreen(),
                ),
              );
            },
          ),
          _SupportEntryCard(
            icon: Icons.report_problem_outlined,
            title: l10n.studentSupportCenterReportProblem,
            subtitle: l10n.studentSupportCenterReportProblemSubtitle,
            accentColor: const Color(0xFFD08B2F),
            cardColor: cardColor,
            borderColor: borderColor,
            shadowColor: shadowColor,
            iconBoxColor: isDark
                ? const Color(0xFF2A2318)
                : const Color(0xFFFFF5E7),
            titleColor: titleColor,
            subtitleColor: mutedColor,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const StudentReportIssueScreen(),
                ),
              );
            },
          ),
          _SupportEntryCard(
            icon: Icons.mail_outline_rounded,
            title: l10n.studentSupportCenterContactUs,
            subtitle: l10n.studentSupportCenterContactUsSubtitle,
            accentColor: const Color(0xFF6B7FE5),
            cardColor: cardColor,
            borderColor: borderColor,
            shadowColor: shadowColor,
            iconBoxColor: isDark
                ? const Color(0xFF20253A)
                : const Color(0xFFF0F3FF),
            titleColor: titleColor,
            subtitleColor: mutedColor,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const StudentContactUsScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SupportEntryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final Color cardColor;
  final Color borderColor;
  final Color shadowColor;
  final Color iconBoxColor;
  final Color titleColor;
  final Color subtitleColor;
  final VoidCallback onTap;

  const _SupportEntryCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.cardColor,
    required this.borderColor,
    required this.shadowColor,
    required this.iconBoxColor,
    required this.titleColor,
    required this.subtitleColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ListTile(
        minTileHeight: 88,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: iconBoxColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: accentColor, size: 24),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: titleColor,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            style: TextStyle(
              color: subtitleColor,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: subtitleColor,
        ),
        onTap: onTap,
      ),
    );
  }
}
