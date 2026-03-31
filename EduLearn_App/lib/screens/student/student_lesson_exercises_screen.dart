import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../services/lesson_exercise_service.dart';
import '../../theme.dart';

class StudentLessonExercisesScreen extends StatefulWidget {
  final int lessonId;
  final String academicId;
  final String lessonTitle;

  const StudentLessonExercisesScreen({
    super.key,
    required this.lessonId,
    required this.academicId,
    required this.lessonTitle,
  });

  @override
  State<StudentLessonExercisesScreen> createState() =>
      _StudentLessonExercisesScreenState();
}

class _StudentLessonExercisesScreenState
    extends State<StudentLessonExercisesScreen> {
  late final LessonExerciseService _exerciseService;

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isSubmitting = false;
  String? _error;

  Map<String, dynamic>? _exerciseSet;
  Map<String, dynamic>? _version;
  Map<String, dynamic>? _latestAttempt;
  Map<String, dynamic>? _syncSummary;

  List<Map<String, dynamic>> _questions = [];

  String _attemptStatus = '';
  bool _attemptLocked = false;
  bool _hasPendingChanges = false;

  double _score = 0;
  double _totalPoints = 0;
  int _correctCount = 0;
  int _wrongCount = 0;

  final Map<String, int> _selectedOptionsByStableKey = {};
  final Map<String, TextEditingController> _textAnswersByStableKey = {};
  final Map<String, Map<String, dynamic>> _answersByStableKey = {};

  bool _hasLocalChanges = false;

  @override
  void initState() {
    super.initState();
    _exerciseService = LessonExerciseService(baseUrl: baseUrl);
    _loadData();
  }

  @override
  void dispose() {
    for (final c in _textAnswersByStableKey.values) {
      c.dispose();
    }
    _exerciseService.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final bundle = await _exerciseService.fetchStudentCurrentExerciseBundle(
        lessonId: widget.lessonId,
        academicId: widget.academicId,
      );

      if (bundle == null) {
        _exerciseSet = null;
        _version = null;
        _latestAttempt = null;
        _syncSummary = null;
        _questions = [];
        _clearAnswerControllers();
        _selectedOptionsByStableKey.clear();
        _answersByStableKey.clear();
        _attemptStatus = '';
        _attemptLocked = false;
        _hasPendingChanges = false;
        _score = 0;
        _totalPoints = 0;
        _correctCount = 0;
        _wrongCount = 0;
        _hasLocalChanges = false;
        return;
      }

      _exerciseSet = LessonExerciseService.extractExerciseSet(bundle);
      _version = LessonExerciseService.extractVersion(bundle);
      _latestAttempt = LessonExerciseService.extractLatestAttempt(bundle);
      _syncSummary = LessonExerciseService.extractSyncSummary(bundle);

      final versionItems = ((_version?['items']) as List?)
              ?.whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          <Map<String, dynamic>>[];

      versionItems.sort((a, b) {
        return _readInt(a['position']).compareTo(_readInt(b['position']));
      });

      _questions = versionItems;

      _prepareAnswerControllers();
      _applyAttempt(_latestAttempt);

      _hasLocalChanges = false;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _clearAnswerControllers() {
    for (final c in _textAnswersByStableKey.values) {
      c.dispose();
    }
    _textAnswersByStableKey.clear();
  }

  void _prepareAnswerControllers() {
    final currentStableKeys = _questions
        .map((q) => (q['stable_question_key'] ?? '').toString())
        .where((k) => k.isNotEmpty)
        .toSet();

    final existingKeys = _textAnswersByStableKey.keys.toList();
    for (final key in existingKeys) {
      if (!currentStableKeys.contains(key)) {
        _textAnswersByStableKey[key]?.dispose();
        _textAnswersByStableKey.remove(key);
      }
    }

    for (final q in _questions) {
      final stableKey = (q['stable_question_key'] ?? '').toString();
      final type = (q['type'] ?? '').toString();

      if (stableKey.isEmpty) continue;

      if (type == 'short_answer' && !_textAnswersByStableKey.containsKey(stableKey)) {
        final controller = TextEditingController();
        controller.addListener(() {
          _hasLocalChanges = true;
        });
        _textAnswersByStableKey[stableKey] = controller;
      }
    }
  }

  void _applyAttempt(Map<String, dynamic>? attempt) {
    _selectedOptionsByStableKey.clear();
    _answersByStableKey.clear();

    for (final c in _textAnswersByStableKey.values) {
      c.text = '';
    }

    if (attempt == null) {
      _attemptStatus = '';
      _attemptLocked = false;
      _hasPendingChanges = false;
      _score = 0;
      _totalPoints = 0;
      _correctCount = 0;
      _wrongCount = 0;
      return;
    }

    _attemptStatus = (attempt['status'] ?? '').toString();
    _hasPendingChanges = (attempt['has_pending_changes'] ?? false) == true;

    _attemptLocked =
        (_attemptStatus == 'graded' || _attemptStatus == 'submitted') &&
            !_hasPendingChanges;

    _score = _readDouble(attempt['score'], fallback: 0);
    _totalPoints = _readDouble(attempt['total_points'], fallback: 0);
    _correctCount = _readInt(attempt['correct_count'], fallback: 0);
    _wrongCount = _readInt(attempt['wrong_count'], fallback: 0);

    final answers = (attempt['answers'] as List?)
            ?.whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList() ??
        <Map<String, dynamic>>[];

    for (final answer in answers) {
      final stableKey = (answer['stable_question_key'] ?? '').toString();
      if (stableKey.isEmpty) continue;

      _answersByStableKey[stableKey] = answer;

      final selectedOptionId = _readInt(answer['selected_option_id'], fallback: 0);
      if (selectedOptionId > 0) {
        _selectedOptionsByStableKey[stableKey] = selectedOptionId;
      }

      final answerText = (answer['answer_text'] ?? '').toString();
      if (_textAnswersByStableKey.containsKey(stableKey)) {
        _textAnswersByStableKey[stableKey]!.text = answerText;
      }
    }
  }

  int _readInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  double _readDouble(dynamic value, {double fallback = 0}) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  String _questionStableKey(Map<String, dynamic> question) {
    return (question['stable_question_key'] ?? '').toString();
  }

  String _questionType(Map<String, dynamic> question) {
    return (question['type'] ?? '').toString();
  }

  String _changeStatus(Map<String, dynamic> question) {
    return (question['change_status_from_previous'] ?? 'unchanged').toString();
  }

  bool _isQuestionActive(Map<String, dynamic> question) {
    return (question['is_active'] ?? true) == true;
  }

  Map<String, dynamic>? _answerForQuestion(Map<String, dynamic> question) {
    return _answersByStableKey[_questionStableKey(question)];
  }

  String _answerStateForQuestion(Map<String, dynamic> question) {
    final answer = _answerForQuestion(question);
    return (answer?['answer_state'] ?? 'active').toString();
  }

  bool _isQuestionDeleted(Map<String, dynamic> question) {
    return _changeStatus(question) == 'deleted' ||
        _answerStateForQuestion(question) == 'deleted_question' ||
        !_isQuestionActive(question);
  }

  bool _needsReanswer(Map<String, dynamic> question) {
    return _answerStateForQuestion(question) == 'needs_reanswer';
  }

  bool _isEditableQuestion(Map<String, dynamic> question) {
    if (_attemptLocked) return false;
    if (_isQuestionDeleted(question)) return false;
    return _isQuestionActive(question);
  }

  bool _hasAtLeastOneAnswer() {
    for (final question in _questions) {
      if (!_isEditableQuestion(question)) continue;

      final stableKey = _questionStableKey(question);
      final type = _questionType(question);

      if (type == 'multiple_choice' || type == 'true_false') {
        if (_selectedOptionsByStableKey.containsKey(stableKey)) {
          return true;
        }
      } else if (type == 'short_answer') {
        final text = _textAnswersByStableKey[stableKey]?.text.trim() ?? '';
        if (text.isNotEmpty) {
          return true;
        }
      }
    }
    return false;
  }

  List<Map<String, dynamic>> _buildAnswersPayload() {
    final payload = <Map<String, dynamic>>[];

    for (final question in _questions) {
      if (!_isEditableQuestion(question)) continue;

      final stableKey = _questionStableKey(question);
      final type = _questionType(question);

      if (stableKey.isEmpty) continue;

      if (type == 'multiple_choice' || type == 'true_false') {
        final selectedOptionId = _selectedOptionsByStableKey[stableKey];
        if (selectedOptionId != null) {
          payload.add(
            LessonExerciseService.buildStudentOptionAnswer(
              stableQuestionKey: stableKey,
              selectedOptionId: selectedOptionId,
            ),
          );
        }
      } else if (type == 'short_answer') {
        final text = _textAnswersByStableKey[stableKey]?.text.trim() ?? '';
        if (text.isNotEmpty) {
          payload.add(
            LessonExerciseService.buildStudentTextAnswer(
              stableQuestionKey: stableKey,
              answerText: text,
            ),
          );
        }
      }
    }

    return payload;
  }

  Future<void> _saveAnswers() async {
    if (_attemptLocked) return;

    if (!_hasAtLeastOneAnswer()) {
      _showSnack('أجب على سؤال واحد على الأقل قبل الحفظ.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final result = await _exerciseService.saveStudentExerciseAnswers(
        lessonId: widget.lessonId,
        academicId: widget.academicId,
        answers: _buildAnswersPayload(),
      );

      final attempt = result['attempt'];
      final syncSummary = result['sync_summary'];

      if (attempt is Map<String, dynamic>) {
        _latestAttempt = attempt;
        _applyAttempt(attempt);
      }

      if (syncSummary is Map<String, dynamic>) {
        _syncSummary = syncSummary;
      }

      _hasLocalChanges = false;
      _showSnack('تم حفظ الإجابات بنجاح.');
      setState(() {});
    } catch (e) {
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _submitAnswers() async {
    if (_attemptLocked) return;

    if (!_hasAtLeastOneAnswer()) {
      _showSnack('أجب على سؤال واحد على الأقل قبل الإرسال.');
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return AlertDialog(
          backgroundColor: theme.cardColor,
          title: const Text('إرسال الإجابات'),
          content: const Text(
            'سيتم تصحيح الإجابات الحالية. يمكنك إعادة الحل لاحقًا فقط إذا نشر الأستاذ تحديثات جديدة على التمارين.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('إرسال'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() => _isSubmitting = true);

    try {
      final result = await _exerciseService.submitStudentExerciseAnswers(
        lessonId: widget.lessonId,
        academicId: widget.academicId,
        answers: _buildAnswersPayload(),
      );

      final attempt = result['attempt'];
      final syncSummary = result['sync_summary'];

      if (attempt is Map<String, dynamic>) {
        _latestAttempt = attempt;
        _applyAttempt(attempt);
      }

      if (syncSummary is Map<String, dynamic>) {
        _syncSummary = syncSummary;
      }

      _hasLocalChanges = false;
      _showSnack('تم إرسال الإجابات وتصحيحها.');
      setState(() {});
    } catch (e) {
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (_attemptLocked || !_hasLocalChanges) return true;

    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return AlertDialog(
          backgroundColor: theme.cardColor,
          title: const Text('إجابات غير محفوظة'),
          content: const Text(
            'لديك إجابات غير محفوظة. هل تريد الخروج من الصفحة؟',
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

    return leave ?? false;
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

  Color _statusColor() {
    if (_attemptLocked) return Colors.green;
    if (_attemptStatus == 'in_progress') return Colors.orange;
    return Colors.blue;
  }

  String _statusLabel() {
    if (_attemptLocked) return 'تم التصحيح';
    if (_attemptStatus == 'in_progress') return 'قيد الحل';
    return 'غير مرسل';
  }

  String _changeLabel(String changeStatus) {
    switch (changeStatus) {
      case 'new':
        return 'جديد';
      case 'updated':
        return 'تم التعديل';
      case 'restored':
        return 'تمت الاستعادة';
      case 'deleted':
        return 'محذوف';
      default:
        return 'ثابت';
    }
  }

  Color _changeColor(String changeStatus) {
    switch (changeStatus) {
      case 'new':
        return Colors.blue;
      case 'updated':
        return Colors.orange;
      case 'restored':
        return Colors.purple;
      case 'deleted':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  bool _isSelectedOptionForQuestion(
    String stableQuestionKey,
    Map<String, dynamic> option,
  ) {
    final selected = _selectedOptionsByStableKey[stableQuestionKey];
    final optionId = _readInt(option['id'], fallback: 0);
    return selected != null && selected == optionId;
  }

  bool _isCorrectOption(Map<String, dynamic> option) {
    return option['is_correct'] == true;
  }

  Color? _optionBackgroundColor(
    Map<String, dynamic> question,
    Map<String, dynamic> option,
    ThemeData theme,
  ) {
    final stableKey = _questionStableKey(question);

    if (!_attemptLocked) {
      return _isSelectedOptionForQuestion(stableKey, option)
          ? theme.colorScheme.primary.withValues(alpha: 0.08)
          : theme.cardColor;
    }

    final isCorrect = _isCorrectOption(option);
    final isSelected = _isSelectedOptionForQuestion(stableKey, option);

    if (isCorrect) {
      return Colors.green.withValues(alpha: 0.12);
    }

    if (isSelected && !isCorrect) {
      return Colors.red.withValues(alpha: 0.12);
    }

    return theme.cardColor;
  }

  Color? _optionBorderColor(
    Map<String, dynamic> question,
    Map<String, dynamic> option,
    ThemeData theme,
  ) {
    final stableKey = _questionStableKey(question);

    if (!_attemptLocked) {
      return _isSelectedOptionForQuestion(stableKey, option)
          ? theme.colorScheme.primary
          : null;
    }

    final isCorrect = _isCorrectOption(option);
    final isSelected = _isSelectedOptionForQuestion(stableKey, option);

    if (isCorrect) return Colors.green;
    if (isSelected && !isCorrect) return Colors.red;

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleColor = theme.colorScheme.onSurface;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.scaffoldBackgroundColor,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: Text(
            'تمارين الدرس',
            style: TextStyle(
              color: titleColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: titleColor),
            onPressed: () async {
              final canLeave = await _onWillPop();
              if (canLeave && mounted) Navigator.of(context).pop();
            },
          ),
          actions: [
            IconButton(
              onPressed: _isLoading ? null : _loadData,
              icon: Icon(Icons.refresh_rounded, color: titleColor),
            ),
          ],
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
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'تعذر تحميل التمارين',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(
                color:
                    theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.72),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _loadData,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final theme = Theme.of(context);

    if (_exerciseSet == null || _version == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.quiz_outlined,
                  size: 42,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 10),
                Text(
                  'لا توجد تمارين منشورة حاليًا',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'لم يتم نشر تمارين لهذا الدرس بعد، أو أن المجموعة مؤرشفة حاليًا.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color:
                        theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.72),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopSummaryCard(),
            if (_syncSummary != null) ...[
              const SizedBox(height: 14),
              _buildSyncSummaryCard(),
            ],
            const SizedBox(height: 18),
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
    final color = _statusColor();

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
              alpha: theme.brightness == Brightness.dark ? 0.16 : 0.05,
            ),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.assignment_turned_in_outlined,
                  color: color,
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
                          text: _statusLabel(),
                          color: color,
                        ),
                        if (_attemptLocked)
                          _StatusChip(
                            text:
                                'النتيجة ${_score.toStringAsFixed(_score % 1 == 0 ? 0 : 1)} / ${_totalPoints.toStringAsFixed(_totalPoints % 1 == 0 ? 0 : 1)}',
                            color: Colors.green,
                          ),
                        if (_hasPendingChanges)
                          const _StatusChip(
                            text: 'توجد تغييرات جديدة',
                            color: Colors.orange,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_attemptLocked) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _ScoreTile(
                    label: 'صحيح',
                    value: _correctCount.toString(),
                    color: Colors.green,
                    icon: Icons.check_circle_outline_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ScoreTile(
                    label: 'خطأ',
                    value: _wrongCount.toString(),
                    color: Colors.red,
                    icon: Icons.highlight_off_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ScoreTile(
                    label: 'الإجمالي',
                    value: _totalPoints.toStringAsFixed(
                      _totalPoints % 1 == 0 ? 0 : 1,
                    ),
                    color: EduTheme.primary,
                    icon: Icons.star_border_rounded,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSyncSummaryCard() {
    final theme = Theme.of(context);

    final versionChanged = (_syncSummary?['version_changed'] ?? false) == true;
    final newCount = _readInt(_syncSummary?['new_count'], fallback: 0);
    final needsReanswerCount =
        _readInt(_syncSummary?['needs_reanswer_count'], fallback: 0);
    final deletedCount = _readInt(_syncSummary?['deleted_count'], fallback: 0);
    final carriedForwardCount =
        _readInt(_syncSummary?['carried_forward_count'], fallback: 0);

    if (!versionChanged &&
        newCount == 0 &&
        needsReanswerCount == 0 &&
        deletedCount == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'تم تحديث التمارين',
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (newCount > 0)
                _MiniCountChip(
                  label: '$newCount جديد',
                  color: Colors.blue,
                ),
              if (needsReanswerCount > 0)
                _MiniCountChip(
                  label: '$needsReanswerCount يحتاج إعادة حل',
                  color: Colors.orange,
                ),
              if (deletedCount > 0)
                _MiniCountChip(
                  label: '$deletedCount محذوف',
                  color: Colors.red,
                ),
              if (carriedForwardCount > 0)
                _MiniCountChip(
                  label: '$carriedForwardCount تم الاحتفاظ به',
                  color: Colors.green,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(int index, Map<String, dynamic> question) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final type = _questionType(question);
    final questionText = (question['question_text'] ?? '').toString();
    final explanation = (question['explanation'] ?? '').toString();
    final points = _readDouble(question['points'], fallback: 1);
    final stableKey = _questionStableKey(question);
    final answer = _answerForQuestion(question);
    final isCorrect = answer?['is_correct'] as bool?;
    final changeStatus = _changeStatus(question);
    final answerState = _answerStateForQuestion(question);
    final deleted = _isQuestionDeleted(question);
    final editable = _isEditableQuestion(question);

    final borderColor = deleted
        ? Colors.red.withValues(alpha: 0.45)
        : (_attemptLocked && isCorrect != null)
            ? (isCorrect ? Colors.green : Colors.red).withValues(alpha: 0.45)
            : theme.dividerColor.withValues(alpha: isDark ? 0.35 : 0.65);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.14 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor:
                    theme.colorScheme.primary.withValues(alpha: 0.12),
                foregroundColor: theme.colorScheme.primary,
                child: Text('${index + 1}'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  questionText,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _QuestionMetaChip(
                text: points % 1 == 0 ? '${points.toInt()} درجة' : '$points درجة',
                color: EduTheme.primary,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _QuestionMetaChip(
                text: _humanizeQuestionType(type),
                color: Colors.grey,
              ),
              if (changeStatus != 'unchanged')
                _QuestionMetaChip(
                  text: _changeLabel(changeStatus),
                  color: _changeColor(changeStatus),
                ),
              if (answerState == 'needs_reanswer')
                const _QuestionMetaChip(
                  text: 'أعد الحل',
                  color: Colors.orange,
                ),
              if (answerState == 'deleted_question' || deleted)
                const _QuestionMetaChip(
                  text: 'محذوف',
                  color: Colors.red,
                ),
              if (_attemptLocked && isCorrect != null && !deleted)
                _QuestionMetaChip(
                  text: isCorrect ? 'إجابة صحيحة' : 'إجابة خاطئة',
                  color: isCorrect ? Colors.green : Colors.red,
                ),
            ],
          ),
          if (explanation.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              explanation,
              style: TextStyle(
                fontSize: 12,
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
          ],
          const SizedBox(height: 14),
          if (deleted)
            _buildDeletedQuestionNotice(question)
          else if (type == 'multiple_choice' || type == 'true_false')
            _buildChoiceQuestion(question, editable, stableKey)
          else if (type == 'short_answer')
            _buildShortAnswerQuestion(question, editable, stableKey),
          if (_attemptLocked && !deleted) ...[
            const SizedBox(height: 12),
            _buildAnswerFeedback(question),
          ],
        ],
      ),
    );
  }

  Widget _buildDeletedQuestionNotice(Map<String, dynamic> question) {
    final theme = Theme.of(context);
    final changeStatus = _changeStatus(question);

    String text = 'تم حذف هذا السؤال من النسخة الحالية.';
    if (changeStatus == 'deleted') {
      text = 'هذا السؤال لم يعد مطلوبًا في النسخة الحالية، وهو ظاهر لك كمرجع فقط.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.red.withValues(alpha: 0.25),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildChoiceQuestion(
    Map<String, dynamic> question,
    bool editable,
    String stableKey,
  ) {
    final theme = Theme.of(context);

    final options = (question['options'] as List?)
            ?.whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList() ??
        <Map<String, dynamic>>[];

    options.sort((a, b) {
      return _readInt(a['position']).compareTo(_readInt(b['position']));
    });

    return Column(
      children: options.map((option) {
        final optionText = (option['option_text'] ?? '').toString();
        final selected = _isSelectedOptionForQuestion(stableKey, option);

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: InkWell(
            onTap: !editable
                ? null
                : () {
                    setState(() {
                      _selectedOptionsByStableKey[stableKey] =
                          _readInt(option['id'], fallback: 0);
                      _hasLocalChanges = true;
                    });
                  },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: _optionBackgroundColor(question, option, theme),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _optionBorderColor(question, option, theme) ??
                      theme.dividerColor.withValues(alpha: 0.35),
                  width: selected || _attemptLocked ? 1.3 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    selected
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    color: selected
                        ? EduTheme.primary
                        : theme.textTheme.bodySmall?.color,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      optionText,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                  if (_attemptLocked && _isCorrectOption(option))
                    const Icon(Icons.check_circle_rounded, color: Colors.green),
                  if (_attemptLocked &&
                      selected &&
                      !_isCorrectOption(option))
                    const Icon(Icons.cancel_rounded, color: Colors.red),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildShortAnswerQuestion(
    Map<String, dynamic> question,
    bool editable,
    String stableKey,
  ) {
    final controller = _textAnswersByStableKey[stableKey]!;
    final theme = Theme.of(context);

    return TextField(
      controller: controller,
      readOnly: !editable,
      minLines: 2,
      maxLines: 4,
      decoration: InputDecoration(
        labelText: 'اكتب إجابتك',
        border: const OutlineInputBorder(),
        filled: !editable,
        fillColor: !editable ? theme.scaffoldBackgroundColor : null,
      ),
      onChanged: (_) {
        _hasLocalChanges = true;
      },
    );
  }

  Widget _buildAnswerFeedback(Map<String, dynamic> question) {
    final theme = Theme.of(context);
    final answer = _answerForQuestion(question);
    final isCorrect = answer?['is_correct'] as bool?;
    final awardedPoints = _readDouble(answer?['awarded_points'], fallback: 0);
    final feedbackSnapshot = answer?['feedback_snapshot'];
    final correctTextAnswer =
        (feedbackSnapshot is Map ? feedbackSnapshot['correct_text_answer'] : null)
                ?.toString() ??
            (question['correct_text_answer'] ?? '').toString();

    final color = isCorrect == true ? Colors.green : Colors.red;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: 0.30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCorrect == true
                    ? Icons.check_circle_rounded
                    : Icons.cancel_rounded,
                color: color,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isCorrect == true ? 'إجابة صحيحة' : 'إجابة خاطئة',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                awardedPoints % 1 == 0
                    ? '${awardedPoints.toInt()} درجة'
                    : '$awardedPoints درجة',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          if (_questionType(question) == 'short_answer' &&
              correctTextAnswer.trim().isNotEmpty &&
              isCorrect == false) ...[
            const SizedBox(height: 8),
            Text(
              'الإجابة الصحيحة: $correctTextAnswer',
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _humanizeQuestionType(String type) {
    switch (type) {
      case 'multiple_choice':
        return 'اختيار من متعدد';
      case 'true_false':
        return 'صح / خطأ';
      case 'short_answer':
        return 'إجابة قصيرة';
      default:
        return type;
    }
  }

  Widget _buildBottomBar() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(
            color: theme.dividerColor.withValues(alpha: isDark ? 0.35 : 0.65),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.10),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: _attemptLocked
          ? SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: const Text('تم تصحيح المحاولة'),
              ),
            )
          : Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: (_isSaving || _isSubmitting) ? null : _saveAnswers,
                    child: _isSaving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('حفظ الإجابات'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        (_isSaving || _isSubmitting) ? null : _submitAnswers,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('إرسال'),
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

class _ScoreTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _ScoreTile({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionMetaChip extends StatelessWidget {
  final String text;
  final Color color;

  const _QuestionMetaChip({
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
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

class _MiniCountChip extends StatelessWidget {
  final String label;
  final Color color;

  const _MiniCountChip({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}