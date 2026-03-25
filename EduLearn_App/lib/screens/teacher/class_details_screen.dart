import 'package:flutter/material.dart';
import '../../theme.dart';
import 'lesson_builder_screen.dart';
import '../../services/lesson_service.dart';

class ClassDetailsScreen extends StatefulWidget {
  final String classTitle;
  final String grade;
  final String section;
  final String subjectName;
  final String classKey;
  final int studentsCount;
  final List<dynamic> students;

  final String teacherCode;
  final int assignmentId;
  final int classSectionId;
  final int subjectId;

  const ClassDetailsScreen({
    super.key,
    required this.classTitle,
    required this.grade,
    required this.section,
    required this.subjectName,
    required this.classKey,
    required this.studentsCount,
    required this.students,
    required this.teacherCode,
    required this.assignmentId,
    required this.classSectionId,
    required this.subjectId,
  });

  @override
  State<ClassDetailsScreen> createState() => _ClassDetailsScreenState();
}

class _ClassDetailsScreenState extends State<ClassDetailsScreen> {
  int _tabIndex = 0;

  bool _isLoadingLessons = false;
  bool _modulesLoaded = false;

  List<_LessonModule> _modules = [];
  List<_LessonSummary> _lessons = [];
  _LessonModule? _activeModule;
  bool _inModuleLessonsView = false;

  bool _isLessonSelectionMode = false;
  final Set<int> _selectedLessonIds = {};

  void _showSnack(
    String msg, {
    bool isError = false,
    bool isSuccess = false,
    IconData? icon,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor = isError
        ? (isDark ? const Color(0xFF5A2630) : const Color(0xFFFFE5E8))
        : isSuccess
            ? (isDark ? const Color(0xFF1F3A2A) : const Color(0xFFEAF8EF))
            : (isDark ? theme.cardColor : Colors.white);

    final foregroundColor = isError
        ? (isDark ? const Color(0xFFFFC7CF) : const Color(0xFFB42318))
        : isSuccess
            ? (isDark ? const Color(0xFFB7F0C5) : const Color(0xFF067647))
            : theme.colorScheme.onSurface;

    final borderColor = isError
        ? (isDark ? const Color(0xFF7A3240) : const Color(0xFFF7B5BE))
        : isSuccess
            ? (isDark ? const Color(0xFF2B5138) : const Color(0xFFB7E3C5))
            : theme.dividerColor;

    final snackIcon = icon ??
        (isError
            ? Icons.error_outline_rounded
            : isSuccess
                ? Icons.check_circle_outline_rounded
                : Icons.info_outline_rounded);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          content: Container(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(snackIcon, color: foregroundColor, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    msg,
                    style: TextStyle(
                      color: foregroundColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }

  Future<void> _handleBackAction() async {
    if (_tabIndex == 1 && _isLessonSelectionMode) {
      setState(() {
        _isLessonSelectionMode = false;
        _selectedLessonIds.clear();
      });
      return;
    }

    if (_tabIndex == 1 && _inModuleLessonsView) {
      _backToModules();
      return;
    }

    if (mounted) {
      Navigator.of(context).maybePop();
    }
  }

  Future<bool> _onWillPop() async {
    if (_tabIndex == 1 && _isLessonSelectionMode) {
      setState(() {
        _isLessonSelectionMode = false;
        _selectedLessonIds.clear();
      });
      return false;
    }

    if (_tabIndex == 1 && _inModuleLessonsView) {
      _backToModules();
      return false;
    }

    return true;
  }

  Future<void> _loadModules() async {
    if (_isLoadingLessons) return;
    setState(() {
      _isLoadingLessons = true;
    });

    try {
      final modules = await LessonService.fetchLessonModules(
        teacherCode: widget.teacherCode,
        assignmentId: widget.assignmentId,
        classSectionId: widget.classSectionId,
        subjectId: widget.subjectId,
      );

      _modules = modules.map((m) {
        final rawCount = m['lessons_count'] ?? 0;
        final intCount =
            rawCount is int ? rawCount : int.tryParse('$rawCount') ?? 0;

        return _LessonModule(
          id: m['id'] as int,
          title: (m['title'] ?? '').toString(),
          lessonsCount: intCount,
        );
      }).toList();

      _modulesLoaded = true;
    } catch (e) {
      _showSnack(
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLessons = false;
        });
      }
    }
  }

  Future<void> _loadLessonsForModule(_LessonModule module) async {
    if (_isLoadingLessons) return;
    setState(() {
      _isLoadingLessons = true;
      _isLessonSelectionMode = false;
      _selectedLessonIds.clear();
    });

    try {
      final lessons = await LessonService.fetchLessonsForModule(
        moduleId: module.id,
      );

      _lessons = lessons
          .map((l) => _LessonSummary(
                id: l['id'] as int,
                title: (l['title'] ?? '').toString(),
                status: (l['status'] ?? 'published').toString(),
              ))
          .toList();

      final idx = _modules.indexWhere((m) => m.id == module.id);
      if (idx != -1) {
        _modules[idx].lessonsCount = _lessons.length;
      }
    } catch (e) {
      _showSnack(
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLessons = false;
        });
      }
    }
  }

