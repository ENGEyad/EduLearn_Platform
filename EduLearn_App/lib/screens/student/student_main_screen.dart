import 'package:flutter/material.dart';
import '../../theme.dart';

import 'student_home_screen.dart';
import 'student_subjects_screen.dart';
import 'student_messages_screen.dart';
import '../settings/student_settings_screen.dart';
import '../../models/user_models.dart';

class StudentMainScreen extends StatefulWidget {
  final Map<String, dynamic> student;          // 👈 بيانات الطالب من الـ API
  final List<dynamic> assignedSubjects;        // 👈 المواد من الـ API

  const StudentMainScreen({
    super.key,
    required this.student,
    required this.assignedSubjects,
  });

  @override
  State<StudentMainScreen> createState() => _StudentMainScreenState();
}

class _StudentMainScreenState extends State<StudentMainScreen> {
  int _currentIndex = 0;

  Future<bool> _onWillPop() async {
    // لو هو في أي تبويب غير الهوم، رجّعه للهوم بدلاً من الخروج
    if (_currentIndex != 0) {
      setState(() {
        _currentIndex = 0;
      });
      return false;
    }
    // لو هو في الهوم، نسمح بالرجوع (خروج من التطبيق / رجوع للشاشة السابقة)
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      StudentHomeScreen(
        student: widget.student,
        assignedSubjects: widget.assignedSubjects,
      ),
      StudentSubjectsScreen(
        student: widget.student,
        assignedSubjects: widget.assignedSubjects,
      ),
      // 👇 هنا التعديل المهم
      StudentMessagesScreen(
        student: widget.student,
      ),
      // 👇 دمجنا صفحة الاعدادات/البروفايل
      StudentSettingsScreen(
        student: StudentModel(
          id: widget.student['id']?.toString() ?? '0',
          fullName: widget.student['full_name'] ?? widget.student['name'] ?? '',
          email: widget.student['email'] ?? '',
          imageUrl: widget.student['image'] != null
              ? 'http://192.168.1.108:8000/storage/${widget.student['image']}'
              : widget.student['photo'] != null
                  ? 'http://192.168.1.108:8000/storage/${widget.student['photo']}'
                  : null,
          studentId: widget.student['academic_id']?.toString() ?? widget.student['id']?.toString() ?? '',
          gradeLevel: widget.student['grade_level']?.toString(),
          enrolledCourses: widget.assignedSubjects
              .map((s) => Course(
                    id: s['id']?.toString() ?? '0',
                    title: s['name']?.toString() ?? s['subject_name']?.toString() ?? 'Unknown',
                  ))
              .toList(),
        ),
      ),
    ];

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: EduTheme.background,
        body: IndexedStack(
          index: _currentIndex,
          children: pages,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: EduTheme.primary,
          unselectedItemColor: EduTheme.textMuted,
          showUnselectedLabels: true,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_filled),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.menu_book_rounded),
              label: 'Subjects',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.message_rounded),
              label: 'Messages',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_rounded),
              label: 'Settings',
            ),
          ],
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
        ),
      ),
    );
  }
}
