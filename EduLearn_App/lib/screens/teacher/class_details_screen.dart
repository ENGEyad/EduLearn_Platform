import 'package:flutter/material.dart';
import '../../theme.dart';
import 'lesson_builder_screen.dart';

// ✅ بدل api_service.dart
import '../../services/lesson_service.dart';

class ClassDetailsScreen extends StatefulWidget {
  final String classTitle;
  final String grade;
  final String section;
  final String subjectName;
  final String classKey;
  final int studentsCount;
  final List<dynamic> students;

  // 🔹 بيانات الربط الحقيقية مع الـ API
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
  int _tabIndex = 0; // 0: Students, 1: Lessons, 2: Assignments

  // ======== حالة تبويب الدروس ========
  bool _isLoadingLessons = false;
  bool _modulesLoaded = false;

  // الوحدات (Modules = Units) = ClassModules في النظام الجديد
  List<_LessonModule> _modules = [];
  // دروس الوحدة الحالية
  List<_LessonSummary> _lessons = [];
  _LessonModule? _activeModule;
  bool _inModuleLessonsView = false;

  // وضع التحديد للدروس
  bool _isLessonSelectionMode = false;
  final Set<int> _selectedLessonIds = {};

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  // ======== تحميل الوحدات من الـ API ========
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
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLessons = false;
        });
      }
    }
  }

  // ======== تحميل دروس وحدة معيّنة ========
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
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLessons = false;
        });
      }
    }
  }

  // ======== فتح وحدة لعرض دروسها ========
  Future<void> _openModule(_LessonModule module) async {
    setState(() {
      _activeModule = module;
      _inModuleLessonsView = true;
    });
    await _loadLessonsForModule(module);
  }

  // ======== الرجوع من دروس الوحدة إلى قائمة الوحدات ========
  void _backToModules() {
    setState(() {
      _inModuleLessonsView = false;
      _activeModule = null;
      _lessons.clear();
      _isLessonSelectionMode = false;
      _selectedLessonIds.clear();
    });
  }

  // ======== زر الـ FAB في تبويب الدروس ========
  void _onLessonsFabPressed() {
    if (!_inModuleLessonsView) {
      _showAddModuleDialog();
    } else {
      _openLessonBuilderForNewLesson();
    }
  }

  // ======== Popup إضافة وحدة ========
  Future<void> _showAddModuleDialog() async {
    final TextEditingController controller = TextEditingController();
    bool canSave = false;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            return AlertDialog(
              title: const Text('إضافة وحدة'),
              content: TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'اسم الوحدة',
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
                  child: const Text('إلغاء'),
                ),
                TextButton(
                  onPressed: canSave ? () => Navigator.of(ctx).pop(true) : null,
                  child: const Text('حفظ'),
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

      await _openModule(newModule);
    } catch (e) {
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // ======== تعديل اسم وحدة أو حذفها (ضغط مطوّل) ========
  void _onModuleLongPress(_LessonModule module) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit_rounded),
                title: const Text('تعديل اسم الوحدة'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _showRenameModuleDialog(module);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever_rounded),
                title: const Text('حذف الوحدة مع جميع دروسها'),
                textColor: Colors.red,
                iconColor: Colors.red,
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
        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            return AlertDialog(
              title: const Text('تعديل اسم الوحدة'),
              content: TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'اسم الوحدة',
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
                  child: const Text('إلغاء'),
                ),
                TextButton(
                  onPressed: canSave ? () => Navigator.of(ctx).pop(true) : null,
                  child: const Text('حفظ'),
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
      _showSnack('تم تحديث اسم الوحدة.');
    } catch (e) {
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _confirmDeleteModule(_LessonModule module) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: Text(
            'هل تريد بالتأكيد حذف الوحدة "${module.title}" مع جميع الدروس التابعة لها؟',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('نعم'),
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

      _showSnack('تم حذف الوحدة بنجاح.');
    } catch (e) {
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // ======== فتح LessonBuilder لدرس جديد ========
  Future<void> _openLessonBuilderForNewLesson() async {
    if (_activeModule == null) {
      _showSnack('اختر وحدة أولاً أو أضف وحدة جديدة.');
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
    }
  }

  // ======== فتح LessonBuilder لتعديل درس موجود ========
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
    }
  }

  // ======== التحديد / الحذف للدروس ========
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
        return AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: Text(
            'هل تريد بالتأكيد حذف ${_selectedLessonIds.length} من الدروس المحددة؟',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('نعم'),
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

      _showSnack('تم حذف الدروس بنجاح.');
    } catch (e) {
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // ======== التعامل مع زر الرجوع (Back) في حالة التحديد للدروس ========
  Future<bool> _onWillPop() async {
    if (_tabIndex == 1 && _isLessonSelectionMode) {
      setState(() {
        _isLessonSelectionMode = false;
        _selectedLessonIds.clear();
      });
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: EduTheme.background,
        appBar: AppBar(
          title: const Text(
            'Class Details',
            style: TextStyle(
              color: EduTheme.primaryDark,
              fontWeight: FontWeight.w700,
            ),
          ),
          backgroundColor: EduTheme.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: EduTheme.primaryDark),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            if (_tabIndex == 1 && _isLessonSelectionMode)
              IconButton(
                icon: const Icon(Icons.delete_forever_rounded,
                    color: Colors.red),
                onPressed: _confirmDeleteSelectedLessons,
              )
            else
              const Padding(
                padding: EdgeInsets.only(right: 10),
                child: Icon(
                  Icons.more_vert_rounded,
                  color: EduTheme.primaryDark,
                ),
              ),
          ],
        ),
        floatingActionButton: _tabIndex == 1
            ? FloatingActionButton(
                backgroundColor: EduTheme.primary,
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: _buildTabContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.classTitle,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: EduTheme.primaryDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'A course covering key topics in ${widget.subjectName}, '
            'helping students build strong understanding and problem-solving skills.',
            style: const TextStyle(
              fontSize: 14,
              color: EduTheme.textMuted,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({required String title, required String value}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                color: EduTheme.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: EduTheme.primaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFE6ECF7),
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
    final bool selected = _tabIndex == index;
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
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              color: selected ? EduTheme.primaryDark : EduTheme.textMuted,
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
    final students = widget.students;

    if (students.isEmpty) {
      return Center(
        child: Text(
          'No students found for this class.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: EduTheme.textMuted,
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFFFFF2E4),
                  backgroundImage: (imageUrl != null && imageUrl.isNotEmpty)
                      ? NetworkImage(imageUrl)
                      : null,
                  child: (imageUrl == null || imageUrl.isEmpty)
                      ? Text(
                          initial,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: EduTheme.primaryDark,
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
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: EduTheme.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ID: $academicId',
                        style: const TextStyle(
                          fontSize: 13,
                          color: EduTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: EduTheme.textMuted,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 🔹 تبويب الدروس بعد التعديل
  Widget _buildLessonsTab() {
    if (_isLoadingLessons && !_modulesLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_inModuleLessonsView) {
      if (_modules.isEmpty) {
        return Center(
          child: Text(
            'لا توجد وحدات مضافة بعد.\nاستخدم زر + لإضافة أول وحدة.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: EduTheme.textMuted,
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F3FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.folder_open_rounded,
                        color: EduTheme.primaryDark,
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
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: EduTheme.primaryDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${module.lessonsCount} درس',
                            style: const TextStyle(
                              fontSize: 13,
                              color: EduTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: EduTheme.textMuted,
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
                onPressed: _backToModules,
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: EduTheme.primaryDark,
                  size: 18,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                _activeModule?.title ?? 'Unit',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: EduTheme.primaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Expanded(
            child: _isLoadingLessons
                ? const Center(child: CircularProgressIndicator())
                : _lessons.isEmpty
                    ? Center(
                        child: Text(
                          'لا توجد دروس بعد لهذه الوحدة.\nاستخدم زر + لإضافة أول درس.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: EduTheme.textMuted,
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
                                      ? const Color(0xFFE8F6FF)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: isSelected
                                        ? EduTheme.primary
                                        : Colors.transparent,
                                    width: 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.03),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
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
                                              ? EduTheme.primary
                                              : EduTheme.textMuted,
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
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 15,
                                              color: EduTheme.primaryDark,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            lesson.status == 'draft'
                                                ? 'مسودة'
                                                : 'منشور',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: lesson.status == 'draft'
                                                  ? Colors.orange
                                                  : EduTheme.textMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.chevron_right_rounded,
                                      color: EduTheme.textMuted,
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
    return Center(
      child: Text(
        'No assignments yet.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: EduTheme.textMuted,
            ),
      ),
    );
  }
}

// ======== Models داخل الملف (وحدات + دروس) ========

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
