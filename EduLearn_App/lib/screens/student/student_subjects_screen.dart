import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../services/student_service.dart';

import 'student_subject_detail_screen.dart';

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

  late List<Map<String, dynamic>> _subjectItems;

  @override
  void initState() {
    super.initState();
    _buildInitialSubjects();
    _refreshSubjects();
  }

  void _buildInitialSubjects() {
    _subjectItems = widget.assignedSubjects
        .whereType<Map<String, dynamic>>()
        .where((m) {
          final name = (m['subject_name'] ?? '').toString();
          if (name.isEmpty) return false;

          final rawId = m['subject_id'];
          if (rawId == null) return false;

          if (rawId is int) return true;
          if (rawId is String) {
            return int.tryParse(rawId) != null;
          }
          return false;
        })
        .toList();
  }

  Future<void> _refreshSubjects() async {
    final String academicId = (widget.student['academic_id'] ?? '').toString();

    if (academicId.isEmpty) {
      return;
    }

    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final List<dynamic> fresh = await StudentService.fetchStudentSubjects(
        academicId: academicId,
      );

      if (!mounted) return;

      final List<Map<String, dynamic>> items = fresh
          .whereType<Map<String, dynamic>>()
          .where((m) {
            final name = (m['subject_name'] ?? '').toString();
            if (name.isEmpty) return false;

            final rawId = m['subject_id'];
            if (rawId == null) return false;

            if (rawId is int) return true;
            if (rawId is String) {
              return int.tryParse(rawId) != null;
            }
            return false;
          })
          .toList();

      setState(() {
        _subjectItems = items;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String academicId = (widget.student['academic_id'] ?? '').toString();

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
            'My Subjects',
            style: TextStyle(
              color: titleColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
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
          'My Subjects',
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
                ? ListView(
                    children: [
                      const SizedBox(height: 120),
                      Center(
                        child: Text(
                          'No subjects found for your grade.',
                          style: TextStyle(
                            color: mutedColor,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
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
                      final subjectMap = _subjectItems[index];

                      final dynamic rawSubjectId = subjectMap['subject_id'];
                      int? subjectId;
                      if (rawSubjectId is int) {
                        subjectId = rawSubjectId;
                      } else if (rawSubjectId is String) {
                        subjectId = int.tryParse(rawSubjectId);
                      }

                      if (subjectId == null) {
                        return const SizedBox.shrink();
                      }

                      final int safeSubjectId = subjectId;

                      final String subjectName =
                          (subjectMap['subject_name'] ?? '').toString();
                      final String teacherName =
                          (subjectMap['teacher_name'] ?? '').toString();
                      final String? teacherImage =
                          subjectMap['teacher_image'] as String?;

                      final icon = _iconForSubject(subjectName);

                      return GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => StudentSubjectDetailScreen(
                                subjectId: safeSubjectId,
                                academicId: academicId,
                                subjectName: subjectName,
                                teacherName: teacherName.isNotEmpty
                                    ? teacherName
                                    : null,
                                teacherImage: teacherImage,
                              ),
                            ),
                          );
                        },
                        child: Container(
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
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                icon,
                                color: EduTheme.primary,
                                size: 28,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                subjectName,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: titleColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (teacherName.isNotEmpty)
                                Text(
                                  teacherName,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: mutedColor,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }

  static IconData _iconForSubject(String subjectName) {
    switch (subjectName) {
      case 'Quran':
        return Icons.menu_book_rounded;
      case 'Islamic Education':
        return Icons.account_balance_rounded;
      case 'Arabic Language':
        return Icons.language_rounded;
      case 'English Language':
        return Icons.translate_rounded;
      case 'Science':
        return Icons.science_rounded;
      case 'Mathematics':
        return Icons.calculate_rounded;
      case 'Social Studies':
        return Icons.public_rounded;
      case 'Chemistry':
        return Icons.biotech_rounded;
      case 'Physics':
        return Icons.bolt_rounded;
      case 'Biology':
        return Icons.eco_rounded;
      case 'Calculus':
        return Icons.functions_rounded;
      case 'Algebra and Geometry':
        return Icons.square_foot_rounded;
      case 'Geography':
        return Icons.map_rounded;
      case 'History':
        return Icons.history_edu_rounded;
      case 'National Education':
        return Icons.flag_rounded;
      default:
        return Icons.menu_book_rounded;
    }
  }
}