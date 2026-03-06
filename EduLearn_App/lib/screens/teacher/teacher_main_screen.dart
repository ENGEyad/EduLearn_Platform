import 'package:flutter/material.dart';
import '../../theme.dart';

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
<<<<<<< HEAD
    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
      return false;
    }
=======
    // لو مش في الـ Dashboard → رجعه للـ Dashboard
    if (_currentIndex != 0) {
      setState(() {
        _currentIndex = 0;
      });
      return false; // لا تخرج من الشاشة
    }
    // في الـ Dashboard → اسمح بالرجوع (يرجع لشاشة التسجيل/تسجيل الدخول)
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: EduTheme.background,
<<<<<<< HEAD
        body: IndexedStack(index: _currentIndex, children: _pages),
        bottomNavigationBar: _TeacherBottomNav(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
=======
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
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
        ),
      ),
    );
  }
}
<<<<<<< HEAD

// ── Premium Teacher Bottom Navigation Bar ─────────────────────────────────────
class _TeacherBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _TeacherBottomNav({required this.currentIndex, required this.onTap});

  static const _items = [
    _NavItem(
        icon: Icons.grid_view_rounded,
        outlinedIcon: Icons.grid_view_outlined,
        label: 'Dashboard'),
    _NavItem(
        icon: Icons.group_rounded,
        outlinedIcon: Icons.group_outlined,
        label: 'Classes'),
    _NavItem(
        icon: Icons.chat_bubble_rounded,
        outlinedIcon: Icons.chat_bubble_outline_rounded,
        label: 'Messages'),
    _NavItem(
        icon: Icons.person_rounded,
        outlinedIcon: Icons.person_outline_rounded,
        label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: EduTheme.primaryDark.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_items.length, (i) {
              final item = _items[i];
              final selected = i == currentIndex;
              return GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOut,
                  padding: EdgeInsets.symmetric(
                    horizontal: selected ? 16 : 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: selected ? EduTheme.primaryGradient : null,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        selected ? item.icon : item.outlinedIcon,
                        color: selected ? Colors.white : EduTheme.textMuted,
                        size: 22,
                      ),
                      if (selected) ...[
                        const SizedBox(width: 6),
                        Text(
                          item.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData outlinedIcon;
  final String label;
  const _NavItem(
      {required this.icon,
      required this.outlinedIcon,
      required this.label});
}
=======
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
