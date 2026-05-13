import 'package:flutter/material.dart';
import '../../../theme.dart';
import '../../../services/student_service.dart';
import '../../../l10n/core/app_localizations.dart';
import '../../../l10n/getters/student/student_subject_detail_l10n.dart';
import '../student_lesson_viewer/student_lesson_viewer_screen.dart';

part 'student_subject_detail_models.dart';
part 'student_subject_detail_widgets.dart';

class StudentSubjectDetailScreen extends StatefulWidget {
  final int subjectId;
  final String academicId;

  final String subjectName;
  final String? teacherName;
  final String? teacherImage;

  const StudentSubjectDetailScreen({
    super.key,
    required this.subjectId,
    required this.academicId,
    required this.subjectName,
    this.teacherName,
    this.teacherImage,
  });

  @override
  State<StudentSubjectDetailScreen> createState() =>
      _StudentSubjectDetailScreenState();
}

class _StudentSubjectDetailScreenState extends State<StudentSubjectDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _isLoadingLessons = false;
  String? _lessonsError;

  bool _modulesLoaded = false;
  final List<_StudentLessonModule> _modules = [];
  bool _inModuleLessonsView = false;
  _StudentLessonModule? _activeModule;

  _StudentSubjectProgressSummary? _subjectProgress;
  String? _progressError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadLessons();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSubjectProgress() async {
    try {
      final data = await StudentService.fetchStudentSubjectProgress(
        subjectId: widget.subjectId,
      );

      if (!mounted) return;
      setState(() {
        _subjectProgress = _StudentSubjectProgressSummary.fromJson(data);
        _progressError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _progressError = e.toString().replaceFirst('Exception: ', '');
        _subjectProgress = null;
      });
    }
  }

  Future<void> _loadLessons() async {
    if (_isLoadingLessons) return;

    setState(() {
      _isLoadingLessons = true;
      _lessonsError = null;
      _modulesLoaded = false;
      _modules.clear();
      _inModuleLessonsView = false;
      _activeModule = null;
      _progressError = null;
    });

    await _loadSubjectProgress();

    try {
      final list = await StudentService.fetchStudentLessonsForSubject(
        subjectId: widget.subjectId,
      );

      final lessons = list.whereType<Map<String, dynamic>>().toList();

      if (lessons.isEmpty) {
        setState(() {
          _modulesLoaded = true;
        });
        return;
      }

      final Map<String, _StudentLessonModule> moduleMap = {};

      for (final raw in lessons) {
        final dynamic rawId = raw['id'];
        final int? id = (rawId is int)
            ? rawId
            : (rawId is String ? int.tryParse(rawId) : null);
        if (id == null) continue;

        final String title = (raw['title'] ?? '').toString();
        final String duration =
            (raw['duration_label'] ?? '').toString().trim();

        String status = (raw['status'] ?? 'not_started').toString();
        if (status != 'not_started' &&
            status != 'draft' &&
            status != 'completed') {
          status = 'not_started';
        }

        final dynamic rawModuleId = raw['class_module_id'] ?? raw['module_id'];
        final String moduleIdKey =
            rawModuleId == null ? 'default' : rawModuleId.toString();

        final String moduleTitle =
            (raw['module_title'] ?? raw['class_module_title'] ?? 'Lessons')
                .toString();

        if (!moduleMap.containsKey(moduleIdKey)) {
          moduleMap[moduleIdKey] = _StudentLessonModule(
            id: rawModuleId is int
                ? rawModuleId
                : int.tryParse(moduleIdKey) ?? -1,
            title: moduleTitle,
            lessons: [],
          );
        }

        moduleMap[moduleIdKey]!.lessons.add(
          _StudentLessonSummary(
            id: id,
            title: title,
            durationLabel: duration,
            status: status,
          ),
        );
      }

      final modules = moduleMap.values.toList();
      modules.sort((a, b) {
        final aIsDefault = a.id <= 0;
        final bIsDefault = b.id <= 0;
        if (aIsDefault != bIsDefault) return aIsDefault ? 1 : -1;
        return a.id.compareTo(b.id);
      });

      setState(() {
        _modules
          ..clear()
          ..addAll(modules);
        _modulesLoaded = true;
      });
    } catch (e) {
      setState(() {
        _lessonsError = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLessons = false;
          _modulesLoaded = true;
        });
      }
    }
  }

  IconData _iconForSubject(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('math') || lower.contains('algebra')) {
      return Icons.calculate_rounded;
    }
    if (lower.contains('history')) {
      return Icons.public_rounded;
    }
    if (lower.contains('chem')) {
      return Icons.biotech_rounded;
    }
    if (lower.contains('english')) {
      return Icons.menu_book_rounded;
    }
    return Icons.menu_book_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final IconData subjectIcon = _iconForSubject(widget.subjectName);
    final ThemeData theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    final Color pageBackground = theme.scaffoldBackgroundColor;
    final Color cardColor = theme.cardColor;
    final Color titleColor = theme.colorScheme.onSurface;
    final Color mutedColor =
        theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.72) ??
        (isDarkMode ? EduTheme.darkTextMuted : EduTheme.textMuted);
    final Color softBoxColor =
        isDarkMode ? EduTheme.darkSurfaceContainer : EduTheme.softPrimaryBackground;
    final Color progressBackground = isDarkMode
        ? EduTheme.darkSurfaceContainerHigh
        : EduTheme.inputBorder.withValues(alpha: 0.85);
    final Color borderColor =
        (isDarkMode ? EduTheme.darkInputBorder : EduTheme.inputBorder)
            .withValues(alpha: isDarkMode ? 0.95 : 0.88);
    final Color shadowColor =
        Colors.black.withValues(alpha: isDarkMode ? 0.18 : 0.06);

    return Scaffold(
      backgroundColor: pageBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: pageBackground,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: Text(
          widget.subjectName,
          style: theme.textTheme.titleMedium?.copyWith(
            color: titleColor,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: const [
          SizedBox(width: 8),
        ],
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerScrolled) {
          return [
            SliverPersistentHeader(
              pinned: false,
              delegate: _OverviewHeaderDelegate(
                minExtentHeight: 0,
                maxExtentHeight: 132,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                  child: _SubjectOverviewCard(
                    subjectIcon: subjectIcon,
                    subjectName: widget.subjectName,
                    teacherName: widget.teacherName ?? l10n.studentSubjectDetailYourTeacher,
                    cardColor: cardColor,
                    borderColor: borderColor,
                    titleColor: titleColor,
                    mutedColor: mutedColor,
                    softBoxColor: softBoxColor,
                    progressBackground: progressBackground,
                    shadowColor: shadowColor,
                    progressValue: _subjectProgress?.overallValue ?? 0.0,
                    progressText: _subjectProgress?.overallText ?? '0%',
                  ),
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _TabBarHeaderDelegate(
                tabBar: TabBar(
                  controller: _tabController,
                  labelColor: EduTheme.primary,
                  unselectedLabelColor: mutedColor,
                  indicatorColor: EduTheme.primary,
                  indicatorWeight: 2.2,
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                  labelStyle: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                  unselectedLabelStyle: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  tabs: [
                    Tab(text: l10n.studentSubjectDetailLessons),
                    const Tab(text: 'Quizzes'), // لا يزال غير مترجم
                  ],
                ),
                borderColor: borderColor,
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildLessonsTab(),
            const _PlaceholderTabView(
              title: 'No quizzes yet',
              subtitle: 'Your teacher will add quizzes for this subject soon.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonsTab() {
    final ThemeData theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    final Color cardColor = theme.cardColor;
    final Color titleColor = theme.colorScheme.onSurface;
    final Color mutedColor =
        theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.72) ??
        (isDarkMode ? EduTheme.darkTextMuted : EduTheme.textMuted);
    final Color softBoxColor =
        isDarkMode ? EduTheme.darkSurfaceContainer : EduTheme.softPrimaryBackground;
    final Color borderColor =
        (isDarkMode ? EduTheme.darkInputBorder : EduTheme.inputBorder)
            .withValues(alpha: isDarkMode ? 0.95 : 0.88);
    final Color shadowColor =
        Colors.black.withValues(alpha: isDarkMode ? 0.18 : 0.06);

    return RefreshIndicator(
      onRefresh: _loadLessons,
      child: Builder(
        builder: (context) {
          if (_isLoadingLessons && !_modulesLoaded) {
            return const _CenteredLoadingView();
          }

          if (_lessonsError != null) {
            return _LessonsErrorView(
              titleColor: titleColor,
              mutedColor: mutedColor,
              errorText: _lessonsError!,
              errorTitle: l10n.studentSubjectDetailErrorLoadingLessons,
              retryLabel: l10n.studentSubjectDetailRetry,
              onRetry: _loadLessons,
            );
          }

          if (!_modulesLoaded || _modules.isEmpty) {
            return _LessonsEmptyView(
              mutedColor: mutedColor,
              message: l10n.studentSubjectDetailNoLessonsAvailable,
            );
          }

          if (!_inModuleLessonsView) {
            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              itemCount: _modules.length,
              itemBuilder: (context, index) {
                final module = _modules[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: _ModuleCard(
                    module: module,
                    cardColor: cardColor,
                    borderColor: borderColor,
                    titleColor: titleColor,
                    mutedColor: mutedColor,
                    softBoxColor: softBoxColor,
                    shadowColor: shadowColor,
                    lessonCountLabel: l10n.studentSubjectDetailLessonCount(module.lessons.length),
                    onTap: () {
                      setState(() {
                        _activeModule = module;
                        _inModuleLessonsView = true;
                      });
                    },
                  ),
                );
              },
            );
          }

          final module = _activeModule;
          if (module == null) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [SizedBox(height: 1)],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ModuleLessonsHeader(
                titleColor: titleColor,
                mutedColor: mutedColor,
                moduleTitle: module.title,
                isLoadingLessons: _isLoadingLessons,
                onBack: () {
                  setState(() {
                    _inModuleLessonsView = false;
                    _activeModule = null;
                  });
                },
              ),
              const SizedBox(height: 2),
              Expanded(
                child: module.lessons.isEmpty
                    ? _LessonsEmptyView(
                        mutedColor: mutedColor,
                        message: l10n.studentSubjectDetailNoLessonsInUnit,
                        topSpacing: 70,
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                        itemCount: module.lessons.length,
                        itemBuilder: (context, index) {
                          final lesson = module.lessons[index];

                          return InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () async {
                              final result = await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => StudentLessonViewerScreen(
                                    lessonId: lesson.id,
                                    academicId: widget.academicId,
                                    initialTitle: lesson.title,
                                    initialDurationLabel:
                                        lesson.durationLabel,
                                    initialStatus: lesson.status,
                                  ),
                                ),
                              );

                              if (result is String &&
                                  (result == 'completed' ||
                                      result == 'draft' ||
                                      result == 'not_started')) {
                                setState(() {
                                  lesson.status = result;
                                });
                                await _loadSubjectProgress();
                              }
                            },
                            child: _LessonItemCard(
                              number: index + 1,
                              title: lesson.title,
                              duration: lesson.durationLabel.isEmpty
                                  ? l10n.studentSubjectDetailLesson
                                  : lesson.durationLabel,
                              status: lesson.status,
                              cardColor: cardColor,
                              borderColor: borderColor,
                              titleColor: titleColor,
                              mutedColor: mutedColor,
                              shadowColor: shadowColor,
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}