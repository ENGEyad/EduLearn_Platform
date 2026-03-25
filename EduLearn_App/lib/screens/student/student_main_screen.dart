import 'package:flutter/material.dart';

import 'student_home_screen.dart';
import 'student_subjects_screen.dart';
import 'student_messages_screen.dart';
import 'student_profile_screen.dart';

class StudentMainScreen extends StatefulWidget {
  final Map<String, dynamic> student;
  final List<dynamic> assignedSubjects;

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

    final pages = [
      StudentHomeScreen(
        student: widget.student,
        assignedSubjects: widget.assignedSubjects,
      ),
      StudentSubjectsScreen(
        student: widget.student,
        assignedSubjects: widget.assignedSubjects,
      ),
      StudentMessagesScreen(
        student: widget.student,
      ),
      StudentProfileScreen(
        student: widget.student,
        assignedSubjects: widget.assignedSubjects,
      ),
    ];

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: IndexedStack(
          index: _currentIndex,
          children: pages,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          type: BottomNavigationBarType.fixed,
          showUnselectedLabels: true,
          backgroundColor:
              theme.bottomNavigationBarTheme.backgroundColor ?? theme.cardColor,
          selectedItemColor: theme.bottomNavigationBarTheme.selectedItemColor ??
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
              icon: Icon(Icons.person_rounded),
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