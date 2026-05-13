import 'package:flutter/material.dart';

import '../../../l10n/core/app_localizations.dart';
import '../../../l10n/getters/student/student_main_l10n.dart';
import '../../../theme.dart';
import '../student_home/student_home_screen.dart';
import '../student_messages/student_messages_screen.dart';
import '../student_profile/student_profile_screen.dart';
import '../student_subjects/student_subjects_screen.dart';

class StudentMainScreen extends StatefulWidget {
  final Map<String, dynamic> student;

  const StudentMainScreen({
    super.key,
    required this.student,
  });

  @override
  State<StudentMainScreen> createState() => _StudentMainScreenState();
}

class _StudentMainScreenState extends State<StudentMainScreen> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  static const List<_StudentMainDestination> _destinations = [
    _StudentMainDestination(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
    ),
    _StudentMainDestination(
      icon: Icons.menu_book_outlined,
      selectedIcon: Icons.menu_book_rounded,
    ),
    _StudentMainDestination(
      icon: Icons.chat_bubble_outline_rounded,
      selectedIcon: Icons.chat_bubble_rounded,
    ),
    _StudentMainDestination(
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();

    // يمكنك استبدال [] بـ (widget.student['subjects'] as List<dynamic>?) ?? []
    // إن كانت بيانات الطالب تحتوي على المواد مسبقاً
    _pages = [
      StudentHomeScreen(student: widget.student),
      StudentSubjectsScreen(
        student: widget.student,
        assignedSubjects: const [], // <-- تمت إضافة الوسيط المطلوب
      ),
      StudentMessagesScreen(student: widget.student),
      StudentProfileScreen(student: widget.student, assignedSubjects: const []),
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

  List<String> _localizedLabels(AppLocalizations l10n) {
    return <String>[
      l10n.studentMainHome,
      l10n.studentMainSubjects,
      l10n.studentMainMessages,
      l10n.studentMainProfile,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final labels = _localizedLabels(l10n);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final canPop = await _onWillPop();
        if (canPop && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        extendBody: true,
        body: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? EduTheme.darkSurface.withValues(alpha: 0.94)
                  : EduTheme.surface.withValues(alpha: 0.96),
              borderRadius: EduTheme.radiusXL,
              border: Border.all(
                color: (isDark ? EduTheme.darkInputBorder : EduTheme.inputBorder)
                    .withValues(alpha: 0.90),
              ),
              boxShadow: EduTheme.cardShadow(isDark),
            ),
            child: ClipRRect(
              borderRadius: EduTheme.radiusXL,
              child: NavigationBar(
                selectedIndex: _currentIndex,
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                destinations: List.generate(
                  _destinations.length,
                  (index) => NavigationDestination(
                    icon: Icon(_destinations[index].icon),
                    selectedIcon: Icon(_destinations[index].selectedIcon),
                    label: labels[index],
                  ),
                ),
                onDestinationSelected: (index) {
                  if (_currentIndex == index) return;
                  setState(() {
                    _currentIndex = index;
                  });
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StudentMainDestination {
  final IconData icon;
  final IconData selectedIcon;

  const _StudentMainDestination({
    required this.icon,
    required this.selectedIcon,
  });
}