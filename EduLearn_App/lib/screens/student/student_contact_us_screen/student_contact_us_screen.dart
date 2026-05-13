import 'package:flutter/material.dart';

import '../../../l10n/core/app_localizations.dart';
import '../../../l10n/getters/student/student_contact_us_l10n.dart';
import '../../../theme.dart';

class StudentContactUsScreen extends StatefulWidget {
  const StudentContactUsScreen({super.key});

  @override
  State<StudentContactUsScreen> createState() => _StudentContactUsScreenState();
}

class _StudentContactUsScreenState extends State<StudentContactUsScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  String _messageTypeKey = 'inquiry';

  final List<String> _messageTypeKeys = const [
    'inquiry',
    'suggestion',
    'feedback',
    'complaint',
  ];

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  String _messageTypeLabel(AppLocalizations l10n, String key) {
    switch (key) {
      case 'inquiry':
        return l10n.studentContactUsTypeInquiry;
      case 'suggestion':
        return l10n.studentContactUsTypeSuggestion;
      case 'feedback':
        return l10n.studentContactUsTypeFeedback;
      case 'complaint':
        return l10n.studentContactUsTypeComplaint;
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
                  l10n.studentContactUsPreviewTitle,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 14),
                _ContactPreviewRow(
                  label: l10n.studentContactUsPreviewType,
                  value: _messageTypeLabel(l10n, _messageTypeKey),
                ),
                _ContactPreviewRow(
                  label: l10n.studentContactUsSubject,
                  value: _subjectController.text.trim(),
                ),
                _ContactPreviewRow(
                  label: l10n.studentContactUsMessage,
                  value: _messageController.text.trim(),
                  isMultiline: true,
                ),
                const SizedBox(height: 18),
                Text(
                  l10n.studentContactUsPreviewNote,
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
                    child: Text(l10n.studentContactUsDone),
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
        title: Text(l10n.studentContactUsTitle),
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
                    l10n.studentContactUsHeading,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.studentContactUsDescription,
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
                  DropdownButtonFormField<String>(
                    initialValue: _messageTypeKey,
                    items: _messageTypeKeys
                        .map(
                          (type) => DropdownMenuItem(
                            value: type,
                            child: Text(_messageTypeLabel(l10n, type)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _messageTypeKey = value);
                      }
                    },
                    decoration: InputDecoration(
                      labelText: l10n.studentContactUsMessageType,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _subjectController,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: l10n.studentContactUsSubject,
                      hintText: l10n.studentContactUsSubjectHint,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n.studentContactUsSubjectRequired;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _messageController,
                    minLines: 6,
                    maxLines: 8,
                    decoration: InputDecoration(
                      alignLabelWithHint: true,
                      labelText: l10n.studentContactUsMessage,
                      hintText: l10n.studentContactUsMessageHint,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n.studentContactUsMessageRequired;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _showPreview,
                      icon: const Icon(Icons.mail_outline_rounded),
                      label: Text(l10n.studentContactUsPreviewMessage),
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

class _ContactPreviewRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isMultiline;

  const _ContactPreviewRow({
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
