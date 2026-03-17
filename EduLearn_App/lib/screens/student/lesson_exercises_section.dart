import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../services/student_service.dart';
import '../../services/exercise_local_store.dart';

class LessonExercisesSection extends StatefulWidget {
  final String academicId;
  final int lessonId;
  final Map<String, dynamic> exercisePack;
  final VoidCallback onCompleted;

  const LessonExercisesSection({
    Key? key,
    required this.academicId,
    required this.lessonId,
    required this.exercisePack,
    required this.onCompleted,
  }) : super(key: key);

  @override
  State<LessonExercisesSection> createState() => _LessonExercisesSectionState();
}

class _LessonExercisesSectionState extends State<LessonExercisesSection> {
  bool _isLoading = true;
  bool _isChecking = false;
  Map<String, dynamic> _savedAnswers = {};
  List<dynamic>? _results; // إذا لم تكن null معناه أن الطالب صحّح إجاباته

  late List<dynamic> _questions;

  @override
  void initState() {
    super.initState();
    _questions = widget.exercisePack['questions']?.cast<Map<String, dynamic>>() ?? [];
    _loadSavedAnswers();
  }

  Future<void> _loadSavedAnswers() async {
    final ans = await ExerciseLocalStore.getAllAnswers(widget.lessonId, widget.academicId);
    if (!mounted) return;
    setState(() {
      _savedAnswers = ans;
      _isLoading = false;
    });
  }

  Future<void> _saveAnswerLocally(int qId, Map<String, dynamic> val) async {
    setState(() {
      _savedAnswers[qId.toString()] = val;
    });

    await ExerciseLocalStore.saveAnswer(
      lessonId: widget.lessonId,
      academicId: widget.academicId,
      questionId: qId,
      optionId: val['option_id'],
      answerBool: val['answer_bool'],
      answerText: val['answer_text'],
    );
  }

  Future<void> _checkAnswers() async {
    if (_savedAnswers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please answer at least one question.')),
      );
      return;
    }

    setState(() => _isChecking = true);

