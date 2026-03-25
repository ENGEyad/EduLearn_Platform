import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../services/student_service.dart';
import 'student_lesson_viewer_screen.dart';

class StudentSubjectDetailScreen extends StatefulWidget {
  final int subjectId; // 👈 من الـ API
  final String academicId; // 👈 رقم الطالب الأكاديمي

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

  // ======== منطق الوحدات + الدروس للطالب ========
  bool _modulesLoaded = false;
  final List<_StudentLessonModule> _modules = [];
  bool _inModuleLessonsView = false;
  _StudentLessonModule? _activeModule;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadLessons();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ✅ Refresh friendly (سحب للتحديث)
  Future<void> _loadLessons() async {
    if (_isLoadingLessons) return;

    setState(() {
      _isLoadingLessons = true;
      _lessonsError = null;
      _modulesLoaded = false;
      _modules.clear();
      _inModuleLessonsView = false;
      _activeModule = null;
    });

    try {
      final list = await StudentService.fetchStudentLessonsForSubject(
        academicId: widget.academicId,
        subjectId: widget.subjectId,
      );

      final lessons = list.whereType<Map<String, dynamic>>().toList();

      if (lessons.isEmpty) {
        setState(() {
          _modulesLoaded = true;
        });
        return;
      }

      // ✅ نجمع الدروس بحسب class_module_id (والسيرفر يرجع module_title)
      final Map<String, _StudentLessonModule> moduleMap = {};

      for (final raw in lessons) {
        // 🔹 قراءة ID بشكل آمن
        final dynamic rawId = raw['id'];
        final int? id = (rawId is int)
            ? rawId
            : (rawId is String ? int.tryParse(rawId) : null);
        if (id == null) continue;

        // 🔹 قراءة عنوان الدرس
        final String title = (raw['title'] ?? '').toString();

        // 🔹 قراءة مدة الدرس / ليبل
        final String duration =
            (raw['duration_label'] ?? '').toString().trim();

        // 🔹 حالة الدرس (not_started | draft | completed)
        String status = (raw['status'] ?? 'not_started').toString();
        if (status != 'not_started' &&
            status != 'draft' &&
            status != 'completed') {
          status = 'not_started';
        }

        // 🔹 بيانات الموديول
        final dynamic rawModuleId = raw['class_module_id'] ?? raw['module_id'];

        // مفتاح تجميع ثابت
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

      // ✅ ترتيب الموديولات: default/غير معروف في الأخير، والباقي حسب id
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

        // ✅ ترتيب الدروس داخل كل موديول (لو السيرفر يرجع number يمكن نستخدمه لاحقاً)
        for (final m in _modules) {
          // لا يوجد sort_order هنا، فنكتفي بالترتيب القادم من السيرفر
          // (السيرفر مرتب أصلاً حسب class_module_id ثم published_at)
        }
      });
    } catch (e) {
      setState(() {
        _lessonsError = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLessons = false;
          _modulesLoaded = true; // ✅ حتى لو فشل، نعتبرها انتهت تحميل
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
    final subjectIcon = _iconForSubject(widget.subjectName);
    final theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;

    final Color pageBackground = theme.scaffoldBackgroundColor;
    final Color cardColor = theme.cardColor;
    final Color titleColor = theme.colorScheme.onSurface;
    final Color mutedColor =
        theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.72) ??
        (isDarkMode ? EduTheme.darkTextMuted : EduTheme.textMuted);
    final Color softBoxColor =
        isDarkMode ? EduTheme.darkSurface : const Color(0xFFE5F2FF);
    final Color progressBackground =
        isDarkMode ? const Color(0xFF2A3441) : const Color(0xFFE3E7F3);
    final Color shadowColor = isDarkMode
        ? Colors.black.withValues(alpha: 0.18)
        : const Color(0x11000000);

    return Scaffold(
      backgroundColor: pageBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: pageBackground,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: titleColor,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: Text(
          widget.subjectName,
          style: TextStyle(
            color: titleColor,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.more_vert_rounded,
              color: titleColor,
            ),
          ),
        ],
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerScrolled) {
          return [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: shadowColor,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: softBoxColor,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(
                          subjectIcon,
                          color: EduTheme.primary,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.subjectName,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: titleColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.teacherName ?? 'Your teacher',
                              style: TextStyle(
                                color: mutedColor,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: LinearProgressIndicator(
                                    value: 0.75,
                                    minHeight: 6,
                                    backgroundColor: progressBackground,
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                      EduTheme.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  '75%',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: EduTheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _TabBarHeaderDelegate(
                TabBar(
                  controller: _tabController,
                  labelColor: EduTheme.primary,
                  unselectedLabelColor: mutedColor,
                  indicatorColor: EduTheme.primary,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                  tabs: const [
                    Tab(text: 'Lessons'),
                    Tab(text: 'Quizzes'),
                    Tab(text: 'Question Bank'),
                  ],
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildLessonsTab(),
            _buildPlaceholderTab(
              title: 'No quizzes yet',
              subtitle: 'Your teacher will add quizzes for this subject soon.',
            ),
            _buildPlaceholderTab(
              title: 'Question bank is empty',
              subtitle:
                  'Practice questions will appear here once they are added.',
            ),
          ],
        ),
      ),
    );
  }

  // ==================== تبويب الدروس (مع الوحدات) ====================

  Widget _buildLessonsTab() {
    final theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;

    final Color cardColor = theme.cardColor;
    final Color titleColor = theme.colorScheme.onSurface;
    final Color mutedColor =
        theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.72) ??
        (isDarkMode ? EduTheme.darkTextMuted : EduTheme.textMuted);
    final Color softBoxColor =
        isDarkMode ? EduTheme.darkSurface : const Color(0xFFE8F3FF);
    final Color shadowColor = isDarkMode
        ? Colors.black.withValues(alpha: 0.18)
        : const Color(0x11000000);

    // ✅ Pull to refresh بدون تغيير التصميم العام
    return RefreshIndicator(
      onRefresh: _loadLessons,
      child: Builder(
        builder: (context) {
          if (_isLoadingLessons && !_modulesLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_lessonsError != null) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 90),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Error loading lessons',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: titleColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _lessonsError!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: mutedColor,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: _loadLessons,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          if (!_modulesLoaded || _modules.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 90),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'No lessons available yet.\nYour teacher will add lessons for this subject.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: mutedColor,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          // 🧩 وضع عرض الوحدات
          if (!_inModuleLessonsView) {
            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _modules.length,
              itemBuilder: (context, index) {
                final module = _modules[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {
                      setState(() {
                        _activeModule = module;
                        _inModuleLessonsView = true;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: shadowColor,
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: softBoxColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.folder_open_rounded,
                              color: EduTheme.primary,
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
                                    color: titleColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${module.lessons.length} lesson(s)',
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
          }

          // 🧩 وضع عرض دروس وحدة معيّنة
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
              // شريط علوي: رجوع + اسم الوحدة
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 4.0,
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _inModuleLessonsView = false;
                          _activeModule = null;
                        });
                      },
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: titleColor,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        module.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: titleColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_isLoadingLessons)
                      const Padding(
                        padding: EdgeInsets.only(right: 8.0),
                        child: SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: module.lessons.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 70),
                          Center(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 32),
                              child: Text(
                                'No lessons yet for this unit.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: mutedColor,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        itemCount: module.lessons.length,
                        itemBuilder: (context, index) {
                          final lesson = module.lessons[index];

                          return InkWell(
                            onTap: () async {
                              // ✅ حسب الاتفاق: لا يوجد قفل لـ not_started
                              // الطالب يستطيع فتح الدرس (منشور أصلاً) وسيتم تحديث حالته عبر Viewer.
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

                              // ✅ تحديث الحالة محلياً (وسريع)
                              if (result is String &&
                                  (result == 'completed' ||
                                      result == 'draft' ||
                                      result == 'not_started')) {
                                setState(() {
                                  lesson.status = result;
                                });
                              }
                            },
                            child: _lessonItem(
                              number: index + 1,
                              title: lesson.title,
                              duration: lesson.durationLabel.isEmpty
                                  ? 'Lesson'
                                  : lesson.durationLabel,
                              status: lesson.status,
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

  Widget _buildPlaceholderTab({
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;

    final Color titleColor = theme.colorScheme.onSurface;
    final Color mutedColor =
        theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.72) ??
        (isDarkMode ? EduTheme.darkTextMuted : EduTheme.textMuted);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: titleColor,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: mutedColor,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _lessonItem({
    required int number,
    required String title,
    required String duration,
    required String status, // not_started | draft | completed
  }) {
    final theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;

    final Color cardColor = theme.cardColor;
    final Color titleColor = theme.colorScheme.onSurface;
    final Color mutedColor =
        theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.72) ??
        (isDarkMode ? EduTheme.darkTextMuted : EduTheme.textMuted);
    final Color shadowColor = isDarkMode
        ? Colors.black.withValues(alpha: 0.18)
        : const Color(0x11000000);

    // ✅ حسب الاتفاق: not_started ليس مقفل — فقط “ابدأ”
    Color circleColor;
    IconData trailingIcon;

    if (status == 'completed') {
      circleColor = const Color(0xFF4CAF50);
      trailingIcon = Icons.check_circle_rounded;
    } else if (status == 'draft') {
      circleColor = EduTheme.primary;
      trailingIcon = Icons.play_circle_fill_rounded;
    } else {
      // not_started
      circleColor = titleColor.withValues(alpha: 0.35);
      trailingIcon = Icons.play_circle_outline_rounded;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: circleColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number.toString(),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: circleColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  duration,
                  style: TextStyle(
                    fontSize: 12,
                    color: mutedColor,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            trailingIcon,
            color: circleColor,
            size: 26,
          ),
        ],
      ),
    );
  }
}

class _TabBarHeaderDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _TabBarHeaderDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant _TabBarHeaderDelegate oldDelegate) => false;
}

// ==================== Models داخل صفحة الطالب ====================

class _StudentLessonModule {
  final int id;
  final String title;
  final List<_StudentLessonSummary> lessons;

  _StudentLessonModule({
    required this.id,
    required this.title,
    required this.lessons,
  });
}

class _StudentLessonSummary {
  final int id;
  final String title;
  final String durationLabel;
  String status; // not_started | draft | completed

  _StudentLessonSummary({
    required this.id,
    required this.title,
    required this.durationLabel,
    required this.status,
  });
}