  Future<void> _openModule(_LessonModule module) async {
    setState(() {
      _activeModule = module;
      _inModuleLessonsView = true;
    });
    await _loadLessonsForModule(module);
  }

  void _backToModules() {
    setState(() {
      _inModuleLessonsView = false;
      _activeModule = null;
      _lessons.clear();
      _isLessonSelectionMode = false;
      _selectedLessonIds.clear();
    });
  }

  void _onLessonsFabPressed() {
    if (!_inModuleLessonsView) {
      _showAddModuleDialog();
    } else {
      _openLessonBuilderForNewLesson();
    }
  }

  Future<void> _showAddModuleDialog() async {
    final TextEditingController controller = TextEditingController();
    bool canSave = false;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            return AlertDialog(
              backgroundColor:
                  theme.dialogTheme.backgroundColor ?? theme.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              title: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.create_new_folder_outlined,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Add Unit',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enter the name of the new unit to add it to this class.',
                    style: TextStyle(
                      color: theme.textTheme.bodySmall?.color,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Unit name',
                      hintText: 'Example: Unit 1',
                    ),
                    onChanged: (val) {
                      setStateDialog(() {
                        canSave = val.trim().isNotEmpty;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: canSave ? () => Navigator.of(ctx).pop(true) : null,
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != true) return;

    final title = controller.text.trim();
    if (title.isEmpty) return;

    try {
      final created = await LessonService.createLessonModule(
        teacherCode: widget.teacherCode,
        assignmentId: widget.assignmentId,
        classSectionId: widget.classSectionId,
        subjectId: widget.subjectId,
        title: title,
      );

      final newModule = _LessonModule(
        id: created['id'] as int,
        title: (created['title'] ?? title).toString(),
        lessonsCount: 0,
      );

      setState(() {
        _modules.add(newModule);
      });

      _showSnack(
        'Unit added successfully.',
        isSuccess: true,
        icon: Icons.task_alt_rounded,
      );

      await _openModule(newModule);
    } catch (e) {
      _showSnack(
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  void _onModuleLongPress(_LessonModule module) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        final bottomTheme = Theme.of(ctx);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  Icons.edit_rounded,
                  color: bottomTheme.colorScheme.onSurface,
                ),
                title: Text(
                  'Rename unit',
                  style: TextStyle(
                    color: bottomTheme.colorScheme.onSurface,
                  ),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _showRenameModuleDialog(module);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_forever_rounded,
                  color: Colors.red,
                ),
                title: const Text(
                  'Delete unit with all lessons',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _confirmDeleteModule(module);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showRenameModuleDialog(_LessonModule module) async {
    final controller = TextEditingController(text: module.title);
    bool canSave = module.title.trim().isNotEmpty;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            return AlertDialog(
              backgroundColor:
                  theme.dialogTheme.backgroundColor ?? theme.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text('Rename unit'),
              content: TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Unit name',
                ),
                onChanged: (val) {
                  setStateDialog(() {
                    canSave = val.trim().isNotEmpty;
                  });
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: canSave ? () => Navigator.of(ctx).pop(true) : null,
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != true) return;

    final newTitle = controller.text.trim();
    if (newTitle.isEmpty || newTitle == module.title) return;

    try {
      await LessonService.updateLessonModule(
        moduleId: module.id,
        title: newTitle,
      );

      setState(() {
        module.title = newTitle;
      });
      _showSnack('Unit name updated successfully.', isSuccess: true);
    } catch (e) {
      _showSnack(
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  Future<void> _confirmDeleteModule(_LessonModule module) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return AlertDialog(
          backgroundColor:
              theme.dialogTheme.backgroundColor ?? theme.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Confirm deletion'),
          content: Text(
            'Are you sure you want to delete the unit "${module.title}" with all its lessons?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await LessonService.deleteLessonModule(moduleId: module.id);

      setState(() {
        _modules.removeWhere((m) => m.id == module.id);
        if (_activeModule?.id == module.id) {
          _backToModules();
        }
      });

      _showSnack('Unit deleted successfully.', isSuccess: true);
    } catch (e) {
      _showSnack(
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  Future<void> _openLessonBuilderForNewLesson() async {
    if (_activeModule == null) {
      _showSnack('Please select a unit first or add a new unit.');
      return;
    }

    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => LessonBuilderScreen(
          classKey: widget.classKey,
          classTitle: widget.classTitle,
          studentsCount: widget.studentsCount,
          teacherCode: widget.teacherCode,
          assignmentId: widget.assignmentId,
          classSectionId: widget.classSectionId,
          subjectId: widget.subjectId,
          existingLessonId: null,
          moduleId: _activeModule!.id,
          moduleTitle: _activeModule!.title,
        ),
      ),
    );

    if (saved == true && mounted && _activeModule != null) {
      await _loadLessonsForModule(_activeModule!);
      _showSnack(
        'Lesson added successfully.',
        isSuccess: true,
        icon: Icons.menu_book_rounded,
      );
    }
  }

  Future<void> _openLessonBuilderForEdit(_LessonSummary lesson) async {
    if (_activeModule == null) return;

    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => LessonBuilderScreen(
          classKey: widget.classKey,
          classTitle: widget.classTitle,
          studentsCount: widget.studentsCount,
          teacherCode: widget.teacherCode,
          assignmentId: widget.assignmentId,
          classSectionId: widget.classSectionId,
          subjectId: widget.subjectId,
          existingLessonId: lesson.id,
          moduleId: _activeModule!.id,
          moduleTitle: _activeModule!.title,
        ),
      ),
    );

    if (saved == true && mounted && _activeModule != null) {
      await _loadLessonsForModule(_activeModule!);
      _showSnack(
        'Lesson updated successfully.',
        isSuccess: true,
        icon: Icons.edit_note_rounded,
      );
    }
  }

  void _toggleLessonSelection(_LessonSummary lesson) {
    setState(() {
      if (_selectedLessonIds.contains(lesson.id)) {
        _selectedLessonIds.remove(lesson.id);
      } else {
        _selectedLessonIds.add(lesson.id);
      }

      if (_selectedLessonIds.isEmpty) {
        _isLessonSelectionMode = false;
      }
    });
  }

  void _startLessonSelection(_LessonSummary lesson) {
    setState(() {
      _isLessonSelectionMode = true;
      _selectedLessonIds.clear();
      _selectedLessonIds.add(lesson.id);
    });
  }

  Future<void> _confirmDeleteSelectedLessons() async {
    if (_selectedLessonIds.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return AlertDialog(
          backgroundColor:
              theme.dialogTheme.backgroundColor ?? theme.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Confirm deletion'),
          content: Text(
            'Are you sure you want to delete ${_selectedLessonIds.length} selected lesson(s)?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await LessonService.deleteLessons(
        teacherCode: widget.teacherCode,
        lessonIds: _selectedLessonIds.toList(),
      );

      setState(() {
        _lessons.removeWhere((l) => _selectedLessonIds.contains(l.id));

        if (_activeModule != null) {
          final idx = _modules.indexWhere((m) => m.id == _activeModule!.id);
          if (idx != -1) {
            _modules[idx].lessonsCount = _lessons.length;
          }
        }

        _selectedLessonIds.clear();
        _isLessonSelectionMode = false;
      });

      _showSnack('Lessons deleted successfully.', isSuccess: true);
    } catch (e) {
      _showSnack(
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final titleColor = theme.colorScheme.onSurface;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            'Class Details',
            style: TextStyle(
              color: titleColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: titleColor,
            ),
            onPressed: _handleBackAction,
          ),
          actions: [
            if (_tabIndex == 1 && _isLessonSelectionMode)
              IconButton(
                icon: const Icon(
                  Icons.delete_forever_rounded,
                  color: Colors.red,
                ),
                onPressed: _confirmDeleteSelectedLessons,
              )
            else
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Icon(
                  Icons.more_vert_rounded,
                  color: titleColor,
                ),
              ),
          ],
        ),
        floatingActionButton: _tabIndex == 1
            ? FloatingActionButton(
                backgroundColor: theme.colorScheme.primary,
                onPressed: _onLessonsFabPressed,
                child: const Icon(Icons.add, color: Colors.white),
              )
            : null,
        body: Column(
          children: [
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: _buildHeaderCard(),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildStatCard(
                    title: 'Students',
                    value: widget.studentsCount.toString(),
                  ),
                  const SizedBox(width: 10),
                  _buildStatCard(
                    title: 'Avg. Grade',
                    value: '88%',
                  ),
                  const SizedBox(width: 10),
                  _buildStatCard(
                    title: 'Assignments Due',
                    value: '3',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildTabs(),
            const SizedBox(height: 4),
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: _buildTabContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: isDark ? 0.35 : 0.65),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.classTitle,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'A course covering key topics in ${widget.subjectName}, helping students build strong understanding and problem-solving skills.',
            style: TextStyle(
              fontSize: 14,
              color: theme.textTheme.bodySmall?.color ??
                  (isDark ? EduTheme.darkTextMuted : EduTheme.textMuted),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({required String title, required String value}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mutedColor = theme.textTheme.bodySmall?.color ??
        (isDark ? EduTheme.darkTextMuted : EduTheme.textMuted);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: theme.dividerColor.withValues(alpha: isDark ? 0.35 : 0.65),
          ),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: mutedColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF222E3E) : const Color(0xFFE6ECF7),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _buildTabButton(0, 'Students'),
          _buildTabButton(1, 'Lessons'),
          _buildTabButton(2, 'Assignments'),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String label) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bool selected = _tabIndex == index;

    final selectedColor = theme.cardColor;
    final unselectedColor = Colors.transparent;

    final selectedText = theme.colorScheme.onSurface;
    final unselectedText = theme.textTheme.bodySmall?.color ??
        (isDark ? EduTheme.darkTextMuted : EduTheme.textMuted);

    return Expanded(
      child: GestureDetector(
        onTap: () async {
          setState(() => _tabIndex = index);
          if (index == 1 && !_modulesLoaded) {
            await _loadModules();
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? selectedColor : unselectedColor,
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              color: selected ? selectedText : unselectedText,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    if (_tabIndex == 0) {
      return _buildStudentsTab();
    } else if (_tabIndex == 1) {
      return _buildLessonsTab();
    } else {
      return _buildAssignmentsTab();
    }
  }

  Widget _buildStudentsTab() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final students = widget.students;

    if (students.isEmpty) {
      return Center(
        child: Text(
          'No students found for this class.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color ??
                    (isDark ? EduTheme.darkTextMuted : EduTheme.textMuted),
              ),
        ),
      );
    }

    return ListView.builder(
      itemCount: students.length,
      itemBuilder: (context, index) {
        final s = students[index] as Map<String, dynamic>;

        final name = (s['full_name'] ?? '').toString();
        final academicId = (s['academic_id'] ?? '').toString();
        final imageUrl = s['image'] as String?;

        final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color:
                    theme.dividerColor.withValues(alpha: isDark ? 0.35 : 0.65),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: isDark
                      ? EduTheme.darkSurface
                      : const Color(0xFFFFF2E4),
                  backgroundImage: (imageUrl != null && imageUrl.isNotEmpty)
                      ? NetworkImage(imageUrl)
                      : null,
                  child: (imageUrl == null || imageUrl.isEmpty)
                      ? Text(
                          initial,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ID: $academicId',
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.textTheme.bodySmall?.color ??
                              (isDark
                                  ? EduTheme.darkTextMuted
                                  : EduTheme.textMuted),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: theme.textTheme.bodySmall?.color ??
                      (isDark ? EduTheme.darkTextMuted : EduTheme.textMuted),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLessonsTab() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mutedColor = theme.textTheme.bodySmall?.color ??
        (isDark ? EduTheme.darkTextMuted : EduTheme.textMuted);

    if (_isLoadingLessons && !_modulesLoaded) {
      return Center(
        child: CircularProgressIndicator(
          color: theme.colorScheme.primary,
        ),
      );
    }

    if (!_inModuleLessonsView) {
      if (_modules.isEmpty) {
        return Center(
          child: Text(
            'No units have been added yet.\nUse the + button to add your first unit.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: mutedColor,
                ),
          ),
        );
      }

      return ListView.builder(
        itemCount: _modules.length,
        itemBuilder: (context, index) {
          final module = _modules[index];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => _openModule(module),
              onLongPress: () => _onModuleLongPress(module),
              child: Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withValues(alpha: isDark ? 0.16 : 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: theme.dividerColor
                        .withValues(alpha: isDark ? 0.35 : 0.65),
                  ),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF223246)
                            : const Color(0xFFE8F3FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.folder_open_rounded,
                        color: theme.colorScheme.onSurface,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            module.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${module.lessonsCount} lesson(s)',
                            style: TextStyle(
                              fontSize: 13,
                              color: mutedColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: mutedColor,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: _handleBackAction,
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: theme.colorScheme.onSurface,
                  size: 18,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                _activeModule?.title ?? 'Unit',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Expanded(
            child: _isLoadingLessons
                ? Center(
                    child: CircularProgressIndicator(
                      color: theme.colorScheme.primary,
                    ),
                  )
                : _lessons.isEmpty
                    ? Center(
                        child: Text(
                          'No lessons have been added to this unit yet.\nUse the + button to add your first lesson.',
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: mutedColor,
                                  ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _lessons.length,
                        itemBuilder: (context, index) {
                          final lesson = _lessons[index];
                          final isSelected =
                              _selectedLessonIds.contains(lesson.id);

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: () {
                                if (_isLessonSelectionMode) {
                                  _toggleLessonSelection(lesson);
                                } else {
                                  _openLessonBuilderForEdit(lesson);
                                }
                              },
                              onLongPress: () {
                                if (_isLessonSelectionMode) {
                                  _toggleLessonSelection(lesson);
                                } else {
                                  _startLessonSelection(lesson);
                                }
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? theme.colorScheme.primary.withValues(
                                          alpha: isDark ? 0.16 : 0.08,
                                        )
                                      : theme.cardColor,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: isSelected
                                        ? theme.colorScheme.primary
                                        : theme.dividerColor.withValues(
                                            alpha: isDark ? 0.35 : 0.0,
                                          ),
                                    width: 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: isDark ? 0.16 : 0.03,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                child: Row(
                                  children: [
                                    if (_isLessonSelectionMode)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(right: 6),
                                        child: Icon(
                                          isSelected
                                              ? Icons.check_circle_rounded
                                              : Icons
                                                  .radio_button_unchecked_rounded,
                                          color: isSelected
                                              ? theme.colorScheme.primary
                                              : mutedColor,
                                          size: 20,
                                        ),
                                      ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            lesson.title,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 15,
                                              color:
                                                  theme.colorScheme.onSurface,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            lesson.status == 'draft'
                                                ? 'Draft'
                                                : 'Published',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: lesson.status == 'draft'
                                                  ? Colors.orange
                                                  : mutedColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      color: mutedColor,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      );
    }
  }

  Widget _buildAssignmentsTab() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Text(
        'No assignments yet.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodySmall?.color ??
                  (isDark ? EduTheme.darkTextMuted : EduTheme.textMuted),
            ),
      ),
    );
  }
}

class _LessonModule {
  final int id;
  String title;
  int lessonsCount;

  _LessonModule({
    required this.id,
    required this.title,
    required this.lessonsCount,
  });
}

class _LessonSummary {
  final int id;
  final String title;
  final String status;

  _LessonSummary({
    required this.id,
    required this.title,
    required this.status,
  });
}