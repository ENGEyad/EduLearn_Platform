import 'dart:async';
import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/auth_service.dart';
import 'student/student_main_screen.dart';
import 'teacher/teacher_main_screen.dart';
import 'auth/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    // Wait for the splash screen animation/timer
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    final session = await AuthService.getSession();
    final type = await AuthService.getUserType();

    if (session != null && type != null) {
      if (type == 'student') {
        final student = session['student'] as Map<String, dynamic>;
        final assignedSubjects = (student['assigned_subjects'] as List?) ?? [];

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => StudentMainScreen(
              student: student,
              assignedSubjects: assignedSubjects,
            ),
          ),
        );
      } else {
        final teacher = session['teacher'] as Map<String, dynamic>;
        final assignments = (teacher['assignments'] as List?) ?? [];

        // Calculate total students (same logic as in RegisterScreen)
        final int totalAssignedStudents = assignments.fold<int>(0, (sum, item) {
          if (item is! Map<String, dynamic>) return sum;
          final dynamic count = item['students_count'];
          if (count is int) return sum + count;
          if (count is num) return sum + count.toInt();
          if (count is String) return sum + (int.tryParse(count) ?? 0);
          return sum;
        });

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => TeacherMainScreen(
              teacher: teacher,
              assignments: assignments,
              totalAssignedStudents: totalAssignedStudents,
            ),
          ),
        );
      }
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // الدائرة مع أيقونة الشعار – تقدر تضيف صورتك بدل الأيقونة
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: EduTheme.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.school_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'EduLearn',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: EduTheme.primaryDark,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Empowering smart, connected learning.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: EduTheme.textMuted,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
