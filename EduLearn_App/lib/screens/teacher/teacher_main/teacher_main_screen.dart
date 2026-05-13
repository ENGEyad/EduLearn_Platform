import 'package:flutter/material.dart';
import '../../../l10n/core/app_localizations.dart';
import '../../../l10n/getters/teacher/teacher_main_l10n.dart';
import '../../../l10n/getters/teacher/teacher_profile_l10n.dart';
import '../../../theme.dart';
import '../teacher_classes/teacher_classes_screen.dart';
import '../teacher_home/teacher_home_screen.dart';
import '../teacher_messages/teacher_messages_screen.dart';
import '../teacher_profile/teacher_profile_screen.dart';

class TeacherMainScreen extends StatefulWidget {
  final Map<String, dynamic> teacher;

  const TeacherMainScreen({
    super.key,
    required this.teacher,
  });

  @override
  State<TeacherMainScreen> createState() => _TeacherMainScreenState();
}

class _TeacherMainScreenState extends State<TeacherMainScreen> {
  int _currentIndex = 0;
  late final List<Widget> _pages;

  static const List<_TeacherMainDestination> _destinations = [
    _TeacherMainDestination(icon: Icons.grid_view_rounded, selectedIcon: Icons.grid_view_rounded),
    _TeacherMainDestination(icon: Icons.group_outlined, selectedIcon: Icons.group_rounded),
    _TeacherMainDestination(icon: Icons.chat_bubble_outline_rounded, selectedIcon: Icons.chat_bubble_rounded),
    _TeacherMainDestination(icon: Icons.person_outline_rounded, selectedIcon: Icons.person_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _pages = [
      TeacherHomeScreen(teacher: widget.teacher),
      TeacherClassesScreen(teacher: widget.teacher),
      TeacherMessagesScreen(teacher: widget.teacher, assignments: const [], totalAssignedStudents: 0),
      TeacherProfileScreen(teacher: widget.teacher, assignments: const [], totalAssignedStudents: 0),
    ];
  }

  Future<bool> _onWillPop() async {
    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
      return false;
    }
    return true;
  }

  List<String> _localizedLabels(AppLocalizations l10n) {
    return <String>[l10n.dashboard, l10n.classes, l10n.messages, l10n.profile];
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
        if (canPop && mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        extendBody: true,
        body: IndexedStack(index: _currentIndex, children: _pages),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? EduTheme.darkSurface.withValues(alpha: 0.94) : EduTheme.surface.withValues(alpha: 0.96),
              borderRadius: EduTheme.radiusXL,
              border: Border.all(color: (isDark ? EduTheme.darkInputBorder : EduTheme.inputBorder).withValues(alpha: 0.90)),
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
                  setState(() => _currentIndex = index);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TeacherMainDestination {
  final IconData icon;
  final IconData selectedIcon;
  const _TeacherMainDestination({required this.icon, required this.selectedIcon});
}