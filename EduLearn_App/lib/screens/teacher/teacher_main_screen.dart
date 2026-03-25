import 'package:flutter/material.dart';

import 'teacher_home_screen.dart';
import 'teacher_classes_screen.dart';
import 'teacher_messages_screen.dart';
import 'teacher_profile_screen.dart';

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
      TeacherProfileScreen(
        teacher: widget.teacher,
        assignments: widget.assignments,
        totalAssignedStudents: widget.totalAssignedStudents,
      ),
    ];
  }

  Future<bool> _onWillPop() async {
    if (_currentIndex != 0) {
      setState(() {
        _currentIndex = 0;
      });
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          type: BottomNavigationBarType.fixed,
          showUnselectedLabels: true,

          backgroundColor:
              theme.bottomNavigationBarTheme.backgroundColor ?? theme.cardColor,

          selectedItemColor:
              theme.bottomNavigationBarTheme.selectedItemColor ??
              theme.colorScheme.primary,

          unselectedItemColor:
              theme.bottomNavigationBarTheme.unselectedItemColor ??
              theme.colorScheme.onSurface.withValues(alpha: 0.6),

          selectedLabelStyle:
              theme.bottomNavigationBarTheme.selectedLabelStyle ??
              const TextStyle(fontWeight: FontWeight.w700),

          unselectedLabelStyle:
              theme.bottomNavigationBarTheme.unselectedLabelStyle ??
              const TextStyle(fontWeight: FontWeight.w500),

          elevation: theme.bottomNavigationBarTheme.elevation ?? 8,

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

          onTap: (index) {
            if (_currentIndex == index) return;

            setState(() {
              _currentIndex = index;
            });
          },
        ),
      ),
    );
  }
}