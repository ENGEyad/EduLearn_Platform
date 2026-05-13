import 'package:flutter/material.dart';

import '../../../l10n/core/app_localizations.dart';
import '../../../l10n/getters/student/student_report_issue_l10n.dart';
import '../../../theme.dart';

class StudentReportIssueScreen extends StatefulWidget {
  const StudentReportIssueScreen({super.key});

  @override
  State<StudentReportIssueScreen> createState() => _StudentReportIssueScreenState();
}

class _StudentReportIssueScreenState extends State<StudentReportIssueScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _lessonController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  String _issueTypeKey = 'technical';

  final List<String> _issueTypeKeys = const [
    'technical',
    'lesson',
    'exercise',
    'account',
    'other',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _lessonController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  String _issueTypeLabel(AppLocalizations l10n, String key) {
    switch (key) {
      case 'technical':
        return l10n.studentReportIssueTypeTechnical;
      case 'lesson':
        return l10n.studentReportIssueTypeLesson;
      case 'exercise':
        return l10n.studentReportIssueTypeExercise;
      case 'account':
        return l10n.studentReportIssueTypeAccount;
      case 'other':
        return l10n.studentReportIssueTypeOther;
      default:
        return key;
    }
  }

  void _showPreview() {
    if (!_formKey.currentState!.validate()) return;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final l10n = AppLocalizations.of(ctx);
        final bool isDark = theme.brightness == Brightness.dark;
        final Color titleColor = theme.colorScheme.onSurface;
        final Color mutedColor =
            theme.textTheme.bodySmall?.color ??
            (isDark ? EduTheme.darkTextMuted : EduTheme.textMuted);

        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.studentReportIssuePreviewTitle,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 14),
                _PreviewRow(
                  label: l10n.studentReportIssuePreviewType,
                  value: _issueTypeLabel(l10n, _issueTypeKey),
                ),
                _PreviewRow(
                  label: l10n.studentReportIssuePreviewTitleLabel,
                  value: _titleController.text.trim(),
                ),
                _PreviewRow(
                  label: l10n.studentReportIssuePreviewLesson,
                  value: _lessonController.text.trim().isEmpty
                      ? l10n.studentReportIssueNotSpecified
                      : _lessonController.text.trim(),
                ),
                _PreviewRow(
                  label: l10n.studentReportIssuePreviewDetails,
                  value: _detailsController.text.trim(),
                  isMultiline: true,
                ),
                const SizedBox(height: 18),
                Text(
                  l10n.studentReportIssuePreviewNote,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: mutedColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(l10n.studentReportIssueDone),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

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

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        title: Text(l10n.studentReportIssueTitle),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            MediaQuery.of(context).padding.bottom + 24,
          ),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
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
                  Text(
                    l10n.studentReportIssueHeading,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.studentReportIssueDescription,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: mutedColor,
                      fontWeight: FontWeight.w600,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.studentReportIssueTypeLabel,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _issueTypeKey,
                    items: _issueTypeKeys
                        .map(
                          (type) => DropdownMenuItem(
                            value: type,
                            child: Text(_issueTypeLabel(l10n, type)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _issueTypeKey = value);
                      }
                    },
                    decoration: InputDecoration(
                      hintText: l10n.studentReportIssueChooseType,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _titleController,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: l10n.studentReportIssueIssueTitle,
                      hintText: l10n.studentReportIssueIssueTitleHint,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n.studentReportIssueTitleRequired;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _lessonController,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: l10n.studentReportIssueLessonLabel,
                      hintText: l10n.studentReportIssueLessonHint,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _detailsController,
                    minLines: 6,
                    maxLines: 8,
                    decoration: InputDecoration(
                      alignLabelWithHint: true,
                      labelText: l10n.studentReportIssueDetailsLabel,
                      hintText: l10n.studentReportIssueDetailsHint,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n.studentReportIssueDetailsRequired;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _showPreview,
                      icon: const Icon(Icons.send_rounded),
                      label: Text(l10n.studentReportIssuePreviewReport),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isMultiline;

  const _PreviewRow({
    required this.label,
    required this.value,
    this.isMultiline = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: isMultiline ? null : 2,
            overflow: isMultiline ? null : TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
