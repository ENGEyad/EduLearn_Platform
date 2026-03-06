import 'package:flutter/material.dart';
import '../../theme.dart';

class StudentProfileScreen extends StatelessWidget {
  const StudentProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EduTheme.background,
      appBar: AppBar(
        backgroundColor: EduTheme.background,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: EduTheme.primaryDark,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: const Center(
        child: Text(
          'Profile screen (placeholder)',
          style: TextStyle(color: EduTheme.textMuted),
        ),
      ),
    );
  }
}
