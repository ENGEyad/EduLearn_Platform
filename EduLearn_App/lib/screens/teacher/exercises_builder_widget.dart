import 'package:flutter/material.dart';
import '../../theme.dart';

class ExercisesBuilderWidget extends StatefulWidget {
  final List<Map<String, dynamic>> initialExercises;
  final ValueChanged<List<Map<String, dynamic>>> onChanged;

  const ExercisesBuilderWidget({
    Key? key,
    required this.initialExercises,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<ExercisesBuilderWidget> createState() => _ExercisesBuilderWidgetState();
}

class _ExercisesBuilderWidgetState extends State<ExercisesBuilderWidget> {
  late List<Map<String, dynamic>> _exercises;

  @override
  void initState() {
    super.initState();
    // عميق النسخ عشان ما تتأثر العناصر الأصلية مبكراً
    _exercises = List<Map<String, dynamic>>.from(widget.initialExercises.map((e) {
      final map = Map<String, dynamic>.from(e);
      if (map['options'] != null) {
        map['options'] = List<Map<String, dynamic>>.from(
            (map['options'] as List).map((o) => Map<String, dynamic>.from(o)));
      }
      return map;
    }));
  }

  void _notifyChanged() {
    // تحديث position لكل التمارين والخيارات
    for (int i = 0; i < _exercises.length; i++) {
      _exercises[i]['position'] = i + 1;
      if (_exercises[i]['type'] == 'mcq' && _exercises[i]['options'] != null) {
        final ops = _exercises[i]['options'] as List<Map<String, dynamic>>;
        for (int j = 0; j < ops.length; j++) {
          ops[j]['position'] = j + 1;
        }
      }
    }
    widget.onChanged(_exercises);
  }

  void _addQuestion(String type) {
    setState(() {
      final newQ = <String, dynamic>{
        'type': type,
        'question_text': '',
        'position': _exercises.length + 1,
      };

      if (type == 'mcq') {
        newQ['options'] = [
          {'text': '', 'is_correct': true, 'position': 1},
          {'text': '', 'is_correct': false, 'position': 2},
        ];
      } else if (type == 'true_false') {
        newQ['correct_bool'] = true;
      }

      _exercises.add(newQ);
      _notifyChanged();
    });
  }

  void _removeQuestion(int index) {
    setState(() {
      _exercises.removeAt(index);
      _notifyChanged();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Interactive Exercises',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Outfit',
                color: Colors.white,
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.add_circle, color: EduTheme.primary),
              color: Colors.white,
              onSelected: _addQuestion,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'mcq',
                  child: Text('Multiple Choice (MCQ)',
                      style: TextStyle(color: Colors.white)),
                ),
                const PopupMenuItem(
                  value: 'true_false',
                  child: Text('True / False',
                      style: TextStyle(color: Colors.white)),
                ),
                const PopupMenuItem(
                  value: 'text',
                  child: Text('Text Question',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_exercises.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Text(
                'No exercises added yet.\nPress + to add.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withOpacity(0.5)),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _exercises.length,
            separatorBuilder: (c, i) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final q = _exercises[index];
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: EduTheme.primary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            q['type'] == 'mcq'
                                ? 'MCQ'
                                : q['type'] == 'true_false'
                                    ? 'True/False'
                                    : 'Text',
                            style: const TextStyle(
                              color: EduTheme.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.delete,
                              color: Colors.redAccent, size: 20),
                          onPressed: () => _removeQuestion(index),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      initialValue: q['question_text'],
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Enter your question...',
                        hintStyle: TextStyle(
                            color: Colors.white.withOpacity(0.3)),
                        filled: true,
                        fillColor: Colors.black.withOpacity(0.3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (val) {
                        q['question_text'] = val;
                        _notifyChanged();
                      },
                    ),
                    const SizedBox(height: 12),
                    if (q['type'] == 'mcq') _buildMcqOptions(index, q),
                    if (q['type'] == 'true_false') _buildTrueFalseOptions(index, q),
                    if (q['type'] == 'text')
                      Text(
                        'Students will answer with open text.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildMcqOptions(int qIndex, Map<String, dynamic> q) {
    if (q['options'] == null) {
      q['options'] = <Map<String, dynamic>>[];
    }
    final List<Map<String, dynamic>> options = q['options'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...options.asMap().entries.map((entry) {
          final oIdx = entry.key;
          final opt = entry.value;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Radio<int>(
                  value: oIdx,
                  groupValue: options.indexWhere((o) => o['is_correct'] == true),
                  activeColor: EduTheme.primary,
                  onChanged: (val) {
                    setState(() {
                      for (var o in options) {
                        o['is_correct'] = false;
                      }
                      options[val!]['is_correct'] = true;
                      _notifyChanged();
                    });
                  },
                ),
                Expanded(
                  child: TextFormField(
                    initialValue: opt['text']?.toString() ?? '',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Option ${oIdx + 1}',
                      hintStyle:
                          TextStyle(color: Colors.white.withOpacity(0.3)),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      filled: true,
                      fillColor: Colors.black.withOpacity(0.2),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (val) {
                      opt['text'] = val;
                      _notifyChanged();
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white38, size: 18),
                  onPressed: () {
                    setState(() {
                      options.removeAt(oIdx);
                      if (options.isNotEmpty &&
                          options.every((o) => o['is_correct'] == false)) {
                        options.first['is_correct'] = true;
                      }
                      _notifyChanged();
                    });
                  },
                )
              ],
            ),
          );
        }).toList(),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () {
              setState(() {
                options.add({
                  'text': '',
                  'is_correct': options.isEmpty,
                  'position': options.length + 1
                });
                _notifyChanged();
              });
            },
            icon: const Icon(Icons.add, size: 16, color: EduTheme.primary),
            label: const Text(
              'Add Option',
              style: TextStyle(color: EduTheme.primary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrueFalseOptions(int qIndex, Map<String, dynamic> q) {
    final correctBool = q['correct_bool'] ?? true;
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () {
              setState(() {
                q['correct_bool'] = true;
                _notifyChanged();
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: correctBool ? Colors.green.withOpacity(0.2) : Colors.black26,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: correctBool ? Colors.green : Colors.white10,
                ),
              ),
              child: Center(
                child: Text(
                  'True',
                  style: TextStyle(
                    color: correctBool ? Colors.green : Colors.white54,
                    fontWeight: correctBool ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: InkWell(
            onTap: () {
              setState(() {
                q['correct_bool'] = false;
                _notifyChanged();
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: !correctBool ? Colors.red.withOpacity(0.2) : Colors.black26,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: !correctBool ? Colors.red : Colors.white10,
                ),
              ),
              child: Center(
                child: Text(
                  'False',
                  style: TextStyle(
                    color: !correctBool ? Colors.red : Colors.white54,
                    fontWeight: !correctBool ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