    try {
      final answersList = _savedAnswers.values.map((v) => Map<String, dynamic>.from(v)).toList();

      final results = await StudentService.checkLessonExercises(
        academicId: widget.academicId,
        lessonId: widget.lessonId,
        answers: answersList,
      );

      if (!mounted) return;
      setState(() {
        _results = results;
        _isChecking = false;
      });

      widget.onCompleted();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isChecking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_questions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.assignment_turned_in_rounded, color: EduTheme.primaryDark),
              const SizedBox(width: 8),
              Text(
                'Lesson Exercises',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: EduTheme.primaryDark,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._questions.asMap().entries.map((entry) {
            final idx = entry.key;
            final q = entry.value;
            return _buildQuestionCard(idx, q);
          }).toList(),
          const SizedBox(height: 16),
          if (_results == null)
            ElevatedButton(
              onPressed: _isChecking ? null : _checkAnswers,
              style: ElevatedButton.styleFrom(
                backgroundColor: EduTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isChecking
                  ? const SizedBox(
                      height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Check Answers', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            )
          else
            _buildResultsSummary(),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(int index, Map<String, dynamic> q) {
    final qId = q['id'];
    final type = q['type'];
    final qText = q['question_text'];

    // الحصول على إجابة التلميذ
    final ansMap = _savedAnswers[qId.toString()];
    
    // الحصول على نتيجة التصحيح إن وجدت
    Map<String, dynamic>? resultObj;
    if (_results != null) {
      try {
        resultObj = _results!.firstWhere((r) => r['question_id'] == qId);
      } catch (_) {}
    }

    // تحديد اللون 
    Color borderColor = Colors.black12;
    if (resultObj != null) {
      if (resultObj['is_correct'] == true) {
        borderColor = Colors.green;
      } else if (resultObj['is_correct'] == false) {
        borderColor = Colors.red;
      } else {
        borderColor = EduTheme.primary; // للـ Text questions
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: resultObj != null ? 2 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Q${index + 1}. $qText',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 10),
          if (type == 'mcq') _buildMcq(qId, q['options'], ansMap, resultObj),
          if (type == 'true_false') _buildTrueFalse(qId, ansMap, resultObj),
          if (type == 'text') _buildTextQuestion(qId, ansMap, resultObj),
        ],
      ),
    );
  }

  Widget _buildMcq(int qId, List<dynamic>? options, Map<String, dynamic>? ansMap, Map<String, dynamic>? resultObj) {
    final ops = options?.cast<Map<String, dynamic>>() ?? [];
    return Column(
      children: ops.map((o) {
        final optionId = o['id'];
        final isSelected = ansMap != null && ansMap['option_id'] == optionId;
        
        bool showAsCorrect = false;
        bool showAsIncorrect = false;
        
        if (resultObj != null) {
          final correctOptionId = resultObj['correct_option_id'];
          if (optionId == correctOptionId) {
            showAsCorrect = true;
          } else if (isSelected && resultObj['is_correct'] == false) {
            showAsIncorrect = true;
          }
        }

        Color itemColor = Colors.transparent;
        if (showAsCorrect) {
          itemColor = Colors.green.withOpacity(0.1);
        } else if (showAsIncorrect) {
          itemColor = Colors.red.withOpacity(0.1);
        }

        return RadioListTile<int>(
          value: optionId,
          groupValue: ansMap != null ? ansMap['option_id'] : null,
          title: Text(
            o['text'] ?? '',
            style: TextStyle(
              color: showAsCorrect ? Colors.green : (showAsIncorrect ? Colors.red : Colors.black87),
              fontWeight: (showAsCorrect || isSelected) ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          fillColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
            if (showAsCorrect) return Colors.green;
            if (showAsIncorrect) return Colors.red;
            if (states.contains(WidgetState.selected)) {
              return EduTheme.primaryDark;
            }
            return Colors.grey;
          }),
          tileColor: itemColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          onChanged: _results != null
              ? null // لا يمكن التغيير بعد التصحيح
              : (val) {
                  _saveAnswerLocally(qId, {
                    'question_id': qId,
                    'option_id': val,
                  });
                },
        );
      }).toList(),
    );
  }

  Widget _buildTrueFalse(int qId, Map<String, dynamic>? ansMap, Map<String, dynamic>? resultObj) {
    final currentVal = ansMap?['answer_bool'];

    return Row(
      children: [
        Expanded(
          child: _tfButton(qId, true, 'True', currentVal == true, resultObj),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _tfButton(qId, false, 'False', currentVal == false, resultObj),
        ),
      ],
    );
  }

  Widget _tfButton(int qId, bool val, String label, bool isSelected, Map<String, dynamic>? resultObj) {
    bool showAsCorrect = false;
    bool showAsIncorrect = false;

    if (resultObj != null) {
      final correctBool = resultObj['correct_bool'];
      if (val == correctBool) {
         showAsCorrect = true;
      } else if (isSelected && resultObj['is_correct'] == false) {
         showAsIncorrect = true;
      }
    }

    Color bgColor = Colors.grey.shade100;
    Color borderColor = Colors.grey.shade300;
    Color textColor = Colors.black54;

    if (showAsCorrect) {
      bgColor = Colors.green.withOpacity(0.1);
      borderColor = Colors.green;
      textColor = Colors.green;
    } else if (showAsIncorrect) {
      bgColor = Colors.red.withOpacity(0.1);
      borderColor = Colors.red;
      textColor = Colors.red;
    } else if (isSelected) {
      bgColor = EduTheme.primary.withOpacity(0.1);
      borderColor = EduTheme.primary;
      textColor = EduTheme.primary;
    }

    return InkWell(
      onTap: _results != null
          ? null 
          : () {
              _saveAnswerLocally(qId, {
                'question_id': qId,
                'answer_bool': val,
              });
            },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
          ),
        ),
      ),
    );
  }

  Widget _buildTextQuestion(int qId, Map<String, dynamic>? ansMap, Map<String, dynamic>? resultObj) {
    return TextFormField(
      initialValue: ansMap?['answer_text'] ?? '',
      readOnly: _results != null,
      maxLines: 3,
      decoration: InputDecoration(
        hintText: 'Type your answer here...',
        border: const OutlineInputBorder(),
        fillColor: Colors.grey.shade50,
        filled: true,
      ),
      onChanged: (val) {
        // لا نحفظ مباشرة مع كل حرف إلا بعد توقف بسيط، لكن للتبسيط:
        _savedAnswers[qId.toString()] = {
          'question_id': qId,
          'answer_text': val,
        };
        ExerciseLocalStore.saveAnswer(
          lessonId: widget.lessonId,
          academicId: widget.academicId,
          questionId: qId,
          answerText: val,
        );
      },
    );
  }

  Widget _buildResultsSummary() {
    int mcqTfCount = 0;
    int correctCount = 0;

    for (var r in _results!) {
      if (r['is_correct'] != null) {
        mcqTfCount++;
        if (r['is_correct'] == true) {
          correctCount++;
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EduTheme.primaryDark.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EduTheme.primaryDark.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          const Text(
            'Results',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: EduTheme.primaryDark),
          ),
          const SizedBox(height: 8),
          if (mcqTfCount > 0)
            Text(
              'You got $correctCount out of $mcqTfCount correct!',
              style: const TextStyle(fontSize: 16),
            ),
          const SizedBox(height: 8),
          const Text(
            'Text answers have been saved locally.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () async {
              await ExerciseLocalStore.clearAnswers(widget.lessonId, widget.academicId);
              setState(() {
                _results = null;
                _savedAnswers.clear();
              });
            },
            child: const Text('Retry Exercises'),
          ),
        ],
      ),
    );
  }
}
