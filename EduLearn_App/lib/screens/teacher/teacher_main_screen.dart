import 'package:flutter/material.dart';
import '../../theme.dart';

import 'teacher_home_screen.dart';
import 'teacher_classes_screen.dart';
import 'teacher_messages_screen.dart';
import '../settings/teacher_settings_screen.dart';
import '../../models/user_models.dart';

class TeacherMainScreen extends StatefulWidget {
  final Map<String, dynamic> teacher;
  final List<dynamic> assignments;
  final int totalAssignedStudents;

  const TeacherMainScreen({
    super.key,
    required this.teacher,
    required this.assignments,
    required this.totalAssignedStudents,
  });

  @override
  State<TeacherMainScreen> createState() => _TeacherMainScreenState();
}

class _TeacherMainScreenState extends State<TeacherMainScreen> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      TeacherHomeScreen(
        teacher: widget.teacher,
        assignments: widget.assignments,
        totalAssignedStudents: widget.totalAssignedStudents,
      ),
      TeacherClassesScreen(
        teacher: widget.teacher,
        assignments: widget.assignments,
        totalAssignedStudents: widget.totalAssignedStudents,
      ),
      TeacherMessagesScreen(
        teacher: widget.teacher,
        assignments: widget.assignments,
        totalAssignedStudents: widget.totalAssignedStudents,
      ),
      TeacherSettingsScreen(
        teacher: TeacherModel(
          id: widget.teacher['id'].toString(),
          fullName: widget.teacher['name'] ?? '',
          email: widget.teacher['email'] ?? '',
          imageUrl: widget.teacher['photo'] != null 
              ? 'http://172.21.108.44:8000/storage/${widget.teacher['photo']}' 
              : null,
          teacherCode: widget.teacher['teacher_code'] ?? 'TCH-${widget.teacher['id']}',
          assignments: widget.assignments.map((a) => Assignment(id: a['subject_id'].toString(), name: '${a['class_name']} - ${a['subject_name']}')).toList(),
          totalAssignedStudents: widget.totalAssignedStudents,
        ),
      ),
    ];
  }

  Future<bool> _onWillPop() async {
    // لو مش في الـ Dashboard → رجعه للـ Dashboard
    if (_currentIndex != 0) {
      setState(() {
        _currentIndex = 0;
      });
      return false; // لا تخرج من الشاشة
    }
    // في الـ Dashboard → اسمح بالرجوع (يرجع لشاشة التسجيل/تسجيل الدخول)
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: EduTheme.background,
        body: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: EduTheme.primary,
          unselectedItemColor: EduTheme.textMuted,
          showUnselectedLabels: true,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_rounded),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.group_rounded),
              label: 'Classes',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline_rounded),
              label: 'Messages',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
