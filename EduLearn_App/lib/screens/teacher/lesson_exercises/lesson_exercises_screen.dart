import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/core/app_localizations.dart';
import '../../../l10n/getters/teacher/lesson_exercises_l10n.dart';
import '../../../services/api_service.dart';
import '../../../theme.dart';

part 'lesson_exercises_models.dart';
part 'lesson_exercises_widgets.dart';

class LessonExercisesScreen extends StatefulWidget {
  final int lessonId;
  final String teacherCode; // still passed but not used in services
  final String lessonTitle;

  const LessonExercisesScreen({
    super.key,
    required this.lessonId,
    required this.teacherCode,
    required this.lessonTitle,
  });

  @override
  State<LessonExercisesScreen> createState() => _LessonExercisesScreenState();
}

class _LessonExercisesScreenState extends State<LessonExercisesScreen> {
  late final LessonExerciseService _exerciseService;
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isPublishing = false;
  bool _isArchiving = false;
  bool _isUnarchiving = false;
  String? _error;

  final TextEditingController _exerciseSetTitleController =
      TextEditingController();

  String _exerciseSetStatus = 'draft';
  bool _hasUnsavedChanges = false;

  final List<_TeacherExerciseFormItem> _questions = [];

  bool _isReordering = false;

  Color _publishedColor(BuildContext context) => Theme.of(context).colorScheme.primary;
  Color _draftColor(BuildContext context) => const Color(0xFFB06A1C);
  Color _archivedColor(BuildContext context) => Theme.of(context).colorScheme.secondary;
  Color _deletedColor(BuildContext context) => Theme.of(context).colorScheme.error;
  Color _inactiveColor(BuildContext context) =>
      Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.92) ??
      Theme.of(context).colorScheme.secondary;
  Color _editedColor(BuildContext context) => Theme.of(context).colorScheme.tertiary;

  @override
  void initState() {
    super.initState();
    _exerciseService = LessonExerciseService(); // removed baseUrl
    _loadExerciseDraft();
  }

  @override
  void dispose() {
    _exerciseSetTitleController.dispose();
    _scrollController.dispose();
    for (final item in _questions) {
      item.dispose();
    }
    // _exerciseService.dispose();
    super.dispose();
  }

  bool get _hasOpenEditorChanges =>
      _questions.any((item) => item.hasPendingEditorChanges);

  void _markApiDirty() {
    if (!_hasUnsavedChanges && mounted) {
      setState(() => _hasUnsavedChanges = true);
    }
  }

  Future<void> _loadExerciseDraft() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // ✅ removed teacherCode
      final data = await _exerciseService.fetchTeacherExerciseDraft(
        lessonId: widget.lessonId,
      );
      _rebuildFromApi(data ?? {});
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges && !_hasOpenEditorChanges) return true;

    final l10n = AppLocalizations.of(context);

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return AlertDialog(
          backgroundColor: theme.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(l10n.lessonExercisesLeavePageTitle),
          content: Text(
            _hasOpenEditorChanges
                ? l10n.lessonExercisesLeaveOpenEdits
                : l10n.lessonExercisesLeaveUnsavedChanges,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.lessonExercisesStay),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.lessonExercisesLeave),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  void _showSnack(String message) {
    if (!mounted) return;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        content: Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: isDark ? 0.35 : 0.65),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.08),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Text(
            message,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  void _clearQuestions() {
    for (final item in _questions) {
      item.dispose();
    }
    _questions.clear();
  }

  void _rebuildFromApi(Map<String, dynamic> data) {
    _clearQuestions();

    _exerciseSetTitleController.text =
        (data['title'] ?? AppLocalizations.of(context).lessonExercisesTitle).toString();
    _exerciseSetStatus = (data['status'] ?? 'draft').toString();

    final draftItemsRaw = (data['draft_items'] as List?)
            ?.whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList() ??
        <Map<String, dynamic>>[];

    draftItemsRaw.sort((a, b) {
      final ap = _readInt(a['position'], fallback: 0);
      final bp = _readInt(b['position'], fallback: 0);
      return ap.compareTo(bp);
    });

    for (final itemData in draftItemsRaw) {
      final item = _TeacherExerciseFormItem.fromApi(
        itemData,
        () {},
      );
      item.serverStatus = _exerciseSetStatus;
      _questions.add(item);
    }

    setState(() {
      _hasUnsavedChanges = false;
      _error = null;
    });
  }

  int _readInt(dynamic value, {int fallback = 1}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  Future<void> _showAddQuestionDialog() async {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: theme.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.lessonExercisesAddQuestion,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.lessonExercisesChooseQuestionType,
                  style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color
                        ?.withValues(alpha: 0.72),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                _dialogActionTile(
                  icon: Icons.list_alt_rounded,
                  title: l10n.lessonExercisesMultipleChoice,
                  subtitle: l10n.lessonExercisesMultipleChoiceSubtitle,
                  color: _publishedColor(context),
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    await _addQuestion(_TeacherQuestionType.multipleChoice);
                  },
                ),
                _dialogActionTile(
                  icon: Icons.toggle_on_outlined,
                  title: l10n.lessonExercisesTrueFalse,
                  subtitle: l10n.lessonExercisesTrueFalseSubtitle,
                  color: _draftColor(context),
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    await _addQuestion(_TeacherQuestionType.trueFalse);
                  },
                ),
                _dialogActionTile(
                  icon: Icons.short_text_rounded,
                  title: l10n.lessonExercisesShortAnswer,
                  subtitle: l10n.lessonExercisesShortAnswerSubtitle,
                  color: _editedColor(context),
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    await _addQuestion(_TeacherQuestionType.shortAnswer);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _dialogActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.72),
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
      ),
    );
  }

  Future<bool> _prepareToFocusQuestion({int? nextIndex}) async {
    final l10n = AppLocalizations.of(context);
    final openIndexes = <int>[];
    bool hasPendingChanges = false;

    for (int i = 0; i < _questions.length; i++) {
      if (!_questions[i].isExpanded) continue;
      if (nextIndex != null && i == nextIndex) continue;
      openIndexes.add(i);
      if (_questions[i].hasPendingEditorChanges) {
        hasPendingChanges = true;
      }
    }

    if (openIndexes.isEmpty) return true;

    if (hasPendingChanges) {
      final shouldDiscard = await _confirmDialog(
        title: l10n.lessonExercisesDiscardCurrentEditsTitle,
        content:
            l10n.lessonExercisesDiscardOpeningContent,
        confirmText: l10n.lessonExercisesDiscard,
        confirmColor: Colors.red,
      );

      if (shouldDiscard != true) return false;
    }

    for (final index in openIndexes) {
      final item = _questions[index];
      if (item.hasPendingEditorChanges) {
        item.discardEditing();
      }
    }

    setState(() {
      for (final index in openIndexes) {
        _questions[index].isExpanded = false;
      }
    });

    return true;
  }

  Future<void> _addQuestion(_TeacherQuestionType type) async {
    final canOpenNewQuestion = await _prepareToFocusQuestion();
    if (!canOpenNewQuestion) return;

    final item = _TeacherExerciseFormItem.createNew(
      type: type,
      onEditorChanged: () {},
    )..serverStatus = 'draft';

    setState(() {
      _questions.add(item);
      item.beginEditing();
      item.isExpanded = true;
      _hasUnsavedChanges = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!_scrollController.hasClients) return;
      await _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 260,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _toggleExpansion(int index) async {
    final l10n = AppLocalizations.of(context);
    final item = _questions[index];

    if (item.isExpanded) {
      if (item.hasPendingEditorChanges) {
        final shouldDiscard = await _confirmDialog(
          title: l10n.lessonExercisesDiscardCurrentEditsTitle,
          content:
              l10n.lessonExercisesDiscardCollapseContent,
          confirmText: l10n.lessonExercisesDiscard,
          confirmColor: Colors.red,
        );

        if (shouldDiscard != true) return;
        item.discardEditing();
      }

      setState(() {
        item.isExpanded = false;
      });
      return;
    }

    final canOpen = await _prepareToFocusQuestion(nextIndex: index);
    if (!canOpen) return;

    setState(() {
      item.beginEditing();
      item.isExpanded = true;
    });
  }

  Future<void> _saveQuestionChanges(_TeacherExerciseFormItem item) async {
    final l10n = AppLocalizations.of(context);
    final validation = item.validateEditor(AppLocalizations.of(context));
    if (validation != null) {
      _showSnack(validation);
      return;
    }

    setState(() {
      item.saveEditing();
      item.isExpanded = true;
      if (!item.isDeleted && !item.isArchived) {
        item.localStatusOverride = 'draft';
      }
      _hasUnsavedChanges = true;
    });

    _showSnack(l10n.lessonExercisesQuestionSavedLocally);
  }

  void _discardQuestionChanges(_TeacherExerciseFormItem item) {
    final l10n = AppLocalizations.of(context);

    setState(() {
      item.discardEditing();
    });
    _showSnack(l10n.lessonExercisesLocalEditsDiscarded);
  }

  Future<void> _deleteQuestion(int index) async {
    final l10n = AppLocalizations.of(context);
    final item = _questions[index];

    if (!item.hasStableKey) {
      setState(() {
        final removed = _questions.removeAt(index);
        removed.dispose();
        _hasUnsavedChanges = true;
      });
      _showSnack(l10n.lessonExercisesQuestionDeletedLocally);
      return;
    }

    final confirm = await _confirmDialog(
      title: l10n.lessonExercisesDeleteQuestionTitle,
      content:
          l10n.lessonExercisesDeleteQuestionContent,
      confirmText: l10n.lessonExercisesDelete,
      confirmColor: Colors.red,
    );

    if (confirm != true) return;

    try {
      // ✅ removed teacherCode
      await _exerciseService.deleteDraftQuestion(
        lessonId: widget.lessonId,
        stableQuestionKey: item.stableQuestionKey!,
      );

      _showSnack(l10n.lessonExercisesQuestionDeleted);
      await _loadExerciseDraft();
    } catch (e) {
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _restoreQuestion(_TeacherExerciseFormItem item) async {
    final l10n = AppLocalizations.of(context);
    if (!item.hasStableKey) return;

    try {
      // ✅ removed teacherCode
      await _exerciseService.restoreDraftQuestion(
        lessonId: widget.lessonId,
        stableQuestionKey: item.stableQuestionKey!,
      );

      _showSnack(l10n.lessonExercisesQuestionRestored);
      await _loadExerciseDraft();
    } catch (e) {
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _archiveQuestion(_TeacherExerciseFormItem item) async {
    final l10n = AppLocalizations.of(context);
    if (!item.hasStableKey) {
      setState(() {
        item.isArchived = true;
        item.localStatusOverride = 'archived';
        _hasUnsavedChanges = true;
      });
      _showSnack(l10n.lessonExercisesQuestionArchivedLocally);
      return;
    }

    try {
      // ✅ removed teacherCode
      await _exerciseService.archiveDraftQuestion(
        lessonId: widget.lessonId,
        stableQuestionKey: item.stableQuestionKey!,
      );

      _showSnack(l10n.lessonExercisesQuestionArchived);
      await _loadExerciseDraft();
    } catch (e) {
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _unarchiveQuestion(_TeacherExerciseFormItem item) async {
    final l10n = AppLocalizations.of(context);
    if (!item.hasStableKey) {
      setState(() {
        item.isArchived = false;
        item.localStatusOverride = 'draft';
        _hasUnsavedChanges = true;
      });
      _showSnack(l10n.lessonExercisesQuestionUnarchivedLocally);
      return;
    }

    try {
      // ✅ removed teacherCode
      await _exerciseService.unarchiveDraftQuestion(
        lessonId: widget.lessonId,
        stableQuestionKey: item.stableQuestionKey!,
      );

      _showSnack(l10n.lessonExercisesQuestionUnarchived);
      await _loadExerciseDraft();
    } catch (e) {
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<bool?> _confirmDialog({
    required String title,
    required String content,
    required String confirmText,
    Color? confirmColor,
  }) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.lessonExercisesCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: confirmColor == null
                ? null
                : ElevatedButton.styleFrom(backgroundColor: confirmColor),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  String? _validateAllQuestions() {
    final l10n = AppLocalizations.of(context);
    final publishableQuestions = _questions.where(
      (q) => !q.isDeleted && !q.isArchived,
    );

    if (publishableQuestions.isEmpty) {
      return l10n.lessonExercisesAddActiveQuestionValidation;
    }

    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      final label = l10n.lessonExercisesQuestionLabel(i + 1);

      if (q.isDeleted || q.isArchived) continue;

      if (q.questionController.text.trim().isEmpty) {
        return l10n.lessonExercisesQuestionNeedsText(label);
      }

      if (q.pointsValue <= 0) {
        return l10n.lessonExercisesQuestionNeedsPoints(label);
      }

      if (q.type == _TeacherQuestionType.multipleChoice) {
        if (q.options.length < 2) {
          return l10n.lessonExercisesQuestionNeedsTwoOptions(label);
        }

        int correctCount = 0;
        for (final option in q.options) {
          if (option.textController.text.trim().isEmpty) {
            return l10n.lessonExercisesQuestionEmptyOption(label);
          }
          if (option.isCorrect) correctCount++;
        }

        if (correctCount != 1) {
          return l10n.lessonExercisesQuestionOneCorrect(label);
        }
      }

      if (q.type == _TeacherQuestionType.shortAnswer &&
          q.answerController.text.trim().isEmpty) {
        return l10n.lessonExercisesQuestionCorrectAnswerRequired(label);
      }
    }

    return null;
  }

  List<Map<String, dynamic>> _buildQuestionsPayload() {
    final payload = <Map<String, dynamic>>[];

    for (int i = 0; i < _questions.length; i++) {
      final item = _questions[i];
      final position = i + 1;
      final explanation = item.explanationController.text.trim().isEmpty
          ? null
          : item.explanationController.text.trim();

      switch (item.type) {
        case _TeacherQuestionType.multipleChoice:
          payload.add({
            if (item.stableQuestionKey != null)
              'stable_question_key': item.stableQuestionKey,
            'origin': item.origin,
            'type': 'multiple_choice',
            'question_text': item.questionController.text.trim(),
            'points': item.pointsValue,
            'position': position,
            'explanation': explanation,
            'is_active': item.isActive,
            'is_archived': item.isArchived,
            'options': List.generate(item.options.length, (optionIndex) {
              final option = item.options[optionIndex];
              return {
                if (option.stableOptionKey != null)
                  'stable_option_key': option.stableOptionKey,
                'option_text': option.textController.text.trim(),
                'is_correct': option.isCorrect,
                'position': optionIndex + 1,
              };
            }),
          });
          break;

        case _TeacherQuestionType.trueFalse:
          payload.add({
            if (item.stableQuestionKey != null)
              'stable_question_key': item.stableQuestionKey,
            'origin': item.origin,
            'type': 'true_false',
            'question_text': item.questionController.text.trim(),
            'points': item.pointsValue,
            'position': position,
            'explanation': explanation,
            'is_active': item.isActive,
            'is_archived': item.isArchived,
            'options': [
              {
                if (item.trueOptionStableKey != null)
                  'stable_option_key': item.trueOptionStableKey,
                'option_text': 'True',
                'is_correct': item.trueFalseCorrectIsTrue,
                'position': 1,
              },
              {
                if (item.falseOptionStableKey != null)
                  'stable_option_key': item.falseOptionStableKey,
                'option_text': 'False',
                'is_correct': !item.trueFalseCorrectIsTrue,
                'position': 2,
              },
            ],
          });
          break;

        case _TeacherQuestionType.shortAnswer:
          payload.add({
            if (item.stableQuestionKey != null)
              'stable_question_key': item.stableQuestionKey,
            'origin': item.origin,
            'type': 'short_answer',
            'question_text': item.questionController.text.trim(),
            'correct_text_answer': item.answerController.text.trim(),
            'points': item.pointsValue,
            'position': position,
            'explanation': explanation,
            'is_active': item.isActive,
            'is_archived': item.isArchived,
            'options': const [],
          });
          break;
      }
    }

    return payload;
  }

  Future<void> _saveExercises() async {
    final l10n = AppLocalizations.of(context);
    if (_hasOpenEditorChanges) {
      _showSnack(l10n.lessonExercisesSaveOrDiscardOpenChanges);
      return;
    }

    final validation = _validateAllQuestions();
    if (validation != null) {
      _showSnack(validation);
      return;
    }

    setState(() => _isSaving = true);

    try {
      // ✅ removed teacherCode
      final data = await _exerciseService.saveTeacherExerciseDraft(
        lessonId: widget.lessonId,
        title: _exerciseSetTitleController.text.trim().isEmpty
            ? l10n.lessonExercisesTitle
            : _exerciseSetTitleController.text.trim(),
        generationSource: 'manual',
        questions: _buildQuestionsPayload(),
      );

      _showSnack(
        _exerciseSetStatus == 'published'
            ? l10n.lessonExercisesChangesSavedNowDraft
            : l10n.lessonExercisesDraftSaved,
      );

      _rebuildFromApi(data);
    } catch (e) {
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _publishExercises() async {
    final l10n = AppLocalizations.of(context);
    if (_hasOpenEditorChanges) {
      _showSnack(l10n.lessonExercisesSaveOrDiscardOpenChanges);
      return;
    }

    if (_hasUnsavedChanges) {
      _showSnack(l10n.lessonExercisesSaveBeforePublish);
      return;
    }

    final publishableQuestions = _questions.where(
      (q) => !q.isDeleted && !q.isArchived,
    );

    if (publishableQuestions.isEmpty) {
      _showSnack(l10n.lessonExercisesNoPublishableQuestions);
      return;
    }

    setState(() => _isPublishing = true);

    try {
      // ✅ removed teacherCode
      await _exerciseService.publishTeacherExerciseSet(
        lessonId: widget.lessonId,
      );

      _showSnack(l10n.lessonExercisesPublishedSuccess);
      await _loadExerciseDraft();
    } catch (e) {
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isPublishing = false);
      }
    }
  }

  Future<void> _archiveExercises() async {
    final l10n = AppLocalizations.of(context);
    final confirm = await _confirmDialog(
      title: l10n.lessonExercisesArchiveSetTitle,
      content:
          l10n.lessonExercisesArchiveSetContent,
      confirmText: l10n.lessonExercisesArchive,
      confirmColor: Colors.red,
    );

    if (confirm != true) return;

    setState(() => _isArchiving = true);

    try {
      // ✅ removed teacherCode
      final data = await _exerciseService.archiveTeacherExerciseSet(
        lessonId: widget.lessonId,
      );

      _showSnack(l10n.lessonExercisesSetArchived);
      _rebuildFromApi(data);
    } catch (e) {
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isArchiving = false);
      }
    }
  }

  Future<void> _unarchiveExercises() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _isUnarchiving = true);

    try {
      // ✅ removed teacherCode
      final data = await _exerciseService.unarchiveTeacherExerciseSet(
        lessonId: widget.lessonId,
      );

      _showSnack(l10n.lessonExercisesSetUnarchived);
      _rebuildFromApi(data);
    } catch (e) {
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isUnarchiving = false);
      }
    }
  }

  int get _publishedCount =>
      _questions.where((q) => _effectiveStatus(q) == 'published').length;

  int get _draftCount =>
      _questions.where((q) => _effectiveStatus(q) == 'draft').length;

  int get _archivedCount =>
      _questions.where((q) => _effectiveStatus(q) == 'archived').length;

  int get _deletedCount =>
      _questions.where((q) => _effectiveStatus(q) == 'deleted').length;

  int get _editedCount =>
      _questions.where((q) => _effectiveStatus(q) == 'edited').length;

  double get _totalPoints {
    return _questions
        .where((q) => !q.isDeleted)
        .fold<double>(0, (sum, item) => sum + item.pointsValue);
  }

  String _effectiveStatus(_TeacherExerciseFormItem item) {
    if (item.isDeleted) return 'deleted';
    if (item.isArchived) return 'archived';
    if (item.localStatusOverride != null) return item.localStatusOverride!;
    if (!item.isActive) return 'inactive';
    final status = item.serverStatus.trim().toLowerCase();
    if (status == 'published') return 'published';
    if (status == 'archived') return 'archived';
    return 'draft';
  }

  String _statusLabel(String status) {
    final l10n = AppLocalizations.of(context);
    switch (status) {
      case 'published':
        return l10n.lessonExercisesStatusPublished;
      case 'archived':
        return l10n.lessonExercisesStatusArchived;
      case 'deleted':
        return l10n.lessonExercisesStatusDeleted;
      case 'inactive':
        return l10n.lessonExercisesStatusInactive;
      case 'edited':
        return l10n.lessonExercisesStatusEdited;
      default:
        return l10n.lessonExercisesStatusDraft;
    }
  }

  Color _statusColor(BuildContext context, String status) {
    switch (status) {
      case 'published':
        return _publishedColor(context);
      case 'archived':
        return _archivedColor(context);
      case 'deleted':
        return _deletedColor(context);
      case 'inactive':
        return _inactiveColor(context);
      case 'edited':
        return _editedColor(context);
      default:
        return _draftColor(context);
    }
  }

  Color _typeColor(BuildContext context, _TeacherQuestionType type) {
    switch (type) {
      case _TeacherQuestionType.multipleChoice:
        return _publishedColor(context);
      case _TeacherQuestionType.trueFalse:
        return _draftColor(context);
      case _TeacherQuestionType.shortAnswer:
        return _editedColor(context);
    }
  }

  void _reorderQuestions(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _questions.length) return;
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _questions.removeAt(oldIndex);
      _questions.insert(newIndex.clamp(0, _questions.length), item);
      _hasUnsavedChanges = true;
      _isReordering = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Text(
            l10n.lessonExercisesTitle,
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () async {
              final canLeave = await _onWillPop();
              if (canLeave && mounted) Navigator.of(context).pop();
            },
          ),
          actions: [
            PopupMenuButton<String>(
              tooltip: l10n.lessonExercisesMore,
              onSelected: (value) async {
                switch (value) {
                  case 'refresh':
                    await _loadExerciseDraft();
                    break;
                  case 'archive_set':
                    await _archiveExercises();
                    break;
                  case 'unarchive_set':
                    await _unarchiveExercises();
                    break;
                }
              },
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  value: 'refresh',
                  child: Text(l10n.lessonExercisesRefresh),
                ),
                PopupMenuItem(
                  value: _exerciseSetStatus == 'archived'
                      ? 'unarchive_set'
                      : 'archive_set',
                  child: Text(
                    _exerciseSetStatus == 'archived'
                        ? l10n.lessonExercisesUnarchiveSet
                        : l10n.lessonExercisesArchiveSet,
                  ),
                ),
              ],
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomActionBar(),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildError()
                : _buildContent(),
      ),
    );
  }

  Widget _buildError() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.55),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.lessonExercisesUnableLoad,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error ?? '',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color:
                      theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.72),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _loadExerciseDraft,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(l10n.lessonExercisesRetry),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return SafeArea(
      child: ReorderableListView.builder(
        scrollController: _scrollController,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 140),
        buildDefaultDragHandles: false,
        itemCount: _questions.length,
        header: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopMetricsCard(),
            const SizedBox(height: 18),
          ],
        ),
        footer: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: _buildAddQuestionCard(),
        ),
        proxyDecorator: (child, index, animation) {
          return AnimatedBuilder(
            animation: animation,
            builder: (context, _) {
              final value = Curves.easeOutCubic.transform(animation.value);
              return Transform.scale(
                scale: 1 + (0.018 * value),
                child: Material(
                  color: Colors.transparent,
                  child: child,
                ),
              );
            },
          );
        },
        onReorderStart: (_) {
          HapticFeedback.mediumImpact();
          if (!_isReordering && mounted) {
            setState(() => _isReordering = true);
          }
        },
        onReorderEnd: (_) {
          if (_isReordering && mounted) {
            setState(() => _isReordering = false);
          }
        },
        onReorder: _reorderQuestions,
        itemBuilder: (context, index) {
          final item = _questions[index];
          return Padding(
            key: ValueKey(item.stableQuestionKey ?? 'local_${index}_${item.hashCode}'),
            padding: const EdgeInsets.only(bottom: 14),
            child: _buildQuestionCard(index, item),
          );
        },
      ),
    );
  }


  Widget _buildTopMetricsCard() {
    final l10n = AppLocalizations.of(context);
    final total = math.max(_questions.length, 1);
    final publishedFlex = _publishedCount;
    final draftFlex = _draftCount;
    final archivedFlex = _archivedCount;
    final deletedFlex = _deletedCount;
    final editedFlex = _editedCount;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _metricBlock(l10n.lessonExercisesQuestionsMetric, '${_questions.length}'),
              const Spacer(),
              _metricBlock(l10n.lessonExercisesTotalPointsMetric, _totalPoints % 1 == 0
                  ? _totalPoints.toInt().toString()
                  : _totalPoints.toStringAsFixed(1)),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 9,
              child: Row(
                children: [
                  if (publishedFlex > 0)
                    Expanded(
                      flex: publishedFlex,
                      child: Container(color: _publishedColor(context)),
                    ),
                  if (draftFlex > 0)
                    Expanded(
                      flex: draftFlex,
                      child: Container(color: _draftColor(context)),
                    ),
                  if (archivedFlex > 0)
                    Expanded(
                      flex: archivedFlex,
                      child: Container(color: _archivedColor(context)),
                    ),
                  if (deletedFlex > 0)
                    Expanded(
                      flex: deletedFlex,
                      child: Container(color: _deletedColor(context)),
                    ),
                  if (editedFlex > 0)
                    Expanded(
                      flex: editedFlex,
                      child: Container(color: _editedColor(context)),
                    ),
                  if (publishedFlex +
                          draftFlex +
                          archivedFlex +
                          deletedFlex +
                          editedFlex ==
                      0)
                    Expanded(
                      flex: total,
                      child: Container(color: Theme.of(context).dividerColor),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 14,
            runSpacing: 10,
            children: [
              _legendItem(l10n.lessonExercisesStatusPublished, _publishedColor(context), _publishedCount),
              _legendItem(l10n.lessonExercisesStatusDraft, _draftColor(context), _draftCount),
              _legendItem(l10n.lessonExercisesStatusArchived, _archivedColor(context), _archivedCount),
              _legendItem(l10n.lessonExercisesStatusDeleted, _deletedColor(context), _deletedCount),
              if (_editedCount > 0)
                _legendItem(l10n.lessonExercisesStatusEdited, _editedColor(context), _editedCount),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricBlock(String label, String value) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            letterSpacing: 1.4,
            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.78),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _legendItem(String text, Color color, int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$text ($count)',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionCard(int index, _TeacherExerciseFormItem item) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final status = _effectiveStatus(item);
    final statusColor = _statusColor(context, status);
    final typeColor = _typeColor(context, item.type);
    final showUnsavedBadge = item.hasPendingEditorChanges;
    final cardBorderColor = item.isExpanded
        ? theme.colorScheme.primary.withValues(alpha: 0.42)
        : theme.dividerColor.withValues(alpha: 0.34);

    final header = InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => _toggleExpansion(index),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, item.isExpanded ? 16 : 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _toggleExpansion(index),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2, right: 6, bottom: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.isExpanded
                              ? Icons.unfold_less_rounded
                              : Icons.unfold_more_rounded,
                          size: 20,
                          color: theme.iconTheme.color?.withValues(alpha: 0.84),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          l10n.lessonExercisesQuestionLabel(index + 1),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _QuestionPill(
                          text: item.type.shortLabel(l10n),
                          color: typeColor,
                        ),
                        const SizedBox(width: 8),
                        _QuestionPill(
                          text: _statusLabel(status),
                          color: statusColor,
                          outlined: status == 'draft' || status == 'archived',
                        ),
                        if (showUnsavedBadge) ...[
                          const SizedBox(width: 8),
                          _QuestionPill(
                            text: l10n.lessonExercisesStatusUnsaved,
                            color: theme.colorScheme.tertiary,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _QuestionMenuButton(
                  statusColor: statusColor,
                  isDeleted: item.isDeleted,
                  isArchived: item.isArchived,
                  onSelected: (value) async {
                    switch (value) {
                      case 'delete':
                        await _deleteQuestion(index);
                        break;
                      case 'restore':
                        await _restoreQuestion(item);
                        break;
                      case 'archive':
                        await _archiveQuestion(item);
                        break;
                      case 'unarchive':
                        await _unarchiveQuestion(item);
                        break;
                    }
                  },
                ),
              ],
            ),
            if (!item.isExpanded) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.previewTitle(l10n),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        height: 1.35,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ReorderableDragStartListener(
                    index: index,
                    child: _QuestionDragHandle(compact: true),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  _MetaTinyPill(
                    icon: Icons.stars_rounded,
                    text: '${_formatPoints(item.pointsValue)} ${l10n.lessonExercisesPointsShort}',
                  ),
                  const SizedBox(width: 8),
                  _MetaTinyPill(
                    icon: item.isActive
                        ? Icons.check_circle_rounded
                        : Icons.pause_circle_rounded,
                    text: item.isActive ? l10n.lessonExercisesActive : l10n.lessonExercisesStatusInactive,
                  ),
                  const Spacer(),
                  ReorderableDragStartListener(
                    index: index,
                    child: const _QuestionDragHandle(),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cardBorderColor, width: item.isExpanded ? 1.3 : 1),
        boxShadow: [
          BoxShadow(
            color: (item.isExpanded ? theme.colorScheme.primary : Colors.black).withValues(
              alpha: item.isExpanded
                  ? (theme.brightness == Brightness.dark ? 0.16 : 0.09)
                  : (theme.brightness == Brightness.dark ? 0.18 : 0.05),
            ),
            blurRadius: item.isExpanded ? 20 : 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            Container(
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    statusColor,
                    statusColor.withValues(alpha: 0.42),
                  ],
                ),
              ),
            ),
            header,
            if (item.isExpanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: _buildExpandedQuestionBody(item),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedQuestionBody(_TeacherExerciseFormItem item) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 2),
        _EditorSection(
          title: l10n.lessonExercisesQuestionTextSection,
          child: _QuestionTextField(
            controller: item.editorQuestionController!,
            hintText: l10n.lessonExercisesQuestionTextHint,
            minLines: 3,
            maxLines: null,
            textInputAction: TextInputAction.newline,
            onChanged: (value) {
              item.questionController.text = value;
              _markApiDirty();
            },
          ),
        ),
        const SizedBox(height: 16),
        _buildEditorByType(item),
        const SizedBox(height: 16),
        _EditorSection(
          title: l10n.lessonExercisesExplanationSection,
          child: _QuestionTextField(
            controller: item.editorExplanationController!,
            hintText: l10n.lessonExercisesExplanationHint,
            minLines: 2,
            maxLines: null,
            textInputAction: TextInputAction.newline,
            onChanged: (value) {
              item.explanationController.text = value;
              _markApiDirty();
            },
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: 120,
          child: _QuestionTextField(
            controller: item.editorPointsController!,
            hintText: '0',
            labelText: l10n.lessonExercisesPointsLabel,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.done,
            minLines: 1,
            maxLines: 1,
            onChanged: (value) {
              item.pointsController.text = value;
              _markApiDirty();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEditorByType(_TeacherExerciseFormItem item) {
    switch (item.type) {
      case _TeacherQuestionType.multipleChoice:
        return _buildMultipleChoiceEditor(item);
      case _TeacherQuestionType.trueFalse:
        return _buildTrueFalseEditor(item);
      case _TeacherQuestionType.shortAnswer:
        return _buildShortAnswerEditor(item);
    }
  }

  Widget _buildMultipleChoiceEditor(_TeacherExerciseFormItem item) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return _EditorSection(
      title: l10n.lessonExercisesOptionsSection,
      trailing: TextButton.icon(
        onPressed: () {
          setState(() {
            final option = _TeacherQuestionOptionItem.createNewDraft();
            final committedOption = _TeacherQuestionOptionItem.createNewCommitted();
            item.editorOptions.add(option);
            item.options.add(committedOption);
            if (item.editorOptions.length == 1) {
              option.isCorrect = true;
              committedOption.isCorrect = true;
            }
            _hasUnsavedChanges = true;
          });
        },
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.lessonExercisesAddOption),
      ),
      child: Column(
        children: List.generate(item.editorOptions.length, (index) {
          final option = item.editorOptions[index];
          final letter = String.fromCharCode(65 + index);
          final selected = option.isCorrect;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              decoration: BoxDecoration(
                color: selected
                    ? _publishedColor(context).withValues(alpha: 0.08)
                    : theme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected
                      ? _publishedColor(context)
                      : theme.dividerColor.withValues(alpha: 0.40),
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () {
                      setState(() {
                        for (int optionIndex = 0;
                            optionIndex < item.editorOptions.length;
                            optionIndex++) {
                          final isCurrent = optionIndex == index;
                          item.editorOptions[optionIndex].isCorrect = isCurrent;
                          if (optionIndex < item.options.length) {
                            item.options[optionIndex].isCorrect = isCurrent;
                          }
                        }
                        option.isCorrect = true;
                        _hasUnsavedChanges = true;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected
                            ? _publishedColor(context)
                            : Colors.transparent,
                        border: Border.all(
                          color: selected
                              ? _publishedColor(context)
                              : theme.dividerColor,
                          width: 2,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: selected
                          ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                          : Text(
                              letter,
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                                height: 1,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              l10n.lessonExercisesOptionLabel(letter),
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (selected)
                              _QuestionPill(
                                text: l10n.lessonExercisesCorrectAnswer,
                                color: _publishedColor(context),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ConstrainedBox(
                          constraints: const BoxConstraints(
                            minHeight: 52,
                            maxHeight: 92,
                          ),
                          child: _QuestionTextField(
                            controller: option.textController,
                            hintText: l10n.lessonExercisesOptionTextHint,
                            minLines: 1,
                            maxLines: 3,
                            textInputAction: TextInputAction.newline,
                            onChanged: (value) {
                              if (index < item.options.length) {
                                item.options[index].textController.text = value;
                              }
                              _markApiDirty();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: item.editorOptions.length <= 2
                        ? null
                        : () {
                            setState(() {
                              final removed = item.editorOptions.removeAt(index);
                              removed.dispose();
                              if (index < item.options.length) {
                                final committed = item.options.removeAt(index);
                                committed.dispose();
                              }
                              if (item.editorOptions.every((e) => !e.isCorrect) &&
                                  item.editorOptions.isNotEmpty) {
                                item.editorOptions.first.isCorrect = true;
                              }
                              if (item.options.every((e) => !e.isCorrect) &&
                                  item.options.isNotEmpty) {
                                item.options.first.isCorrect = true;
                              }
                              _hasUnsavedChanges = true;
                            });
                          },
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTrueFalseEditor(_TeacherExerciseFormItem item) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    Widget buildChoice({
      required String label,
      required bool selected,
      required VoidCallback onTap,
    }) {
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            height: 62,
            decoration: BoxDecoration(
              color: selected
                  ? _draftColor(context).withValues(alpha: 0.12)
                  : theme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected
                    ? _draftColor(context)
                    : theme.dividerColor.withValues(alpha: 0.4),
                width: selected ? 1.6 : 1,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                color: selected ? _draftColor(context) : theme.colorScheme.onSurface,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ),
        ),
      );
    }

    return _EditorSection(
      title: l10n.lessonExercisesCorrectAnswerSection,
      child: Row(
        children: [
          buildChoice(
            label: l10n.lessonExercisesTrue,
            selected: item.editorTrueFalseCorrectIsTrue,
            onTap: () {
              setState(() {
                item.editorTrueFalseCorrectIsTrue = true;
                item.trueFalseCorrectIsTrue = true;
                _hasUnsavedChanges = true;
              });
            },
          ),
          const SizedBox(width: 12),
          buildChoice(
            label: l10n.lessonExercisesFalse,
            selected: !item.editorTrueFalseCorrectIsTrue,
            onTap: () {
              setState(() {
                item.editorTrueFalseCorrectIsTrue = false;
                item.trueFalseCorrectIsTrue = false;
                _hasUnsavedChanges = true;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildShortAnswerEditor(_TeacherExerciseFormItem item) {
    final l10n = AppLocalizations.of(context);
    return _EditorSection(
      title: l10n.lessonExercisesCorrectAnswerSection,
      child: _QuestionTextField(
        controller: item.editorAnswerController!,
        hintText: l10n.lessonExercisesShortAnswerHint,
        minLines: 2,
        maxLines: null,
        textInputAction: TextInputAction.newline,
        onChanged: (value) {
          item.answerController.text = value;
          _markApiDirty();
        },
      ),
    );
  }

  Widget _buildAddQuestionCard() {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return GestureDetector(
      onTap: _showAddQuestionDialog,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: theme.dividerColor.withValues(alpha: 0.50),
            style: BorderStyle.solid,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: theme.brightness == Brightness.dark ? 0.16 : 0.05,
              ),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add_rounded,
                size: 34,
                color: accent,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.lessonExercisesAddQuestionTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.lessonExercisesAddQuestionSubtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.76),
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActionBar() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isBusy =
        _isSaving || _isPublishing || _isArchiving || _isUnarchiving;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: theme.cardColor.withValues(alpha: 0.98),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: Border(
          top: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.52),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.22 : 0.10,
            ),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isBusy ? null : _saveExercises,
                icon: _isSaving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(l10n.lessonExercisesSaveDraft),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: isBusy ? null : _publishExercises,
                icon: _isPublishing
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.publish_rounded),
                label: Text(l10n.lessonExercisesPublish),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPoints(double value) {
    return value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(1);
  }
}