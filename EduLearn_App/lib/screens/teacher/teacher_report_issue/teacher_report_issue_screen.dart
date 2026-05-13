import 'package:flutter/material.dart';

import '../../../l10n/core/app_localizations.dart';
import '../../../l10n/getters/teacher/teacher_report_issue_l10n.dart';
import '../../../theme.dart';

class TeacherReportIssueScreen extends StatefulWidget {
  final String teacherName;
  final String teacherCode;

  const TeacherReportIssueScreen({
    super.key,
    required this.teacherName,
    required this.teacherCode,
  });

  @override
  State<TeacherReportIssueScreen> createState() => _TeacherReportIssueScreenState();
}

class _TeacherReportIssueScreenState extends State<TeacherReportIssueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _detailsController = TextEditingController();
  String _issueType = 'technical';
  String _priority = 'medium';

  @override
  void dispose() {
    _titleController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  void _submitPreview() {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.teacherReportIssueReadySnack),
      ),
    );
  }

  String _issueTypeLabel(AppLocalizations l10n, String value) {
    switch (value) {
      case 'account':
        return l10n.teacherReportIssueTypeAccount;
      case 'lesson':
        return l10n.teacherReportIssueTypeLesson;
      case 'exercise':
        return l10n.teacherReportIssueTypeExercise;
      case 'other':
        return l10n.teacherReportIssueTypeOther;
      case 'technical':
      default:
        return l10n.teacherReportIssueTypeTechnical;
    }
  }

  String _priorityLabel(AppLocalizations l10n, String value) {
    switch (value) {
      case 'low':
        return l10n.teacherReportIssuePriorityLow;
      case 'high':
        return l10n.teacherReportIssuePriorityHigh;
      case 'medium':
      default:
        return l10n.teacherReportIssuePriorityMedium;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final borderColor = theme.dividerColor.withValues(alpha: isDark ? 0.26 : 0.55);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.teacherReportIssueTitle)),
      body: Form(
        key: _formKey,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            MediaQuery.of(context).padding.bottom + 28,
          ),
          children: [
            _FormIntroCard(
              title: l10n.teacherReportIssueIntroTitle,
              subtitle: l10n.teacherReportIssueIntroSubtitle,
              icon: Icons.report_problem_outlined,
            ),
            const SizedBox(height: 18),
            _StaticMetaCard(
              teacherName: widget.teacherName,
              teacherCode: widget.teacherCode,
              typeLabel: l10n.teacherReportIssueRoutingPreview,
            ),
            const SizedBox(height: 18),
            _LabeledField(
              label: l10n.teacherReportIssueProblemTitle,
              child: TextFormField(
                controller: _titleController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  hintText: l10n.teacherReportIssueTitleHint,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.teacherReportIssueTitleRequired;
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 14),
            _LabeledField(
              label: l10n.teacherReportIssueProblemType,
              child: DropdownButtonFormField<String>(
                value: _issueType,
                items: [
                  DropdownMenuItem(value: 'technical', child: Text(l10n.teacherReportIssueTypeTechnical)),
                  DropdownMenuItem(value: 'account', child: Text(l10n.teacherReportIssueTypeAccount)),
                  DropdownMenuItem(value: 'lesson', child: Text(l10n.teacherReportIssueTypeLesson)),
                  DropdownMenuItem(value: 'exercise', child: Text(l10n.teacherReportIssueTypeExercise)),
                  DropdownMenuItem(value: 'other', child: Text(l10n.teacherReportIssueTypeOther)),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _issueType = value);
                },
                decoration: const InputDecoration(),
              ),
            ),
            const SizedBox(height: 14),
            _LabeledField(
              label: l10n.teacherReportIssuePriority,
              child: DropdownButtonFormField<String>(
                value: _priority,
                items: [
                  DropdownMenuItem(value: 'low', child: Text(l10n.teacherReportIssuePriorityLow)),
                  DropdownMenuItem(value: 'medium', child: Text(l10n.teacherReportIssuePriorityMedium)),
                  DropdownMenuItem(value: 'high', child: Text(l10n.teacherReportIssuePriorityHigh)),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _priority = value);
                },
                decoration: const InputDecoration(),
              ),
            ),
            const SizedBox(height: 14),
            _LabeledField(
              label: l10n.teacherReportIssueProblemDetails,
              child: TextFormField(
                controller: _detailsController,
                minLines: 6,
                maxLines: 9,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: l10n.teacherReportIssueDetailsHint,
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().length < 12) {
                    return l10n.teacherReportIssueDetailsRequired;
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: borderColor),
                boxShadow: EduTheme.subtleShadow(isDark),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.teacherReportIssuePayloadTitle,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  _PayloadLine(label: l10n.teacherReportIssueTeacherName, value: widget.teacherName),
                  _PayloadLine(label: l10n.teacherReportIssueTeacherCode, value: widget.teacherCode),
                  _PayloadLine(label: l10n.teacherReportIssueTypeLabel, value: _issueTypeLabel(l10n, _issueType)),
                  _PayloadLine(label: l10n.teacherReportIssuePriorityLabel, value: _priorityLabel(l10n, _priority)),
                  _PayloadLine(label: l10n.teacherReportIssueAppVersion, value: l10n.teacherReportIssueReadyInject),
                  _PayloadLine(label: l10n.teacherReportIssueDeviceInfo, value: l10n.teacherReportIssueReadyInject),
                ],
              ),
            ),
            const SizedBox(height: 22),
            ElevatedButton.icon(
              onPressed: _submitPreview,
              icon: const Icon(Icons.send_rounded),
              label: Text(l10n.teacherReportIssueSubmit),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormIntroCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _FormIntroCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final borderColor = theme.dividerColor.withValues(alpha: isDark ? 0.26 : 0.55);

    return Container(
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
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(subtitle, style: theme.textTheme.bodyMedium?.copyWith(height: 1.45)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StaticMetaCard extends StatelessWidget {
  final String teacherName;
  final String teacherCode;
  final String typeLabel;

  const _StaticMetaCard({
    required this.teacherName,
    required this.teacherCode,
    required this.typeLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(22),
        boxShadow: EduTheme.subtleShadow(isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(typeLabel, style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800, color: theme.colorScheme.primary)),
          const SizedBox(height: 10),
          _PayloadLine(label: l10n.teacherReportIssueTeacherName, value: teacherName),
          _PayloadLine(label: l10n.teacherReportIssueTeacherCode, value: teacherCode),
        ],
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final Widget child;

  const _LabeledField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _PayloadLine extends StatelessWidget {
  final String label;
  final String value;

  const _PayloadLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
