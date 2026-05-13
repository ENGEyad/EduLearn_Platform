import 'package:flutter/material.dart';

import '../../../services/api_service.dart';
import '../../../theme.dart';
import '../../../l10n/core/app_localizations.dart';
import '../../../l10n/getters/student/student_lesson_exercises_l10n.dart';

part 'student_lesson_exercises_widgets.dart';

class StudentLessonExercisesScreen extends StatefulWidget {
  final int lessonId;
  final String academicId; // kept only to pass to parent (will be removed later)
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
    extends State<StudentLessonExercisesScreen> with WidgetsBindingObserver {
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

  final Stopwatch _exerciseStopwatch = Stopwatch();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // ✅ removed baseUrl
    _exerciseService = LessonExerciseService();
    _exerciseStopwatch.start();
    _loadData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _exerciseStopwatch.stop();
    for (final controller in _textAnswersByStableKey.values) {
      controller.dispose();
    }
    // ✅ _exerciseService.dispose() removed (service no longer needs disposal)
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_attemptLocked) return;

    if (state == AppLifecycleState.resumed) {
      if (!_exerciseStopwatch.isRunning) {
        _exerciseStopwatch.start();
      }
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (_exerciseStopwatch.isRunning) {
        _exerciseStopwatch.stop();
      }
      _saveExerciseTimeSilently();
    }
  }

  int _consumeElapsedExerciseSeconds({bool restart = true}) {
    final seconds = _exerciseStopwatch.elapsed.inSeconds;
    _exerciseStopwatch.reset();
    if (restart && !_attemptLocked && !_exerciseStopwatch.isRunning) {
      _exerciseStopwatch.start();
    }
    return seconds;
  }

  Future<void> _saveExerciseTimeSilently() async {
    if (_attemptLocked) return;

    final elapsedSeconds = _consumeElapsedExerciseSeconds(restart: false);
    if (elapsedSeconds <= 0) return;

    try {
      // ✅ removed academicId
      await _exerciseService.saveStudentExerciseAnswers(
        lessonId: widget.lessonId,
        answers: const [],
        timeSpentSeconds: elapsedSeconds,
      );
    } catch (_) {}
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // ✅ removed academicId
      final bundle = await _exerciseService.fetchStudentCurrentExerciseBundle(
        lessonId: widget.lessonId,
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

        if (mounted) {
          setState(() {});
        }
        return;
      }

      _exerciseSet = LessonExerciseService.extractExerciseSet(bundle);
      _version = LessonExerciseService.extractVersion(bundle);
      _latestAttempt = LessonExerciseService.extractLatestAttempt(bundle);
      _syncSummary = LessonExerciseService.extractSyncSummary(bundle);

      final versionItems = LessonExerciseService.extractVersionItems(bundle)
          .where((q) => !LessonExerciseService.isQuestionDeleted(q))
          .toList();

      versionItems.sort((a, b) {
        return LessonExerciseService.readInt(a['position']).compareTo(
          LessonExerciseService.readInt(b['position']),
        );
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
    for (final controller in _textAnswersByStableKey.values) {
      controller.dispose();
    }
    _textAnswersByStableKey.clear();
  }

  void _prepareAnswerControllers() {
    final currentStableKeys = _questions
        .map(LessonExerciseService.questionStableKey)
        .where((key) => key.isNotEmpty)
        .toSet();

    final existingKeys = _textAnswersByStableKey.keys.toList();
    for (final key in existingKeys) {
      if (!currentStableKeys.contains(key)) {
        _textAnswersByStableKey[key]?.dispose();
        _textAnswersByStableKey.remove(key);
      }
    }

    for (final question in _questions) {
      final stableKey = LessonExerciseService.questionStableKey(question);
      final type = LessonExerciseService.questionType(question);

      if (stableKey.isEmpty) continue;

      if (type == 'short_answer' &&
          !_textAnswersByStableKey.containsKey(stableKey)) {
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

    for (final controller in _textAnswersByStableKey.values) {
      controller.text = '';
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

    _attemptStatus = LessonExerciseService.attemptStatus(attempt);
    _hasPendingChanges = LessonExerciseService.attemptHasPendingChanges(attempt);
    _attemptLocked = LessonExerciseService.attemptIsLocked(attempt);

    _score = LessonExerciseService.readDouble(attempt['score']);
    _totalPoints = LessonExerciseService.readDouble(attempt['total_points']);
    _correctCount = LessonExerciseService.readInt(attempt['correct_count']);
    _wrongCount = LessonExerciseService.readInt(attempt['wrong_count']);

    final answers = LessonExerciseService.extractAttemptAnswers(attempt);

    for (final answer in answers) {
      final stableKey = (answer['stable_question_key'] ?? '').toString();
      if (stableKey.isEmpty) continue;

      _answersByStableKey[stableKey] = answer;

      final selectedOptionId =
          LessonExerciseService.readInt(answer['selected_option_id']);
      if (selectedOptionId > 0) {
        _selectedOptionsByStableKey[stableKey] = selectedOptionId;
      }

      final answerText = (answer['answer_text'] ?? '').toString();
      if (_textAnswersByStableKey.containsKey(stableKey)) {
        _textAnswersByStableKey[stableKey]!.text = answerText;
      }
    }
  }

  Map<String, dynamic>? _answerForQuestion(Map<String, dynamic> question) {
    return _answersByStableKey[LessonExerciseService.questionStableKey(question)];
  }

  bool _isQuestionReadonly(Map<String, dynamic> question) {
    final answer = _answerForQuestion(question);
    return LessonExerciseService.isAnswerReadonly(answer);
  }

  bool _needsReanswer(Map<String, dynamic> question) {
    final answer = _answerForQuestion(question);
    return LessonExerciseService.isAnswerNeedsReanswer(answer);
  }

  bool _isEditableQuestion(Map<String, dynamic> question) {
    return LessonExerciseService.shouldQuestionBeEditable(
      question: question,
      attempt: _latestAttempt,
    );
  }

  bool _isSelectedOptionForQuestion(
    String stableQuestionKey,
    Map<String, dynamic> option,
  ) {
    final selected = _selectedOptionsByStableKey[stableQuestionKey];
    final optionId = LessonExerciseService.readInt(option['id']);
    return selected != null && selected == optionId;
  }

  bool _hasAtLeastOneAnswer() {
    for (final question in _questions) {
      if (!_isEditableQuestion(question)) continue;

      final stableKey = LessonExerciseService.questionStableKey(question);
      final type = LessonExerciseService.questionType(question);

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

  bool _hasUnansweredRequiredQuestions() {
    for (final question in _questions) {
      if (!_isEditableQuestion(question)) continue;

      final stableKey = LessonExerciseService.questionStableKey(question);
      final type = LessonExerciseService.questionType(question);

      if (stableKey.isEmpty) continue;

      if (type == 'multiple_choice' || type == 'true_false') {
        final selected = _selectedOptionsByStableKey[stableKey];
        if (selected == null || selected <= 0) {
          return true;
        }
      } else if (type == 'short_answer') {
        final text = _textAnswersByStableKey[stableKey]?.text.trim() ?? '';
        if (text.isEmpty) {
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

      final stableKey = LessonExerciseService.questionStableKey(question);
      final type = LessonExerciseService.questionType(question);

      if (stableKey.isEmpty) continue;

      if (type == 'multiple_choice' || type == 'true_false') {
        final selectedOptionId = _selectedOptionsByStableKey[stableKey];
        if (selectedOptionId != null && selectedOptionId > 0) {
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
      _showSnack(AppLocalizations.of(context).studentLessonExercisesAnswerOneBeforeSaving);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final elapsedSeconds = _consumeElapsedExerciseSeconds();
      // ✅ removed academicId
      final result = await _exerciseService.saveStudentExerciseAnswers(
        lessonId: widget.lessonId,
        answers: _buildAnswersPayload(),
        timeSpentSeconds: elapsedSeconds,
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
      _showSnack(AppLocalizations.of(context).studentLessonExercisesSavedSuccessfully);

      if (mounted) setState(() {});
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

    if (_hasUnansweredRequiredQuestions()) {
      _showSnack(
        AppLocalizations.of(context).studentLessonExercisesAnswerAllBeforeSubmit,
      );
      return;
    }

    if (!_hasAtLeastOneAnswer() &&
        LessonExerciseService.hasAnySubmittableQuestion(
          questions: _questions,
          attempt: _latestAttempt,
        )) {
      _showSnack(AppLocalizations.of(context).studentLessonExercisesNothingNewToSubmit);
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return AlertDialog(
          backgroundColor: theme.cardColor,
          title: Text(AppLocalizations.of(ctx).studentLessonExercisesSubmitAnswersTitle),
          content: Text(
            AppLocalizations.of(ctx).studentLessonExercisesSubmitAnswersMessage,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(AppLocalizations.of(ctx).studentLessonExercisesCancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(AppLocalizations.of(ctx).studentLessonExercisesSubmit),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() => _isSubmitting = true);

    try {
      final elapsedSeconds = _consumeElapsedExerciseSeconds();
      // ✅ removed academicId
      final result = await _exerciseService.submitStudentExerciseAnswers(
        lessonId: widget.lessonId,
        answers: _buildAnswersPayload(),
        timeSpentSeconds: elapsedSeconds,
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
      _showSnack(AppLocalizations.of(context).studentLessonExercisesSubmittedSuccessfully);

      if (mounted) setState(() {});
    } catch (e) {
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<bool> _handleBackNavigation() async {
    if (_attemptLocked) return true;

    if (!_hasLocalChanges) {
      await _saveExerciseTimeSilently();
      return true;
    }

    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return AlertDialog(
          backgroundColor: theme.cardColor,
          title: Text(AppLocalizations.of(ctx).studentLessonExercisesUnsavedChangesTitle),
          content: Text(
            AppLocalizations.of(ctx).studentLessonExercisesUnsavedChangesMessage,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(AppLocalizations.of(ctx).studentLessonExercisesStay),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(AppLocalizations.of(ctx).studentLessonExercisesLeave),
            ),
          ],
        );
      },
    );

    final shouldLeave = leave ?? false;
    if (shouldLeave) {
      await _saveExerciseTimeSilently();
    }

    return shouldLeave;
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
                blurRadius: 12,
                offset: const Offset(0, 5),
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
    if (_hasPendingChanges) return Colors.orange;
    if (_attemptStatus == 'in_progress') return Colors.blue;
    return Colors.grey;
  }

  String _statusLabel() {
    final l10n = AppLocalizations.of(context);
    if (_attemptLocked) return l10n.studentLessonExercisesChecked;
    if (_hasPendingChanges) return l10n.studentLessonExercisesActionRequired;
    if (_attemptStatus == 'in_progress') return l10n.studentLessonExercisesInProgress;
    return l10n.studentLessonExercisesNotSubmitted;
  }

  String _humanizeQuestionType(String type) {
    switch (type) {
      case 'multiple_choice':
        return AppLocalizations.of(context).studentLessonExercisesMultipleChoice;
      case 'true_false':
        return AppLocalizations.of(context).studentLessonExercisesTrueFalse;
      case 'short_answer':
        return AppLocalizations.of(context).studentLessonExercisesShortAnswer;
      default:
        return type;
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

  String _changeStatusLabel(String changeStatus) {
    final l10n = AppLocalizations.of(context);
    switch (changeStatus) {
      case 'new':
        return l10n.studentLessonExercisesNew;
      case 'updated':
        return l10n.studentLessonExercisesUpdated;
      case 'restored':
        return l10n.studentLessonExercisesRestored;
      case 'deleted':
        return l10n.studentLessonExercisesRemoved;
      default:
        return changeStatus;
    }
  }

  String? _correctOptionTextFromQuestion(Map<String, dynamic> question) {
    final options = LessonExerciseService.extractQuestionOptions(question);
    for (final option in options) {
      final bool isMarkedCorrect =
          (option['is_correct'] ?? false) == true ||
          (option['is_right'] ?? false) == true ||
          (option['correct'] ?? false) == true;
      if (isMarkedCorrect) {
        final value = (option['option_text'] ?? '').toString().trim();
        if (value.isNotEmpty) return value;
      }
    }
    return null;
  }

  String? _resolvedCorrectAnswerText(Map<String, dynamic> question) {
    final fromQuestion = _correctOptionTextFromQuestion(question);
    if (fromQuestion != null && fromQuestion.isNotEmpty) {
      return fromQuestion;
    }

    final answer = _answerForQuestion(question);
    final fromFeedback = LessonExerciseService.feedbackCorrectTextAnswer(answer);
    if (fromFeedback != null && fromFeedback.trim().isNotEmpty) {
      return fromFeedback.trim();
    }

    return null;
  }

  bool _isCorrectOption(Map<String, dynamic> question, Map<String, dynamic> option) {
    final correctText = _resolvedCorrectAnswerText(question);
    if (correctText == null || correctText.isEmpty) return false;

    final optionText = (option['option_text'] ?? '').toString().trim().toLowerCase();
    return optionText == correctText.trim().toLowerCase();
  }

  _QuestionVisualState _questionVisualState(Map<String, dynamic> question) {
    final answer = _answerForQuestion(question);
    final readonly = _isQuestionReadonly(question);
    final needsReanswer = _needsReanswer(question);
    final changeStatus = LessonExerciseService.questionChangeStatus(question);
    final isCorrect = answer?['is_correct'] as bool?;

    if (readonly && isCorrect != null) {
      return _QuestionVisualState(
        label: isCorrect
            ? AppLocalizations.of(context).studentLessonExercisesCorrect
            : AppLocalizations.of(context).studentLessonExercisesIncorrect,
        color: isCorrect ? Colors.green : Colors.red,
      );
    }

    if (needsReanswer) {
      return _QuestionVisualState(
        label: AppLocalizations.of(context).studentLessonExercisesNeedsAnswer,
        color: Colors.orange,
      );
    }

    if (changeStatus != 'unchanged') {
      return _QuestionVisualState(
        label: _changeStatusLabel(changeStatus),
        color: _changeColor(changeStatus),
      );
    }

    if (_isEditableQuestion(question)) {
      return _QuestionVisualState(
        label: _humanizeQuestionType(LessonExerciseService.questionType(question)),
        color: EduTheme.primary,
      );
    }

    return _QuestionVisualState(
      label: AppLocalizations.of(context).studentLessonExercisesLocked,
      color: Colors.blueGrey,
    );
  }

  Color? _optionBackgroundColor(
    Map<String, dynamic> question,
    Map<String, dynamic> option,
    ThemeData theme,
  ) {
    final stableKey = LessonExerciseService.questionStableKey(question);
    final answer = _answerForQuestion(question);
    final isReadonly = LessonExerciseService.isAnswerReadonly(answer);

    if (!isReadonly) {
      return _isSelectedOptionForQuestion(stableKey, option)
          ? theme.colorScheme.primary.withValues(alpha: 0.09)
          : theme.cardColor;
    }

    final isSelected = _isSelectedOptionForQuestion(stableKey, option);
    final isCorrect = (answer?['is_correct'] ?? false) == true;

    if (_isCorrectOption(question, option)) {
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
    final stableKey = LessonExerciseService.questionStableKey(question);
    final answer = _answerForQuestion(question);
    final isReadonly = LessonExerciseService.isAnswerReadonly(answer);

    if (!isReadonly) {
      return _isSelectedOptionForQuestion(stableKey, option)
          ? theme.colorScheme.primary
          : null;
    }

    final isSelected = _isSelectedOptionForQuestion(stableKey, option);
    final isCorrect = (answer?['is_correct'] ?? false) == true;

    if (_isCorrectOption(question, option)) {
      return Colors.green;
    }

    if (isSelected && !isCorrect) {
      return Colors.red;
    }

    return null;
  }

  Widget _buildError() {
    return StudentLessonExercisesErrorState(
      error: _error ?? '',
      onRetry: _loadData,
    );
  }

  Widget _buildContent() {
    if (_exerciseSet == null || _version == null) {
      return const StudentLessonExercisesNoPublishedState();
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 128),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StudentLessonExercisesTopSummaryCard(
              lessonTitle: widget.lessonTitle,
              statusColor: _statusColor(),
              statusLabel: _statusLabel(),
              attemptLocked: _attemptLocked,
              hasPendingChanges: _hasPendingChanges,
              score: _score,
              totalPoints: _totalPoints,
              correctCount: _correctCount,
              wrongCount: _wrongCount,
            ),
            if (_syncSummary != null) ...[
              const SizedBox(height: 14),
              StudentLessonExercisesSyncSummaryCard(
                syncSummary: _syncSummary!,
              ),
            ],
            const SizedBox(height: 18),
            if (_questions.isEmpty)
              const StudentLessonExercisesEmptyQuestionsCard()
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

  Widget _buildQuestionCard(int index, Map<String, dynamic> question) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final type = LessonExerciseService.questionType(question);
    final questionText = (question['question_text'] ?? '').toString();
    final points = LessonExerciseService.readDouble(question['points']);
    final stableKey = LessonExerciseService.questionStableKey(question);
    final answer = _answerForQuestion(question);
    final changeStatus = LessonExerciseService.questionChangeStatus(question);
    final answerState = LessonExerciseService.answerState(answer);
    final editable = _isEditableQuestion(question);
    final readonly = _isQuestionReadonly(question);
    final needsReanswer = _needsReanswer(question);
    final isCorrect = answer?['is_correct'] as bool?;
    final visualState = _questionVisualState(question);

    final borderColor = readonly && isCorrect != null
        ? (isCorrect ? Colors.green : Colors.red).withValues(alpha: 0.45)
        : needsReanswer
            ? Colors.orange.withValues(alpha: 0.50)
            : theme.dividerColor.withValues(alpha: isDark ? 0.35 : 0.65);

    return StudentLessonExerciseQuestionCard(
      index: index,
      questionText: questionText,
      points: points,
      questionTypeLabel: _humanizeQuestionType(type),
      statusLabel: visualState.label,
      statusColor: visualState.color,
      readonly: readonly,
      needsReanswer: needsReanswer,
      isCorrect: isCorrect,
      borderColor: borderColor,
      content: type == 'multiple_choice' || type == 'true_false'
          ? _buildChoiceQuestion(question, editable, stableKey)
          : _buildShortAnswerQuestion(question, editable, stableKey),
      feedback: LessonExerciseService.shouldShowQuestionFeedback(
        question: question,
        attempt: _latestAttempt,
      )
          ? Padding(
              padding: const EdgeInsets.only(top: 14),
              child: _buildAnswerFeedback(question),
            )
          : null,
    );
  }

  Widget _buildChoiceQuestion(
    Map<String, dynamic> question,
    bool editable,
    String stableKey,
  ) {
    final theme = Theme.of(context);

    final options = LessonExerciseService.extractQuestionOptions(question)
      ..sort((a, b) {
        return LessonExerciseService.readInt(a['position']).compareTo(
          LessonExerciseService.readInt(b['position']),
        );
      });

    return Column(
      children: options.map((option) {
        final optionText = (option['option_text'] ?? '').toString();
        final selected = _isSelectedOptionForQuestion(stableKey, option);

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: StudentLessonExerciseOptionTile(
            optionText: optionText,
            selected: selected,
            readOnly: _isQuestionReadonly(question),
            backgroundColor: _optionBackgroundColor(question, option, theme),
            borderColor: _optionBorderColor(question, option, theme) ??
                theme.dividerColor.withValues(alpha: 0.35),
            showCorrectIcon: _isQuestionReadonly(question) &&
                _isCorrectOption(question, option),
            showWrongIcon: _isQuestionReadonly(question) &&
                selected &&
                !((_answerForQuestion(question)?['is_correct'] ?? false) ==
                    true),
            onTap: !editable
                ? null
                : () {
                    setState(() {
                      _selectedOptionsByStableKey[stableKey] =
                          LessonExerciseService.readInt(option['id']);
                      _hasLocalChanges = true;
                    });
                  },
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

    return StudentLessonExerciseShortAnswerField(
      controller: controller,
      editable: editable,
      onChanged: (_) {
        _hasLocalChanges = true;
      },
    );
  }

  Widget _buildAnswerFeedback(Map<String, dynamic> question) {
    final answer = _answerForQuestion(question);
    final isCorrect = answer?['is_correct'] as bool?;
    final awardedPoints = LessonExerciseService.answerAwardedPoints(answer);
    final explanation = LessonExerciseService.feedbackExplanation(answer);
    final correctTextAnswer = _resolvedCorrectAnswerText(question);

    return StudentLessonExerciseFeedbackCard(
      isCorrect: isCorrect == true,
      awardedPoints: awardedPoints,
      correctTextAnswer: correctTextAnswer,
      explanation: explanation,
    );
  }

  Widget _buildBottomBar() {
    final canInteract = !_attemptLocked;
    final hasEditableQuestions = LessonExerciseService.hasAnySubmittableQuestion(
      questions: _questions,
      attempt: _latestAttempt,
    );

    return StudentLessonExercisesBottomBar(
      attemptLocked: _attemptLocked,
      isSaving: _isSaving,
      isSubmitting: _isSubmitting,
      canSaveOrSubmit:
          canInteract && !_isSaving && !_isSubmitting && hasEditableQuestions,
      onSave: _saveAnswers,
      onSubmit: _submitAnswers,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleColor = theme.colorScheme.onSurface;

    return PopScope(
      canPop: _attemptLocked || !_hasLocalChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final canLeave = await _handleBackNavigation();
        if (canLeave && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.scaffoldBackgroundColor,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: Text(
            AppLocalizations.of(context).studentLessonExercisesTitle,
            style: TextStyle(
              color: titleColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: titleColor),
            onPressed: () async {
              final canLeave = await _handleBackNavigation();
              if (canLeave && mounted) Navigator.of(context).pop();
            },
          ),
          actions: [
            IconButton(
              onPressed: _isLoading ? null : _loadData,
              icon: Icon(Icons.refresh_rounded, color: titleColor),
              tooltip: AppLocalizations.of(context).studentLessonExercisesRefresh,
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
}