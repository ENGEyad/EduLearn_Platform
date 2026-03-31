import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../theme.dart';

class LessonExercisesScreen extends StatefulWidget {
  final int lessonId;
  final String teacherCode;
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

  @override
  void initState() {
    super.initState();
    _exerciseService = LessonExerciseService(baseUrl: baseUrl);
    _exerciseSetTitleController.text = 'تمارين الدرس';
    _exerciseSetTitleController.addListener(_markDirtySilently);
    _loadExerciseDraft();
  }

  @override
  void dispose() {
    _exerciseSetTitleController.removeListener(_markDirtySilently);
    _exerciseSetTitleController.dispose();
    for (final item in _questions) {
      item.dispose();
    }
    _exerciseService.dispose();
    super.dispose();
  }

  void _markDirtySilently() {
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
      final data = await _exerciseService.fetchTeacherExerciseDraft(
        lessonId: widget.lessonId,
        teacherCode: widget.teacherCode,
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
    if (!_hasUnsavedChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return AlertDialog(
          backgroundColor: theme.cardColor,
          title: const Text('Unsaved changes'),
          content: const Text(
            'هناك تعديلات غير محفوظة في التمارين. هل تريد الخروج؟',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('البقاء'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('الخروج'),
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
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: isDark ? 0.35 : 0.65),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Text(
            message,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
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
        (data['title'] ?? 'تمارين الدرس').toString();
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

    for (final item in draftItemsRaw) {
      _questions.add(
        _TeacherExerciseFormItem.fromApi(item, _markDirtySilently),
      );
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

  double _readDouble(dynamic value, {double fallback = 1}) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  Future<void> _showAddQuestionSheet() async {
    final theme = Theme.of(context);

    await showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _sheetAction(
                  icon: Icons.list_alt_rounded,
                  title: 'اختيار من متعدد',
                  subtitle: 'سؤال مع عدة خيارات وإجابة صحيحة واحدة',
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _addQuestion(_TeacherQuestionType.multipleChoice);
                  },
                ),
                _sheetAction(
                  icon: Icons.check_circle_outline_rounded,
                  title: 'صح / خطأ',
                  subtitle: 'سؤال بإجابتين: صح أو خطأ',
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _addQuestion(_TeacherQuestionType.trueFalse);
                  },
                ),
                _sheetAction(
                  icon: Icons.short_text_rounded,
                  title: 'إجابة قصيرة',
                  subtitle: 'سؤال مباشر مع إجابة نصية صحيحة',
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _addQuestion(_TeacherQuestionType.shortAnswer);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sheetAction({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
          foregroundColor: theme.colorScheme.primary,
          child: Icon(icon),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        subtitle: Text(subtitle),
      ),
    );
  }

  void _addQuestion(_TeacherQuestionType type) {
    setState(() {
      _questions.add(
        _TeacherExerciseFormItem.createNew(
          type: type,
          onChanged: _markDirtySilently,
        ),
      );
      _hasUnsavedChanges = true;
    });
  }

  Future<void> _deleteQuestion(int index) async {
    final item = _questions[index];

    if (!item.hasStableKey) {
      setState(() {
        _questions.removeAt(index).dispose();
        _hasUnsavedChanges = true;
      });
      return;
    }

    final confirm = await _confirmDialog(
      title: 'حذف السؤال',
      content:
          'سيتم تعليم السؤال كمحذوف داخل المسودة الحالية. يمكنك استعادته لاحقًا.',
      confirmText: 'حذف',
      confirmColor: Colors.red,
    );

    if (confirm != true) return;

    try {
      await _exerciseService.deleteDraftQuestion(
        lessonId: widget.lessonId,
        teacherCode: widget.teacherCode,
        stableQuestionKey: item.stableQuestionKey!,
      );

      _showSnack('تم حذف السؤال من المسودة.');
      await _loadExerciseDraft();
    } catch (e) {
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _restoreQuestion(_TeacherExerciseFormItem item) async {
    if (!item.hasStableKey) return;

    try {
      await _exerciseService.restoreDraftQuestion(
        lessonId: widget.lessonId,
        teacherCode: widget.teacherCode,
        stableQuestionKey: item.stableQuestionKey!,
      );

      _showSnack('تمت استعادة السؤال.');
      await _loadExerciseDraft();
    } catch (e) {
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _archiveQuestion(_TeacherExerciseFormItem item) async {
    if (!item.hasStableKey) return;

    try {
      await _exerciseService.archiveDraftQuestion(
        lessonId: widget.lessonId,
        teacherCode: widget.teacherCode,
        stableQuestionKey: item.stableQuestionKey!,
      );

      _showSnack('تمت أرشفة السؤال.');
      await _loadExerciseDraft();
    } catch (e) {
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _unarchiveQuestion(_TeacherExerciseFormItem item) async {
    if (!item.hasStableKey) return;

    try {
      await _exerciseService.unarchiveDraftQuestion(
        lessonId: widget.lessonId,
        teacherCode: widget.teacherCode,
        stableQuestionKey: item.stableQuestionKey!,
      );

      _showSnack('تم إلغاء أرشفة السؤال.');
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

    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('إلغاء'),
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
    if (_exerciseSetTitleController.text.trim().isEmpty) {
      return 'أدخل عنوانًا لمجموعة التمارين.';
    }

    final publishableQuestions = _questions.where(
      (q) => !q.isDeleted && !q.isArchived,
    );

    if (publishableQuestions.isEmpty) {
      return 'أضف سؤالًا واحدًا على الأقل أو ألغِ حذف/أرشفة سؤال موجود.';
    }

    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      final label = 'السؤال ${i + 1}';

      if (q.isDeleted || q.isArchived) {
        continue;
      }

      if (q.questionController.text.trim().isEmpty) {
        return '$label يحتاج نص السؤال.';
      }

      final points = q.pointsValue;
      if (points <= 0) {
        return '$label يحتاج درجة أكبر من صفر.';
      }

      if (q.type == _TeacherQuestionType.multipleChoice) {
        if (q.options.length < 2) {
          return '$label يحتاج خيارين على الأقل.';
        }

        int correctCount = 0;
        for (final option in q.options) {
          if (option.textController.text.trim().isEmpty) {
            return '$label يحتوي خيارًا فارغًا.';
          }
          if (option.isCorrect) {
            correctCount++;
          }
        }

        if (correctCount != 1) {
          return '$label يجب أن يحتوي إجابة صحيحة واحدة فقط.';
        }
      }

      if (q.type == _TeacherQuestionType.trueFalse) {
        // دائمًا يوجد اختيار واحد صحيح منطقيًا من المتغير نفسه
      }

      if (q.type == _TeacherQuestionType.shortAnswer) {
        if (q.answerController.text.trim().isEmpty) {
          return '$label يحتاج إجابة نصية صحيحة.';
        }
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
                'option_text': 'صح',
                'is_correct': item.trueFalseCorrectIsTrue,
                'position': 1,
              },
              {
                if (item.falseOptionStableKey != null)
                  'stable_option_key': item.falseOptionStableKey,
                'option_text': 'خطأ',
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
    final validation = _validateAllQuestions();
    if (validation != null) {
      _showSnack(validation);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final data = await _exerciseService.saveTeacherExerciseDraft(
        lessonId: widget.lessonId,
        teacherCode: widget.teacherCode,
        title: _exerciseSetTitleController.text.trim(),
        generationSource: 'manual',
        questions: _buildQuestionsPayload(),
      );

      _showSnack(
        _exerciseSetStatus == 'published'
            ? 'تم حفظ التعديلات. عادت المجموعة إلى حالة مسودة.'
            : 'تم حفظ المسودة بنجاح.',
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
    if (_hasUnsavedChanges) {
      _showSnack('احفظ التعديلات أولًا قبل النشر.');
      return;
    }

    final publishableQuestions = _questions.where(
      (q) => !q.isDeleted && !q.isArchived,
    );

    if (publishableQuestions.isEmpty) {
      _showSnack('لا توجد أسئلة قابلة للنشر.');
      return;
    }

    setState(() => _isPublishing = true);

    try {
      final data = await _exerciseService.publishTeacherExerciseSet(
        lessonId: widget.lessonId,
        teacherCode: widget.teacherCode,
      );

      _showSnack('تم نشر التمارين بنجاح.');
      final exerciseSet = LessonExerciseService.extractExerciseSet({
            'exercise_set': null,
          }) ??
          <String, dynamic>{};

      // لأن publish يرجع data فيه version غالبًا وليس draft نفسها
      // نعمل refresh كامل للشاشة بعد النشر حتى نقرأ draft الحالية والحالة الفعلية
      await _loadExerciseDraft();
      if (exerciseSet.isNotEmpty) {
        _rebuildFromApi(exerciseSet);
      } else {
        // تجاهل لأننا عملنا reload بالفعل
      }

      data;
    } catch (e) {
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isPublishing = false);
      }
    }
  }

  Future<void> _archiveExercises() async {
    final confirm = await _confirmDialog(
      title: 'أرشفة مجموعة التمارين',
      content:
          'سيتم إخفاء التمارين عن الطالب، لكن ستبقى متاحة لك للتعديل وإعادة النشر لاحقًا.',
      confirmText: 'أرشفة',
      confirmColor: Colors.red,
    );

    if (confirm != true) return;

    setState(() => _isArchiving = true);

    try {
      final data = await _exerciseService.archiveTeacherExerciseSet(
        lessonId: widget.lessonId,
        teacherCode: widget.teacherCode,
      );

      _showSnack('تمت أرشفة المجموعة.');
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
    setState(() => _isUnarchiving = true);

    try {
      final data = await _exerciseService.unarchiveTeacherExerciseSet(
        lessonId: widget.lessonId,
        teacherCode: widget.teacherCode,
      );

      _showSnack('تم إلغاء أرشفة المجموعة.');
      _rebuildFromApi(data);
    } catch (e) {
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isUnarchiving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: const Text('تمارين الدرس'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () async {
              final canLeave = await _onWillPop();
              if (canLeave && mounted) Navigator.of(context).pop();
            },
          ),
          actions: [
            IconButton(
              onPressed: _isLoading ? null : _loadExerciseDraft,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _isLoading ? null : _showAddQuestionSheet,
          icon: const Icon(Icons.add_rounded),
          label: const Text('إضافة سؤال'),
        ),
        bottomNavigationBar: _buildBottomBar(),
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

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 46,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              'تعذر تحميل التمارين',
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
                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.72),
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton(
              onPressed: _loadExerciseDraft,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final theme = Theme.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 130),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopSummaryCard(),
            const SizedBox(height: 18),
            _buildSetMetaCard(),
            const SizedBox(height: 22),
            Row(
              children: [
                Text(
                  'الأسئلة',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_questions.length} سؤال',
                  style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color
                        ?.withValues(alpha: 0.72),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (_questions.isEmpty)
              _EmptyExercisesCard(onAddPressed: _showAddQuestionSheet)
            else
              ...List.generate(
                _questions.length,
                (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _buildQuestionCard(index, _questions[index]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSummaryCard() {
    final theme = Theme.of(context);
    final statusColor = _statusColor(_exerciseSetStatus);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.55),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
                alpha: theme.brightness == Brightness.dark ? 0.16 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.assignment_turned_in_outlined,
              color: statusColor,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.lessonTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _StatusChip(
                      text: _humanizeStatus(_exerciseSetStatus),
                      color: statusColor,
                    ),
                    _StatusChip(
                      text: _hasUnsavedChanges ? 'تعديلات غير محفوظة' : 'محفوظ',
                      color: _hasUnsavedChanges ? Colors.orange : Colors.green,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetMetaCard() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.55),
        ),
      ),
      child: Column(
        children: [
          TextField(
            controller: _exerciseSetTitleController,
            style: TextStyle(color: theme.colorScheme.onSurface),
            decoration: InputDecoration(
              labelText: 'عنوان مجموعة التمارين',
              prefixIcon: Icon(
                Icons.quiz_outlined,
                color: theme.colorScheme.primary,
              ),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _InfoTile(
                  label: 'الدرس',
                  value: widget.lessonTitle,
                  icon: Icons.menu_book_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoTile(
                  label: 'الحالة',
                  value: _humanizeStatus(_exerciseSetStatus),
                  icon: Icons.flag_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_exerciseSetStatus == 'published')
            _buildHintBanner(
              color: Colors.orange,
              text:
                  'أي حفظ جديد بعد النشر سيعيد المجموعة إلى حالة مسودة حتى تُراجع وتنشر من جديد.',
            ),
          if (_exerciseSetStatus == 'archived') ...[
            if (_exerciseSetStatus == 'published') const SizedBox(height: 10),
            _buildHintBanner(
              color: Colors.red,
              text:
                  'المجموعة مؤرشفة حاليًا: لا تظهر للطالب، لكن ما زال بإمكانك التعديل عليها ثم إلغاء الأرشفة أو إعادة النشر.',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHintBanner({
    required Color color,
    required String text,
  }) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.20),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.w600,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildQuestionCard(int index, _TeacherExerciseFormItem item) {
    final theme = Theme.of(context);

    final isBlocked = item.isDeleted || item.isArchived;
    final statusColor = item.isDeleted
        ? Colors.red
        : item.isArchived
            ? Colors.orange
            : theme.colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.55),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.14 : 0.05,
            ),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ExpansionTile(
        initiallyExpanded: index == 0,
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.12),
          foregroundColor: statusColor,
          child: Text('${index + 1}'),
        ),
        title: ValueListenableBuilder<TextEditingValue>(
          valueListenable: item.questionController,
          builder: (_, value, __) {
            final text = value.text.trim();
            return Text(
              text.isEmpty ? 'سؤال جديد' : text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            );
          },
        ),
        subtitle: Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            Text(
              item.type.label,
              style: TextStyle(
                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.72),
              ),
            ),
            if (item.isDeleted)
              const _MiniFlagChip(
                text: 'محذوف',
                color: Colors.red,
              ),
            if (item.isArchived)
              const _MiniFlagChip(
                text: 'مؤرشف',
                color: Colors.orange,
              ),
            if (!item.isActive)
              const _MiniFlagChip(
                text: 'غير نشط',
                color: Colors.grey,
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
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
          itemBuilder: (ctx) => [
            if (!item.isDeleted)
              const PopupMenuItem(
                value: 'delete',
                child: Text('حذف السؤال'),
              ),
            if (item.isDeleted)
              const PopupMenuItem(
                value: 'restore',
                child: Text('استعادة السؤال'),
              ),
            if (!item.isArchived)
              const PopupMenuItem(
                value: 'archive',
                child: Text('أرشفة السؤال'),
              ),
            if (item.isArchived)
              const PopupMenuItem(
                value: 'unarchive',
                child: Text('إلغاء أرشفة السؤال'),
              ),
          ],
        ),
        children: [
          if (isBlocked)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildHintBanner(
                color: item.isDeleted ? Colors.red : Colors.orange,
                text: item.isDeleted
                    ? 'هذا السؤال محذوف من المسودة الحالية، لكنه ما زال ظاهرًا لك حتى تستعيده أو تعدله.'
                    : 'هذا السؤال مؤرشف حاليًا، ولن يظهر للطالب حتى تلغي أرشفته ثم تحفظ/تنشر.',
              ),
            ),
          DropdownButtonFormField<_TeacherQuestionType>(
            value: item.type,
            decoration: const InputDecoration(
              labelText: 'نوع السؤال',
              border: OutlineInputBorder(),
            ),
            items: _TeacherQuestionType.values
                .map(
                  (type) => DropdownMenuItem(
                    value: type,
                    child: Text(type.label),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                item.changeType(value, _markDirtySilently);
                _hasUnsavedChanges = true;
              });
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: item.questionController,
            minLines: 2,
            maxLines: 4,
            style: TextStyle(color: theme.colorScheme.onSurface),
            decoration: const InputDecoration(
              labelText: 'نص السؤال',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => _markDirtySilently(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: item.explanationController,
            minLines: 1,
            maxLines: 3,
            style: TextStyle(color: theme.colorScheme.onSurface),
            decoration: const InputDecoration(
              labelText: 'شرح الإجابة (اختياري)',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => _markDirtySilently(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: item.pointsController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(color: theme.colorScheme.onSurface),
                  decoration: const InputDecoration(
                    labelText: 'الدرجة',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => _markDirtySilently(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SwitchListTile.adaptive(
                  value: item.isActive,
                  onChanged: (value) {
                    setState(() {
                      item.isActive = value;
                      _hasUnsavedChanges = true;
                    });
                  },
                  title: const Text('نشط'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildQuestionTypeSection(item),
        ],
      ),
    );
  }

  Widget _buildQuestionTypeSection(_TeacherExerciseFormItem item) {
    switch (item.type) {
      case _TeacherQuestionType.multipleChoice:
        return _buildMultipleChoiceSection(item);
      case _TeacherQuestionType.trueFalse:
        return _buildTrueFalseSection(item);
      case _TeacherQuestionType.shortAnswer:
        return _buildShortAnswerSection(item);
    }
  }

  Widget _buildMultipleChoiceSection(_TeacherExerciseFormItem item) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'الخيارات',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  item.options.add(
                    _TeacherQuestionOptionItem.createNew(
                      onChanged: _markDirtySilently,
                    ),
                  );
                  _hasUnsavedChanges = true;
                });
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('إضافة خيار'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...List.generate(
          item.options.length,
          (index) {
            final option = item.options[index];

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Radio<int>(
                      value: index,
                      groupValue: item.correctOptionIndex,
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          for (int i = 0; i < item.options.length; i++) {
                            item.options[i].isCorrect = i == value;
                          }
                          _hasUnsavedChanges = true;
                        });
                      },
                    ),
                    Expanded(
                      child: TextField(
                        controller: option.textController,
                        style: TextStyle(color: theme.colorScheme.onSurface),
                        decoration: InputDecoration(
                          labelText: 'الخيار ${index + 1}',
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (_) => _markDirtySilently(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: item.options.length <= 2
                          ? null
                          : () {
                              setState(() {
                                item.options.removeAt(index).dispose();
                                if (item.options.every((e) => !e.isCorrect) &&
                                    item.options.isNotEmpty) {
                                  item.options.first.isCorrect = true;
                                }
                                _hasUnsavedChanges = true;
                              });
                            },
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTrueFalseSection(_TeacherExerciseFormItem item) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الإجابة الصحيحة',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ChoiceChip(
                label: const Text('صح'),
                selected: item.trueFalseCorrectIsTrue,
                onSelected: (_) {
                  setState(() {
                    item.trueFalseCorrectIsTrue = true;
                    _hasUnsavedChanges = true;
                  });
                },
              ),
              ChoiceChip(
                label: const Text('خطأ'),
                selected: !item.trueFalseCorrectIsTrue,
                onSelected: (_) {
                  setState(() {
                    item.trueFalseCorrectIsTrue = false;
                    _hasUnsavedChanges = true;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShortAnswerSection(_TeacherExerciseFormItem item) {
    final theme = Theme.of(context);

    return TextField(
      controller: item.answerController,
      minLines: 1,
      maxLines: 3,
      style: TextStyle(color: theme.colorScheme.onSurface),
      decoration: const InputDecoration(
        labelText: 'الإجابة النصية الصحيحة',
        border: OutlineInputBorder(),
      ),
      onChanged: (_) => _markDirtySilently(),
    );
  }

  Widget _buildBottomBar() {
    final theme = Theme.of(context);

    final isBusy =
        _isSaving || _isPublishing || _isArchiving || _isUnarchiving;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.55),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.16 : 0.10,
            ),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isBusy ? null : _saveExercises,
                  child: _isSaving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('حفظ كمسودة'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: isBusy ? null : _publishExercises,
                  child: _isPublishing
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('نشر'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: isBusy
                      ? null
                      : (_exerciseSetStatus == 'archived'
                          ? _unarchiveExercises
                          : _archiveExercises),
                  icon: (_isArchiving || _isUnarchiving)
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          _exerciseSetStatus == 'archived'
                              ? Icons.unarchive_outlined
                              : Icons.archive_outlined,
                        ),
                  label: Text(
                    _exerciseSetStatus == 'archived'
                        ? 'إلغاء الأرشفة'
                        : 'أرشفة المجموعة',
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: _exerciseSetStatus == 'archived'
                        ? theme.colorScheme.primary
                        : Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _humanizeStatus(String status) {
    switch (status.trim().toLowerCase()) {
      case 'published':
        return 'منشور';
      case 'archived':
        return 'مؤرشف';
      case 'needs_review':
        return 'يحتاج مراجعة';
      default:
        return 'مسودة';
    }
  }

  Color _statusColor(String status) {
    switch (status.trim().toLowerCase()) {
      case 'published':
        return Colors.green;
      case 'archived':
        return Colors.red;
      case 'needs_review':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }
}

enum _TeacherQuestionType {
  multipleChoice,
  trueFalse,
  shortAnswer;

  String get apiValue {
    switch (this) {
      case _TeacherQuestionType.multipleChoice:
        return 'multiple_choice';
      case _TeacherQuestionType.trueFalse:
        return 'true_false';
      case _TeacherQuestionType.shortAnswer:
        return 'short_answer';
    }
  }

  String get label {
    switch (this) {
      case _TeacherQuestionType.multipleChoice:
        return 'اختيار من متعدد';
      case _TeacherQuestionType.trueFalse:
        return 'صح / خطأ';
      case _TeacherQuestionType.shortAnswer:
        return 'إجابة قصيرة';
    }
  }

  static _TeacherQuestionType fromApi(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'true_false':
        return _TeacherQuestionType.trueFalse;
      case 'short_answer':
        return _TeacherQuestionType.shortAnswer;
      default:
        return _TeacherQuestionType.multipleChoice;
    }
  }
}

class _TeacherExerciseFormItem {
  final String? stableQuestionKey;
  final String origin;
  _TeacherQuestionType type;

  final TextEditingController questionController;
  final TextEditingController answerController;
  final TextEditingController explanationController;
  final TextEditingController pointsController;

  bool isActive;
  bool isDeleted;
  bool isArchived;
  bool trueFalseCorrectIsTrue;

  String? trueOptionStableKey;
  String? falseOptionStableKey;

  List<_TeacherQuestionOptionItem> options;

  _TeacherExerciseFormItem({
    required this.stableQuestionKey,
    required this.origin,
    required this.type,
    required this.questionController,
    required this.answerController,
    required this.explanationController,
    required this.pointsController,
    required this.isActive,
    required this.isDeleted,
    required this.isArchived,
    required this.trueFalseCorrectIsTrue,
    required this.trueOptionStableKey,
    required this.falseOptionStableKey,
    required this.options,
  });

  bool get hasStableKey => stableQuestionKey != null && stableQuestionKey!.isNotEmpty;

  factory _TeacherExerciseFormItem.createNew({
    required _TeacherQuestionType type,
    required VoidCallback onChanged,
  }) {
    final item = _TeacherExerciseFormItem(
      stableQuestionKey: null,
      origin: 'manual',
      type: type,
      questionController: TextEditingController(),
      answerController: TextEditingController(),
      explanationController: TextEditingController(),
      pointsController: TextEditingController(text: '1'),
      isActive: true,
      isDeleted: false,
      isArchived: false,
      trueFalseCorrectIsTrue: true,
      trueOptionStableKey: null,
      falseOptionStableKey: null,
      options: [],
    );

    if (type == _TeacherQuestionType.multipleChoice) {
      item.options = [
        _TeacherQuestionOptionItem.createNew(onChanged: onChanged),
        _TeacherQuestionOptionItem.createNew(onChanged: onChanged),
      ];
      item.options.first.isCorrect = true;
    }

    item._attachListeners(onChanged);
    return item;
  }

  factory _TeacherExerciseFormItem.fromApi(
    Map<String, dynamic> data,
    VoidCallback onChanged,
  ) {
    final type = _TeacherQuestionType.fromApi((data['type'] ?? '').toString());
    final optionsData = (data['options'] as List?)
            ?.whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList() ??
        <Map<String, dynamic>>[];

    bool tfCorrect = true;
    String? trueKey;
    String? falseKey;
    final parsedOptions = <_TeacherQuestionOptionItem>[];

    if (type == _TeacherQuestionType.multipleChoice) {
      for (final option in optionsData) {
        parsedOptions.add(
          _TeacherQuestionOptionItem.fromApi(option, onChanged),
        );
      }
      if (parsedOptions.isEmpty) {
        parsedOptions.addAll([
          _TeacherQuestionOptionItem.createNew(onChanged: onChanged),
          _TeacherQuestionOptionItem.createNew(onChanged: onChanged),
        ]);
        parsedOptions.first.isCorrect = true;
      }
    } else if (type == _TeacherQuestionType.trueFalse) {
      final trueOption = optionsData.cast<Map<String, dynamic>?>().firstWhere(
            (e) => (e?['option_text'] ?? '').toString().trim() == 'صح',
            orElse: () => null,
          );
      final falseOption = optionsData.cast<Map<String, dynamic>?>().firstWhere(
            (e) => (e?['option_text'] ?? '').toString().trim() == 'خطأ',
            orElse: () => null,
          );

      trueKey = trueOption?['stable_option_key']?.toString();
      falseKey = falseOption?['stable_option_key']?.toString();

      tfCorrect = (trueOption?['is_correct'] ?? true) == true;
    }

    final item = _TeacherExerciseFormItem(
      stableQuestionKey: data['stable_question_key']?.toString(),
      origin: (data['origin'] ?? 'manual').toString(),
      type: type,
      questionController: TextEditingController(
        text: (data['question_text'] ?? '').toString(),
      ),
      answerController: TextEditingController(
        text: (data['correct_text_answer'] ?? '').toString(),
      ),
      explanationController: TextEditingController(
        text: (data['explanation'] ?? '').toString(),
      ),
      pointsController: TextEditingController(
        text: ((data['points'] ?? 1)).toString(),
      ),
      isActive: (data['is_active'] ?? true) == true,
      isDeleted: (data['is_deleted'] ?? false) == true,
      isArchived: (data['is_archived'] ?? false) == true,
      trueFalseCorrectIsTrue: tfCorrect,
      trueOptionStableKey: trueKey,
      falseOptionStableKey: falseKey,
      options: parsedOptions,
    );

    item._attachListeners(onChanged);
    return item;
  }

  void _attachListeners(VoidCallback onChanged) {
    questionController.addListener(onChanged);
    answerController.addListener(onChanged);
    explanationController.addListener(onChanged);
    pointsController.addListener(onChanged);
  }

  double get pointsValue {
    final raw = double.tryParse(pointsController.text.trim());
    if (raw == null || raw <= 0) return 1;
    return raw;
  }

  int? get correctOptionIndex {
    final index = options.indexWhere((o) => o.isCorrect);
    return index == -1 ? null : index;
  }

  void changeType(_TeacherQuestionType newType, VoidCallback onChanged) {
    if (type == newType) return;

    type = newType;

    for (final option in options) {
      option.dispose();
    }
    options = [];

    trueOptionStableKey = null;
    falseOptionStableKey = null;
    trueFalseCorrectIsTrue = true;
    answerController.text = '';

    if (newType == _TeacherQuestionType.multipleChoice) {
      options = [
        _TeacherQuestionOptionItem.createNew(onChanged: onChanged),
        _TeacherQuestionOptionItem.createNew(onChanged: onChanged),
      ];
      options.first.isCorrect = true;
    }
  }

  void dispose() {
    questionController.dispose();
    answerController.dispose();
    explanationController.dispose();
    pointsController.dispose();
    for (final option in options) {
      option.dispose();
    }
  }
}

class _TeacherQuestionOptionItem {
  final String? stableOptionKey;
  final TextEditingController textController;
  bool isCorrect;

  _TeacherQuestionOptionItem({
    required this.stableOptionKey,
    required this.textController,
    required this.isCorrect,
  });

  factory _TeacherQuestionOptionItem.createNew({
    required VoidCallback onChanged,
  }) {
    final item = _TeacherQuestionOptionItem(
      stableOptionKey: null,
      textController: TextEditingController(),
      isCorrect: false,
    );
    item.textController.addListener(onChanged);
    return item;
  }

  factory _TeacherQuestionOptionItem.fromApi(
    Map<String, dynamic> data,
    VoidCallback onChanged,
  ) {
    final item = _TeacherQuestionOptionItem(
      stableOptionKey: data['stable_option_key']?.toString(),
      textController: TextEditingController(
        text: (data['option_text'] ?? '').toString(),
      ),
      isCorrect: (data['is_correct'] ?? false) == true,
    );
    item.textController.addListener(onChanged);
    return item;
  }

  void dispose() {
    textController.dispose();
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? EduTheme.darkSurface : theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String text;
  final Color color;

  const _StatusChip({
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _MiniFlagChip extends StatelessWidget {
  final String text;
  final Color color;

  const _MiniFlagChip({
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _EmptyExercisesCard extends StatelessWidget {
  final VoidCallback onAddPressed;

  const _EmptyExercisesCard({
    required this.onAddPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedColor =
        theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.72) ??
            EduTheme.textMuted;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.55),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.quiz_outlined,
            size: 42,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 10),
          Text(
            'لا توجد أسئلة حتى الآن',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'ابدأ بإضافة أول سؤال لهذه المجموعة.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: mutedColor,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: onAddPressed,
            icon: const Icon(Icons.add_rounded),
            label: const Text('إضافة سؤال'),
          ),
        ],
      ),
    );
  }
}