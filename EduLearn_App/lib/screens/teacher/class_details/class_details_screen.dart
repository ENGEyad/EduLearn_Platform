import 'package:flutter/material.dart';

import '../../../l10n/core/app_localizations.dart';
import '../../../l10n/getters/teacher/class_details_l10n.dart';

import '../lesson_builder/lesson_builder_screen.dart';
import '../student_subject_progress/student_subject_progress_screen.dart';
import '../../../services/lesson_service.dart';
import '../../../services/teacher_data_service.dart';
import '../../../theme.dart';

part 'class_details_models.dart';
part 'class_details_widgets.dart';

class ClassDetailsScreen extends StatefulWidget {
  final String classTitle;
  final String grade;
  final String section;
  final String subjectName;
  final String classKey;
  final int studentsCount;
  final List<dynamic> students;

  final String teacherCode; // still needed for LessonBuilderScreen (temporary)
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

  bool _isLoadingStudents = false;
  bool _studentsLoaded = false;
  List<Map<String, dynamic>> _students = [];

  int get _lessonsCount => _modules.fold<int>(
        0,
        (total, module) => total + module.lessonsCount,
      );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _students = widget.students
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      await Future.wait([
        _loadStudents(showLoader: false),
        _loadModules(showLoader: false),
      ]);
    });
  }

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
                  color: Colors.black.withValues(alpha: isDark ? 0.14 : 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
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

  Future<void> _loadStudents({bool showLoader = true}) async {
    if (_isLoadingStudents) return;

    if (showLoader) {
      setState(() {
        _isLoadingStudents = true;
      });
    } else {
      _isLoadingStudents = true;
    }

    try {
      final fresh = await TeacherDataService.fetchAssignmentStudents(
        assignmentId: widget.assignmentId,
      );

      final parsed = fresh
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      _students = parsed;
      _studentsLoaded = true;
    } catch (e) {
      if (mounted) {
        _showSnack(
          e.toString().replaceFirst('Exception: ', ''),
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingStudents = false;
        });
      } else {
        _isLoadingStudents = false;
      }
    }
  }

  Future<void> _loadModules({bool showLoader = true}) async {
    if (_isLoadingLessons) return;

    if (showLoader) {
      setState(() {
        _isLoadingLessons = true;
      });
    } else {
      _isLoadingLessons = true;
    }

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
      if (mounted) {
        _showSnack(
          e.toString().replaceFirst('Exception: ', ''),
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLessons = false;
        });
      } else {
        _isLoadingLessons = false;
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
          .map(
            (l) => _LessonSummary(
              id: l['id'] as int,
              title: (l['title'] ?? '').toString(),
              status: (l['status'] ?? 'published').toString(),
            ),
          )
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
    final l10n = AppLocalizations.of(context);
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
                    l10n.classDetailsAddUnit,
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
                    l10n.classDetailsAddUnitDescription,
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
                    decoration: InputDecoration(
                      labelText: l10n.classDetailsUnitName,
                      hintText: l10n.classDetailsUnitNameHint,
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
                  child: Text(l10n.classDetailsCancel),
                ),
                ElevatedButton(
                  onPressed: canSave ? () => Navigator.of(ctx).pop(true) : null,
                  child: Text(l10n.classDetailsSave),
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
        _modulesLoaded = true;
      });

      _showSnack(
        l10n.classDetailsUnitAddedSuccess,
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
    final l10n = AppLocalizations.of(context);

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
                  l10n.classDetailsRenameUnit,
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
                title: Text(
                  l10n.classDetailsDeleteUnitWithLessons,
                  style: const TextStyle(color: Colors.red),
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
    final l10n = AppLocalizations.of(context);
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
              title: Text(l10n.classDetailsRenameUnit),
              content: TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: l10n.classDetailsUnitName,
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
                  child: Text(l10n.classDetailsCancel),
                ),
                ElevatedButton(
                  onPressed: canSave ? () => Navigator.of(ctx).pop(true) : null,
                  child: Text(l10n.classDetailsSave),
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

      _showSnack(l10n.classDetailsUnitNameUpdatedSuccess, isSuccess: true);
    } catch (e) {
      _showSnack(
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  Future<void> _confirmDeleteModule(_LessonModule module) async {
    final l10n = AppLocalizations.of(context);

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
          title: Text(l10n.classDetailsConfirmDeletion),
          content: Text(
            l10n.classDetailsDeleteUnitConfirmation(module.title),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.classDetailsCancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(
                l10n.classDetailsDelete,
                style: const TextStyle(color: Colors.red),
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

      _showSnack(l10n.classDetailsUnitDeletedSuccess, isSuccess: true);
    } catch (e) {
      _showSnack(
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  Future<void> _openLessonBuilderForNewLesson() async {
    final l10n = AppLocalizations.of(context);

    if (_activeModule == null) {
      _showSnack(l10n.classDetailsSelectUnitFirst);
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
        l10n.classDetailsLessonAddedSuccess,
        isSuccess: true,
        icon: Icons.menu_book_rounded,
      );
    }
  }

  Future<void> _openLessonBuilderForEdit(_LessonSummary lesson) async {
    final l10n = AppLocalizations.of(context);

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
        l10n.classDetailsLessonUpdatedSuccess,
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

    final l10n = AppLocalizations.of(context);

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
          title: Text(l10n.classDetailsConfirmDeletion),
          content: Text(
            l10n.classDetailsDeleteSelectedLessonsConfirmation(
              _selectedLessonIds.length,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.classDetailsCancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(
                l10n.classDetailsDelete,
                style: const TextStyle(color: Colors.red),
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

      _showSnack(l10n.classDetailsLessonsDeletedSuccess, isSuccess: true);
    } catch (e) {
      _showSnack(
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  Future<void> _onTabTapped(int index) async {
    if (_tabIndex == index) return;

    setState(() => _tabIndex = index);
    if (index == 1 && !_modulesLoaded) {
      await _loadModules();
    }
  }

  int? _readStudentId(Map<String, dynamic> student) {
    final value = student['id'] ?? student['student_id'];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  String? _readStudentImage(Map<String, dynamic> student) {
    final candidates = <dynamic>[
      student['image'],
      student['photo_url'],
      student['image_url'],
      student['avatar'],
      student['photo_path'],
    ];

    for (final value in candidates) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }

    return null;
  }

  void _openStudentSubjectProgress(Map<String, dynamic> student) {
  final l10n = AppLocalizations.of(context);

  final studentName = (student['full_name'] ?? student['name'] ?? '')
      .toString()
      .trim();
  final academicId = (student['academic_id'] ?? '').toString().trim();
  final studentId = _readStudentId(student);
  final studentImage = _readStudentImage(student);

  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => StudentSubjectProgressScreen(
        studentName: studentName.isEmpty
            ? l10n.classDetailsStudentFallback
            : studentName,
        studentImageUrl: studentImage,
        subjectName: widget.subjectName,
        grade: widget.grade,
        section: widget.section,
        teacherCode: widget.teacherCode,
        studentId: studentId,
        academicId: academicId.isEmpty ? null : academicId,
        subjectId: widget.subjectId,
        assignmentId: widget.assignmentId, // ✅ الإضافة الوحيدة
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final titleColor = theme.colorScheme.onSurface;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final canPop = await _onWillPop();
        if (!mounted) return;

        if (canPop) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            widget.subjectName,
            style: TextStyle(
              color: titleColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          backgroundColor: theme.scaffoldBackgroundColor,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
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
                  Icons.more_horiz_rounded,
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
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: _ClassDetailsHeaderCard(
                subjectName: widget.subjectName,
                grade: widget.grade,
                section: widget.section,
                classTitle: widget.classTitle,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _ClassDetailsStatCard(
                    title: l10n.classDetailsStudents,
                    value: (_studentsLoaded
                            ? _students.length
                            : widget.studentsCount)
                        .toString(),
                  ),
                  const SizedBox(width: 10),
                  _ClassDetailsStatCard(
                    title: l10n.classDetailsLessons,
                    value: _modulesLoaded ? _lessonsCount.toString() : '—',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _ClassDetailsTabs(
              tabIndex: _tabIndex,
              onTap: _onTabTapped,
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: child,
                    );
                  },
                  child: KeyedSubtree(
                    key: ValueKey('tab_$_tabIndex'),
                    child: _buildTabContent(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    if (_tabIndex == 0) {
      return _buildStudentsTab();
    } else {
      return _buildLessonsTab();
    }
  }

  Widget _buildStudentsTab() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final students = _students;

    if (_isLoadingStudents && !_studentsLoaded) {
      return Center(
        child: CircularProgressIndicator(
          color: theme.colorScheme.primary,
        ),
      );
    }

    if (students.isEmpty) {
      return Center(
        child: Text(
          l10n.classDetailsNoStudentsFound,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color ??
                    (isDark ? EduTheme.darkTextMuted : EduTheme.textMuted),
              ),
        ),
      );
    }

    return ListView.separated(
      key: const PageStorageKey('students_tab_list'),
      padding: const EdgeInsets.only(bottom: 20),
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      itemCount: students.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final s = students[index];
        return _StudentTile(
          student: s,
          onTap: () => _openStudentSubjectProgress(s),
        );
      },
    );
  }

  Widget _buildLessonsTab() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
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

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: !_inModuleLessonsView
          ? KeyedSubtree(
              key: const ValueKey('modules_view'),
              child: _modules.isEmpty
                  ? Center(
                      child: Text(
                        l10n.classDetailsNoUnits,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: mutedColor,
                            ),
                      ),
                    )
                  : ListView.separated(
                      key: const PageStorageKey('modules_list'),
                      padding: const EdgeInsets.only(bottom: 20),
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      itemCount: _modules.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final module = _modules[index];
                        return _ModuleTile(
                          module: module,
                          onTap: () => _openModule(module),
                          onLongPress: () => _onModuleLongPress(module),
                        );
                      },
                    ),
            )
          : KeyedSubtree(
              key: ValueKey('lessons_view_${_activeModule?.id ?? 0}'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _LessonsBreadcrumbHeader(
                    title: _activeModule?.title ??
                        l10n.classDetailsUnitFallback,
                    lessonsCount: _lessons.length,
                    onBack: _handleBackAction,
                  ),
                  const SizedBox(height: 8),
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
                                  l10n.classDetailsNoLessons,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: mutedColor,
                                      ),
                                ),
                              )
                            : ListView.separated(
                                key: PageStorageKey(
                                  'lessons_list_${_activeModule?.id ?? 0}',
                                ),
                                padding: const EdgeInsets.only(bottom: 20),
                                physics: const BouncingScrollPhysics(
                                  parent: AlwaysScrollableScrollPhysics(),
                                ),
                                itemCount: _lessons.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final lesson = _lessons[index];
                                  final isSelected =
                                      _selectedLessonIds.contains(lesson.id);

                                  return _LessonTile(
                                    lesson: lesson,
                                    isSelectionMode: _isLessonSelectionMode,
                                    isSelected: isSelected,
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
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),
    );
  }
}