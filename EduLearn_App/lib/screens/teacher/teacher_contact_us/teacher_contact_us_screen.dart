import 'package:flutter/material.dart';

import '../../../l10n/core/app_localizations.dart';
import '../../../l10n/getters/teacher/teacher_contact_us_l10n.dart';
import '../../../theme.dart';

class TeacherContactUsScreen extends StatefulWidget {
  final String teacherName;
  final String teacherCode;

  const TeacherContactUsScreen({
    super.key,
    required this.teacherName,
    required this.teacherCode,
  });

  @override
  State<TeacherContactUsScreen> createState() => _TeacherContactUsScreenState();
}

class _TeacherContactUsScreenState extends State<TeacherContactUsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  String _messageType = 'question';

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _submitPreview() {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.teacherContactUsReadySnack),
      ),
    );
  }

  String _messageTypeLabel(AppLocalizations l10n, String value) {
    switch (value) {
      case 'suggestion':
        return l10n.teacherContactUsTypeSuggestion;
      case 'note':
        return l10n.teacherContactUsTypeNote;
      case 'feedback':
        return l10n.teacherContactUsTypeFeedback;
      case 'question':
      default:
        return l10n.teacherContactUsTypeQuestion;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final borderColor = theme.dividerColor.withValues(alpha: isDark ? 0.26 : 0.55);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.teacherContactUsTitle)),
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
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: borderColor),
                boxShadow: EduTheme.subtleShadow(isDark),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.teacherContactUsIntroTitle,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.teacherContactUsIntroSubtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ContactMetaLine(label: l10n.teacherContactUsTeacherName, value: widget.teacherName),
                  _ContactMetaLine(label: l10n.teacherContactUsTeacherCode, value: widget.teacherCode),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _FieldGroup(
              label: l10n.teacherContactUsMessageType,
              child: DropdownButtonFormField<String>(
                value: _messageType,
                items: [
                  DropdownMenuItem(value: 'question', child: Text(l10n.teacherContactUsTypeQuestion)),
                  DropdownMenuItem(value: 'suggestion', child: Text(l10n.teacherContactUsTypeSuggestion)),
                  DropdownMenuItem(value: 'note', child: Text(l10n.teacherContactUsTypeNote)),
                  DropdownMenuItem(value: 'feedback', child: Text(l10n.teacherContactUsTypeFeedback)),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _messageType = value);
                },
                decoration: const InputDecoration(),
              ),
            ),
            const SizedBox(height: 14),
            _FieldGroup(
              label: l10n.teacherContactUsSubject,
              child: TextFormField(
                controller: _subjectController,
                decoration: InputDecoration(
                  hintText: l10n.teacherContactUsSubjectHint,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.teacherContactUsSubjectRequired;
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 14),
            _FieldGroup(
              label: l10n.teacherContactUsMessage,
              child: TextFormField(
                controller: _messageController,
                minLines: 6,
                maxLines: 10,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: l10n.teacherContactUsMessageHint,
                ),
                validator: (value) {
                  if (value == null || value.trim().length < 10) {
                    return l10n.teacherContactUsMessageRequired;
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
                    l10n.teacherContactUsPayloadTitle,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  _ContactMetaLine(label: l10n.teacherContactUsTeacherName, value: widget.teacherName),
                  _ContactMetaLine(label: l10n.teacherContactUsTeacherCode, value: widget.teacherCode),
                  _ContactMetaLine(label: l10n.teacherContactUsMessageTypeLabel, value: _messageTypeLabel(l10n, _messageType)),
                ],
              ),
            ),
            const SizedBox(height: 22),
            ElevatedButton.icon(
              onPressed: _submitPreview,
              icon: const Icon(Icons.send_rounded),
              label: Text(l10n.teacherContactUsSend),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldGroup extends StatelessWidget {
  final String label;
  final Widget child;

  const _FieldGroup({required this.label, required this.child});

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

class _ContactMetaLine extends StatelessWidget {
  final String label;
  final String value;

  const _ContactMetaLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 108,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(value, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
