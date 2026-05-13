import 'package:flutter/material.dart';

import '../../../l10n/core/app_localizations.dart';
import '../../../l10n/getters/teacher/teacher_classes_l10n.dart';

import '../../../services/api_service.dart';
import '../../../services/teacher_data_service.dart';
import '../../../theme.dart';
import '../class_details/class_details_screen.dart';

part 'teacher_classes_widgets.dart';

class TeacherClassesScreen extends StatefulWidget {
  final Map<String, dynamic> teacher;

  const TeacherClassesScreen({
    super.key,
    required this.teacher,
  });

  @override
  State<TeacherClassesScreen> createState() => _TeacherClassesScreenState();
}

class _TeacherClassesScreenState extends State<TeacherClassesScreen> {
  bool _isLoading = false;
  List<dynamic> _assignments = [];

  String get fullName => (widget.teacher['full_name'] ?? '').toString();
  String get teacherCode => (widget.teacher['teacher_code'] ?? '').toString();

  @override
  void initState() {
    super.initState();
    _refreshAssignments();
  }

  int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  Future<void> _refreshAssignments() async {
    if (teacherCode.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // ✅ no longer passing teacherCode
      final List<dynamic> fresh = await TeacherDataService.fetchAssignmentsSummary();

      if (!mounted) return;
      setState(() {
        _assignments = fresh;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _buildClassKey({
    required String grade,
    required String section,
    required String subjectName,
  }) {
    return '${grade.trim()}_${section.trim()}_${subjectName.trim()}';
  }

  String _buildClassLabel({
    required BuildContext context,
    required String grade,
    required String section,
  }) {
    final l10n = AppLocalizations.of(context);
    final parts = <String>[];

    if (grade.isNotEmpty) {
      parts.add('${l10n.grade} $grade');
    }

    if (section.isNotEmpty) {
      parts.add('${l10n.section} $section');
    }

    return parts.join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color pageBackground = theme.scaffoldBackgroundColor;
    final Color titleColor = theme.colorScheme.onSurface;

    return Scaffold(
      backgroundColor: pageBackground,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // لاحقاً: إضافة درس أو كلاس جديد من هنا إن حبيت
        },
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: isDark ? 2 : 6,
        child: const Icon(Icons.add_rounded),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: theme.colorScheme.primary,
          onRefresh: _refreshAssignments,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.myClasses,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Text(
                            l10n.assignedClasses,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: titleColor,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Spacer(),
                          if (_isLoading)
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colorScheme.primary,
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '${_assignments.length}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              if (_isLoading && _assignments.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _TeacherClassesLoadingState(),
                )
              else if (_assignments.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _TeacherClassesEmptyState(),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  sliver: SliverList.separated(
                    itemCount: _assignments.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = _assignments[index];
                      if (item is! Map<String, dynamic>) {
                        return const SizedBox.shrink();
                      }

                      final String grade = (item['class_grade'] ?? '').toString();
                      final String section = (item['class_section'] ?? '').toString();
                      final String subjectName = (item['subject_name'] ?? '').toString();

                      final int studentsCount = _parseInt(item['students_count']);

                      final String classLabel = _buildClassLabel(
                        context: context,
                        grade: grade,
                        section: section,
                      );

                      final String classKey = _buildClassKey(
                        grade: grade,
                        section: section,
                        subjectName: subjectName,
                      );

                      final int assignmentId = _parseInt(item['assignment_id']);
                      final int classSectionId = _parseInt(item['class_section_id']);
                      final int subjectId = _parseInt(item['subject_id']);

                      if (assignmentId == 0 || classSectionId == 0 || subjectId == 0) {
                        return const SizedBox.shrink();
                      }

                      return _ClassCard(
                        grade: grade,
                        section: section,
                        subjectName: subjectName,
                        classLabel: classLabel,
                        studentsCount: studentsCount,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ClassDetailsScreen(
                                classTitle: [
                                  if (grade.isNotEmpty) grade,
                                  if (section.isNotEmpty) '${l10n.section} $section',
                                  if (subjectName.isNotEmpty) subjectName,
                                ].join(' - '),
                                grade: grade,
                                section: section,
                                subjectName: subjectName,
                                classKey: classKey,
                                studentsCount: studentsCount,
                                students: const [],
                                teacherCode: teacherCode, // still needed for LessonBuilderScreen
                                assignmentId: assignmentId,
                                classSectionId: classSectionId,
                                subjectId: subjectId,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}