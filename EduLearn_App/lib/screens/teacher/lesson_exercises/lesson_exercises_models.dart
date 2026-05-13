part of 'lesson_exercises_screen.dart';

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

  String shortLabel(AppLocalizations l10n) {
    switch (this) {
      case _TeacherQuestionType.multipleChoice:
        return l10n.lessonExercisesMultipleChoiceShort;
      case _TeacherQuestionType.trueFalse:
        return l10n.lessonExercisesTrueFalseShort;
      case _TeacherQuestionType.shortAnswer:
        return l10n.lessonExercisesShortAnswerShort;
    }
  }

  Color get pillColor {
    switch (this) {
      case _TeacherQuestionType.multipleChoice:
        return const Color(0xFF2563EB);
      case _TeacherQuestionType.trueFalse:
        return const Color(0xFFB45309);
      case _TeacherQuestionType.shortAnswer:
        return const Color(0xFF7C3AED);
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

  String serverStatus;
  String? localStatusOverride;
  bool isExpanded;

  String? trueOptionStableKey;
  String? falseOptionStableKey;

  List<_TeacherQuestionOptionItem> options;

  TextEditingController? editorQuestionController;
  TextEditingController? editorAnswerController;
  TextEditingController? editorExplanationController;
  TextEditingController? editorPointsController;
  bool editorIsActive = true;
  bool editorTrueFalseCorrectIsTrue = true;
  List<_TeacherQuestionOptionItem> editorOptions = [];

  final VoidCallback onEditorChanged;

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
    required this.onEditorChanged,
    this.serverStatus = 'draft',
    this.localStatusOverride,
    this.isExpanded = false,
  });

  bool get hasStableKey => stableQuestionKey != null && stableQuestionKey!.isNotEmpty;

  String previewTitle(AppLocalizations l10n) {
    final text = questionController.text.trim();
    if (text.isEmpty) {
      switch (type) {
        case _TeacherQuestionType.multipleChoice:
          return l10n.lessonExercisesNewMultipleChoiceQuestion;
        case _TeacherQuestionType.trueFalse:
          return l10n.lessonExercisesNewTrueFalseQuestion;
        case _TeacherQuestionType.shortAnswer:
          return l10n.lessonExercisesNewShortAnswerQuestion;
      }
    }
    return text;
  }

  bool get hasPendingEditorChanges {
    if (editorQuestionController == null) return false;
    if (editorQuestionController!.text != questionController.text) return true;
    if (editorAnswerController!.text != answerController.text) return true;
    if (editorExplanationController!.text != explanationController.text) return true;
    if (editorPointsController!.text != pointsController.text) return true;
    if (editorIsActive != isActive) return true;
    if (editorTrueFalseCorrectIsTrue != trueFalseCorrectIsTrue) return true;
    if (editorOptions.length != options.length) return true;

    for (int i = 0; i < editorOptions.length; i++) {
      final draft = editorOptions[i];
      final committed = options[i];
      if (draft.textController.text != committed.textController.text) return true;
      if (draft.isCorrect != committed.isCorrect) return true;
    }

    return false;
  }

  double get pointsValue {
    final raw = double.tryParse(pointsController.text.trim());
    if (raw == null || raw <= 0) return 1;
    return raw;
  }

  factory _TeacherExerciseFormItem.createNew({
    required _TeacherQuestionType type,
    required VoidCallback onEditorChanged,
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
      onEditorChanged: onEditorChanged,
    );

    if (type == _TeacherQuestionType.multipleChoice) {
      item.options = [
        _TeacherQuestionOptionItem.createNewCommitted(),
        _TeacherQuestionOptionItem.createNewCommitted(),
      ];
      item.options.first.isCorrect = true;
    }

    return item;
  }

  factory _TeacherExerciseFormItem.fromApi(
    Map<String, dynamic> data,
    VoidCallback onEditorChanged,
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
        parsedOptions.add(_TeacherQuestionOptionItem.fromApiCommitted(option));
      }
      if (parsedOptions.isEmpty) {
        parsedOptions.addAll([
          _TeacherQuestionOptionItem.createNewCommitted(),
          _TeacherQuestionOptionItem.createNewCommitted(),
        ]);
        parsedOptions.first.isCorrect = true;
      }
    } else if (type == _TeacherQuestionType.trueFalse) {
      final trueOption = optionsData.cast<Map<String, dynamic>?>().firstWhere(
            (e) => (e?['option_text'] ?? '').toString().trim().toLowerCase() == 'true' ||
                (e?['option_text'] ?? '').toString().trim() == 'صح',
            orElse: () => null,
          );
      final falseOption = optionsData.cast<Map<String, dynamic>?>().firstWhere(
            (e) => (e?['option_text'] ?? '').toString().trim().toLowerCase() == 'false' ||
                (e?['option_text'] ?? '').toString().trim() == 'خطأ',
            orElse: () => null,
          );
      trueKey = trueOption?['stable_option_key']?.toString();
      falseKey = falseOption?['stable_option_key']?.toString();
      tfCorrect = (trueOption?['is_correct'] ?? true) == true;
    }

    return _TeacherExerciseFormItem(
      stableQuestionKey: data['stable_question_key']?.toString(),
      origin: (data['origin'] ?? 'manual').toString(),
      type: type,
      questionController:
          TextEditingController(text: (data['question_text'] ?? '').toString()),
      answerController: TextEditingController(
        text: (data['correct_text_answer'] ?? '').toString(),
      ),
      explanationController: TextEditingController(
        text: (data['explanation'] ?? '').toString(),
      ),
      pointsController:
          TextEditingController(text: ((data['points'] ?? 1)).toString()),
      isActive: (data['is_active'] ?? true) == true,
      isDeleted: (data['is_deleted'] ?? false) == true,
      isArchived: (data['is_archived'] ?? false) == true,
      trueFalseCorrectIsTrue: tfCorrect,
      trueOptionStableKey: trueKey,
      falseOptionStableKey: falseKey,
      options: parsedOptions,
      onEditorChanged: onEditorChanged,
    );
  }

  void beginEditing() {
    disposeEditor();

    editorQuestionController = TextEditingController(text: questionController.text)
      ..addListener(onEditorChanged);
    editorAnswerController = TextEditingController(text: answerController.text)
      ..addListener(onEditorChanged);
    editorExplanationController =
        TextEditingController(text: explanationController.text)
          ..addListener(onEditorChanged);
    editorPointsController = TextEditingController(text: pointsController.text)
      ..addListener(onEditorChanged);

    editorIsActive = isActive;
    editorTrueFalseCorrectIsTrue = trueFalseCorrectIsTrue;
    editorOptions = options
        .map((option) => option.copyAsDraft(onEditorChanged))
        .toList(growable: true);
  }

  void saveEditing() {
    if (editorQuestionController == null) return;

    questionController.text = editorQuestionController!.text;
    answerController.text = editorAnswerController!.text;
    explanationController.text = editorExplanationController!.text;
    pointsController.text = editorPointsController!.text;
    isActive = editorIsActive;
    trueFalseCorrectIsTrue = editorTrueFalseCorrectIsTrue;

    for (final option in options) {
      option.dispose();
    }
    options = editorOptions
        .map((draft) => draft.copyAsCommitted())
        .toList(growable: true);

    disposeEditor();
    beginEditing();
  }

  void discardEditing() {
    beginEditing();
  }

  String? validateEditor(AppLocalizations l10n) {
    if (editorQuestionController == null) return null;

    if (editorQuestionController!.text.trim().isEmpty) {
      return l10n.lessonExercisesQuestionTextRequired;
    }

    final points = double.tryParse(editorPointsController!.text.trim());
    if (points == null || points <= 0) {
      return l10n.lessonExercisesPointsGreaterZero;
    }

    if (type == _TeacherQuestionType.multipleChoice) {
      if (editorOptions.length < 2) {
        return l10n.lessonExercisesMultipleChoiceTwoOptions;
      }

      int correctCount = 0;
      for (final option in editorOptions) {
        if (option.textController.text.trim().isEmpty) {
          return l10n.lessonExercisesEveryOptionText;
        }
        if (option.isCorrect) correctCount++;
      }

      if (correctCount != 1) {
        return l10n.lessonExercisesSelectOneCorrect;
      }
    }

    if (type == _TeacherQuestionType.shortAnswer &&
        editorAnswerController!.text.trim().isEmpty) {
      return l10n.lessonExercisesShortAnswerCorrectRequired;
    }

    return null;
  }

  void disposeEditor() {
    editorQuestionController?.dispose();
    editorAnswerController?.dispose();
    editorExplanationController?.dispose();
    editorPointsController?.dispose();
    for (final option in editorOptions) {
      option.dispose();
    }
    editorOptions = [];
    editorQuestionController = null;
    editorAnswerController = null;
    editorExplanationController = null;
    editorPointsController = null;
  }

  void dispose() {
    questionController.dispose();
    answerController.dispose();
    explanationController.dispose();
    pointsController.dispose();
    disposeEditor();
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

  factory _TeacherQuestionOptionItem.createNewCommitted() {
    return _TeacherQuestionOptionItem(
      stableOptionKey: null,
      textController: TextEditingController(),
      isCorrect: false,
    );
  }

  factory _TeacherQuestionOptionItem.createNewDraft() {
    return _TeacherQuestionOptionItem(
      stableOptionKey: null,
      textController: TextEditingController(),
      isCorrect: false,
    );
  }

  factory _TeacherQuestionOptionItem.fromApiCommitted(Map<String, dynamic> data) {
    return _TeacherQuestionOptionItem(
      stableOptionKey: data['stable_option_key']?.toString(),
      textController:
          TextEditingController(text: (data['option_text'] ?? '').toString()),
      isCorrect: (data['is_correct'] ?? false) == true,
    );
  }

  _TeacherQuestionOptionItem copyAsDraft(VoidCallback onChanged) {
    final item = _TeacherQuestionOptionItem(
      stableOptionKey: stableOptionKey,
      textController: TextEditingController(text: textController.text),
      isCorrect: isCorrect,
    );
    item.textController.addListener(onChanged);
    return item;
  }

  _TeacherQuestionOptionItem copyAsCommitted() {
    return _TeacherQuestionOptionItem(
      stableOptionKey: stableOptionKey,
      textController: TextEditingController(text: textController.text),
      isCorrect: isCorrect,
    );
  }

  void dispose() {
    textController.dispose();
  }
}
