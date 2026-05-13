import 'package:flutter/material.dart';
import '../../../theme.dart';
import '../../../services/student_service.dart';
import '../../../l10n/core/app_localizations.dart';
import '../../../l10n/getters/student/student_subjects_l10n.dart';
import '../student_subject_detail/student_subject_detail_screen.dart';

part 'student_subjects_models.dart';
part 'student_subjects_widgets.dart';

class StudentSubjectsScreen extends StatefulWidget {
  final Map<String, dynamic> student;
  final List<dynamic> assignedSubjects;

  const StudentSubjectsScreen({
    super.key,
    required this.student,
    required this.assignedSubjects,
  });

  @override
  State<StudentSubjectsScreen> createState() => _StudentSubjectsScreenState();
}

class _StudentSubjectsScreenState extends State<StudentSubjectsScreen> {
  bool _isLoading = false;
  late List<_StudentSubjectItem> _subjectItems;

  @override
  void initState() {
    super.initState();
    _buildInitialSubjects();
    _refreshSubjects();
  }

  void _buildInitialSubjects() {
    _subjectItems = widget.assignedSubjects
        .whereType<Map<String, dynamic>>()
        .map(_StudentSubjectItem.fromMap)
        .whereType<_StudentSubjectItem>()
        .toList();
  }

  Future<void> _refreshSubjects() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final List<dynamic> fresh = await StudentService.fetchStudentSubjects();

      if (!mounted) return;

      final List<_StudentSubjectItem> items = fresh
          .whereType<Map<String, dynamic>>()
          .map(_StudentSubjectItem.fromMap)
          .whereType<_StudentSubjectItem>()
          .toList();

      setState(() {
        _subjectItems = items;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String academicId = (widget.student['academic_id'] ?? '').toString();
    final l10n = AppLocalizations.of(context);

    final theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;

    final Color pageBackground = theme.scaffoldBackgroundColor;
    final Color appBarBackground = theme.scaffoldBackgroundColor;
    final Color titleColor = theme.colorScheme.onSurface;
    final Color mutedColor =
        theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.72) ??
        (isDarkMode ? EduTheme.darkTextMuted : EduTheme.textMuted);
    final Color cardColor = theme.cardColor;
    final Color shadowColor = isDarkMode
        ? Colors.black.withValues(alpha: 0.18)
        : const Color(0x11000000);

    if (_isLoading && _subjectItems.isEmpty) {
      return Scaffold(
        backgroundColor: pageBackground,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: appBarBackground,
          surfaceTintColor: Colors.transparent,
          centerTitle: true,
          iconTheme: IconThemeData(color: titleColor),
          title: Text(
            l10n.studentSubjectsTitle,
            style: TextStyle(
              color: titleColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: const _SubjectsLoadingView(),
      );
    }

    return Scaffold(
      backgroundColor: pageBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: appBarBackground,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        iconTheme: IconThemeData(color: titleColor),
        title: Text(
          l10n.studentSubjectsTitle,
          style: TextStyle(
            color: titleColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: RefreshIndicator(
            onRefresh: _refreshSubjects,
            child: _subjectItems.isEmpty
                ? _SubjectsEmptyView(
                    mutedColor: mutedColor,
                    message: l10n.studentSubjectsEmptyMessage,
                  )
                : GridView.builder(
                    itemCount: _subjectItems.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 3 / 2,
                    ),
                    itemBuilder: (context, index) {
                      final item = _subjectItems[index];

                      return _SubjectGridCard(
                        item: item,
                        cardColor: cardColor,
                        titleColor: titleColor,
                        mutedColor: mutedColor,
                        shadowColor: shadowColor,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => StudentSubjectDetailScreen(
                                subjectId: item.subjectId,
                                academicId: academicId,
                                subjectName: item.subjectName,
                                teacherName: item.teacherName.isNotEmpty
                                    ? item.teacherName
                                    : null,
                                teacherImage: item.teacherImage,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }
}