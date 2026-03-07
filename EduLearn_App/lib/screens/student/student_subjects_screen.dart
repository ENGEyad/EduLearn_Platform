import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../services/student_service.dart';

import 'student_subject_detail_screen.dart';

class StudentSubjectsScreen extends StatefulWidget {
  final Map<String, dynamic> student;          // 👈 بيانات الطالب من الـ API
  final List<dynamic> assignedSubjects;        // 👈 قائمة المواد من الـ API (القديمة من تسجيل الدخول)

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

  /// ✅ نبني قائمة المواد المبدئية من بيانات تسجيل الدخول
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

    setState(() {
      _isLoading = true;
    });

    try {
      final List<dynamic> fresh = await StudentService.fetchStudentSubjects(
        academicId: academicId,
      );

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
      setState(() {
        _isLoading = false;
      });
      // ممكن تضيف Snackbar هنا لاحقاً لو حاب
    }
  }

  @override
  Widget build(BuildContext context) {
    final String fullName = (widget.student['full_name'] ?? '').toString();
    final String academicId = (widget.student['academic_id'] ?? '').toString();

    if (_isLoading && _subjectItems.isEmpty) {
      return Scaffold(
        backgroundColor: EduTheme.background,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: EduTheme.background,
          centerTitle: true,
          title: const Text(
            'My Subjects',
            style: TextStyle(
              color: EduTheme.primaryDark,
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
      backgroundColor: EduTheme.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: EduTheme.background,
        centerTitle: true,
        title: const Text(
          'My Subjects',
          style: TextStyle(
            color: EduTheme.primaryDark,
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
                    children: const [
                      SizedBox(height: 120),
                      Center(
                        child: Text(
                          'No subjects found for your grade.',
                          style: TextStyle(
                            color: EduTheme.textMuted,
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

                      // ✅ قراءة subject_id بشكل آمن
                      final dynamic rawSubjectId = subjectMap['subject_id'];
                      int? subjectId;
                      if (rawSubjectId is int) {
                        subjectId = rawSubjectId;
                      } else if (rawSubjectId is String) {
                        subjectId = int.tryParse(rawSubjectId);
                      }

                      // لو الـ ID غير صالح نتجاهل هذا الكرت بدل ما يطيح التطبيق
                      if (subjectId == null) {
                        return const SizedBox.shrink();
                      }
                      // ✅ هنا مضمون إنه non-null
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
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x11000000),
                                blurRadius: 6,
                                offset: Offset(0, 2),
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
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: EduTheme.primaryDark,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (teacherName.isNotEmpty)
                                Text(
                                  teacherName,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: EduTheme.textMuted,
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
