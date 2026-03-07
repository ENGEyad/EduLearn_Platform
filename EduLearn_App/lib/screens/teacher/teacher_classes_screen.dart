import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../services/api_service.dart';

import 'class_details_screen.dart';

class TeacherClassesScreen extends StatefulWidget {
  final Map<String, dynamic> teacher;   // بيانات الأستاذ من الـ API
  final List<dynamic> assignments;
  final int totalAssignedStudents;

  const TeacherClassesScreen({
    super.key,
    required this.teacher,
    required this.assignments,
    required this.totalAssignedStudents,
  });

  @override
  State<TeacherClassesScreen> createState() => _TeacherClassesScreenState();
}

class _TeacherClassesScreenState extends State<TeacherClassesScreen> {
  bool _isLoading = false;
  late List<dynamic> _assignments;

  String get fullName => (widget.teacher['full_name'] ?? '').toString();
  String get teacherCode => (widget.teacher['teacher_code'] ?? '').toString();

  @override
  void initState() {
    super.initState();
    // نبدأ بالبيانات الممرّرة من تسجيل الدخول
    _assignments = widget.assignments;
    // ثم نحدّثها من السيرفر
    _refreshAssignments();
  }

  /// ✅ تحويل أي قيمة إلى int بشكل آمن
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
      final List<dynamic> fresh =
          await TeacherService.fetchTeacherAssignments(teacherCode: teacherCode);

      setState(() {
        _assignments = fresh;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // ممكن تضيف Snackbar لو حاب لاحقاً
    }
  }

  String _buildClassKey({
    required String grade,
    required String section,
    required String subjectName,
  }) {
    return '${grade.trim()}_${section.trim()}_${subjectName.trim()}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EduTheme.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: EduTheme.background,
        centerTitle: true,
        title: const Text(
          'My Classes',
          style: TextStyle(
            color: EduTheme.primaryDark,
            fontWeight: FontWeight.w700,
          ),
        ),
        // تبويب رئيسي، لذلك لا نضع سهم رجوع هنا
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(
              Icons.search_rounded,
              color: EduTheme.primaryDark,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading && _assignments.isEmpty
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : RefreshIndicator(
                onRefresh: _refreshAssignments,
                child: ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _assignments.length,
                  itemBuilder: (context, index) {
                    final item = _assignments[index];
                    if (item is! Map<String, dynamic>) {
                      return const SizedBox.shrink();
                    }

                    final String grade =
                        (item['class_grade'] ?? '').toString();
                    final String section =
                        (item['class_section'] ?? '').toString();
                    final String subjectName =
                        (item['subject_name'] ?? '').toString();

                    final String title = [
                      if (grade.isNotEmpty) grade,
                      if (section.isNotEmpty) 'Section $section',
                      if (subjectName.isNotEmpty) subjectName,
                    ].join(' - ');

                    final int studentsCount =
                        (item['students_count'] as int?) ?? 0;
                    const String scheduleText =
                        'Mon, Wed, Fri - 10:00 AM';

                    final double progress =
                        [0.85, 0.45, 1.0, 0.6][index % 4];
                    final String progressText =
                        '${(progress * 100).round()}%';

                    final classKey = _buildClassKey(
                      grade: grade,
                      section: section,
                      subjectName: subjectName,
                    );

                    final List<dynamic> students =
                        (item['students'] as List<dynamic>?) ?? [];

                    // ✅ IDs الحقيقية من الـ API بشكل آمن
                    final int assignmentId =
                        _parseInt(item['assignment_id']);
                    final int classSectionId =
                        _parseInt(item['class_section_id']);
                    final int subjectId =
                        _parseInt(item['subject_id']);

                    // ❗ لو واحد من IDs طلع 0 (مفقود أو غير صالح) نتجاهل هذه الكلاس
                    if (assignmentId == 0 ||
                        classSectionId == 0 ||
                        subjectId == 0) {
                      return const SizedBox.shrink();
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: _classCard(
                        title: title,
                        grade: grade,
                        section: section,
                        subjectName: subjectName,
                        studentsCount: studentsCount,
                        schedule: scheduleText,
                        progress: progress,
                        progressText: progressText,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ClassDetailsScreen(
                                classTitle: title,
                                grade: grade,
                                section: section,
                                subjectName: subjectName,
                                classKey: classKey,
                                studentsCount: studentsCount,
                                students: students,
                                teacherCode: teacherCode,
                                assignmentId: assignmentId,
                                classSectionId: classSectionId,
                                subjectId: subjectId,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // لاحقاً: إضافة درس أو كلاس جديد من هنا إن حبيت
        },
        backgroundColor: EduTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _classCard({
    required String title,
    required String grade,
    required String section,
    required String subjectName,
    required int studentsCount,
    required String schedule,
    required double progress,
    required String progressText,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Color(0x11000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D6C3C),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.eco_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: EduTheme.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (grade.isNotEmpty || section.isNotEmpty)
                        Row(
                          children: [
                            const Icon(
                              Icons.class_rounded,
                              size: 16,
                              color: EduTheme.textMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              [
                                if (grade.isNotEmpty) 'Grade: $grade',
                                if (section.isNotEmpty) 'Section: $section',
                              ].join(' | '),
                              style: const TextStyle(
                                fontSize: 13,
                                color: EduTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.group_rounded,
                            size: 16,
                            color: EduTheme.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$studentsCount Students',
                            style: const TextStyle(
                              fontSize: 13,
                              color: EduTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_month_rounded,
                            size: 16,
                            color: EduTheme.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            schedule,
                            style: const TextStyle(
                              fontSize: 13,
                              color: EduTheme.textMuted,
                            ),
                          ),
                        ],
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
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: const Color(0xFFE3E7F3),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF8DD2F0),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  progressText,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: EduTheme.primaryDark,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
