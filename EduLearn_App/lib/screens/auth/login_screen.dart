import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../main.dart';
import '../../services/auth_service.dart';
import '../student/student_main_screen.dart';
import '../teacher/teacher_main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController fullNameCtrl = TextEditingController();
  final TextEditingController idCtrl = TextEditingController();

  bool isStudent = true;
  bool isLoading = false;

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      if (isStudent) {
        final res = await AuthService.authStudent(
          fullName: fullNameCtrl.text.trim(),
          academicId: idCtrl.text.trim(),
        );

        final Map<String, dynamic> student =
            (res['student'] as Map<String, dynamic>);

        final List<dynamic> assignedSubjects =
            (student['assigned_subjects'] as List<dynamic>?) ?? [];

        if (!mounted) return;

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => StudentMainScreen(
              student: student,
              assignedSubjects: assignedSubjects,
            ),
          ),
        );
      } else {
        final res = await AuthService.authTeacher(
          fullName: fullNameCtrl.text.trim(),
          teacherCode: idCtrl.text.trim(),
        );

        final Map<String, dynamic> teacher =
            (res['teacher'] as Map<String, dynamic>);

        final assignmentsRaw = teacher['assignments'];
        final List<dynamic> assignments = (assignmentsRaw is List)
            ? List<dynamic>.from(assignmentsRaw)
            : <dynamic>[];

        final int totalAssignedStudents = assignments.fold<int>(0, (sum, item) {
          if (item is! Map<String, dynamic>) return sum;
          final dynamic count = item['students_count'];
          if (count is int) return sum + count;
          if (count is num) return sum + count.toInt();
          if (count is String) return sum + (int.tryParse(count) ?? 0);
          return sum;
        });

        if (!mounted) return;

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
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    fullNameCtrl.dispose();
    idCtrl.dispose();
    super.dispose();
  }

  Widget _buildRoleToggle({
    required Color tileColor,
    required Color shadowColor,
    required Color titleColor,
    required Color mutedColor,
    required Color selectedBackgroundColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: tileColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => isStudent = true),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isStudent ? selectedBackgroundColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(
                  'I am a Student',
                  style: TextStyle(
                    color: isStudent ? EduTheme.primary : mutedColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => isStudent = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color:
                      !isStudent ? selectedBackgroundColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(
                  'I am a Teacher',
                  style: TextStyle(
                    color: !isStudent ? EduTheme.primary : mutedColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeTile({
    required bool isDarkMode,
    required Color tileColor,
    required Color shadowColor,
    required Color titleColor,
    required Color iconBoxBackground,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: tileColor,
        borderRadius: const BorderRadius.all(Radius.circular(18)),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconBoxBackground,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(Icons.dark_mode_outlined, color: titleColor),
        ),
        title: Text(
          'Dark Mode',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: titleColor,
          ),
        ),
        trailing: Switch(
          value: isDarkMode,
          onChanged: (v) {
            EduLearnApp.of(context).toggleTheme(v);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    final appState = EduLearnApp.of(context);
    final isDarkMode = appState.isDarkMode;

    final Color pageBackground = theme.scaffoldBackgroundColor;
    final Color titleColor = theme.colorScheme.onSurface;
    final Color mutedColor =
        theme.textTheme.bodySmall?.color ??
        (isDarkMode ? EduTheme.darkTextMuted : EduTheme.textMuted);

    final Color tileColor = theme.cardColor;
    final Color tileShadowColor = isDarkMode
        ? Colors.black.withValues(alpha: 0.18)
        : const Color(0x11000000);

    final Color iconBoxBackground =
        isDarkMode ? EduTheme.darkSurface : const Color(0xFFE8F3FF);

    final Color logoBackground =
        isDarkMode ? EduTheme.darkSurface : Colors.white;

    final Color selectedSegmentBackground =
        isDarkMode ? EduTheme.darkSurface : Colors.white;

    return Scaffold(
      backgroundColor: pageBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: size.width * 0.08,
              vertical: 24,
            ),
            child: Form(
              key: _formKey,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),

                    Center(
                      child: Container(
                        width: 78,
                        height: 78,
                        decoration: BoxDecoration(
                          color: logoBackground,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: tileShadowColor,
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.school_rounded,
                          color: EduTheme.primary,
                          size: 34,
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    Text(
                      'Welcome back to EduLearn',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: titleColor,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Log in to continue as a student or teacher',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: mutedColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 28),

                    Text(
                      'Account Type',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: titleColor,
                      ),
                    ),

                    const SizedBox(height: 10),

                    _buildRoleToggle(
                      tileColor: tileColor,
                      shadowColor: tileShadowColor,
                      titleColor: titleColor,
                      mutedColor: mutedColor,
                      selectedBackgroundColor: selectedSegmentBackground,
                    ),

                    const SizedBox(height: 22),

                    Text(
                      'Full Name',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                      ),
                    ),

                    const SizedBox(height: 6),

                    TextFormField(
                      controller: fullNameCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Enter your full name',
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Full name is required';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    Text(
                      isStudent ? 'Student ID' : 'Teacher Code',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                      ),
                    ),

                    const SizedBox(height: 6),

                    TextFormField(
                      controller: idCtrl,
                      decoration: InputDecoration(
                        hintText: isStudent
                            ? 'Enter your student ID'
                            : 'Enter your teacher code',
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return isStudent
                              ? 'Student ID is required'
                              : 'Teacher code is required';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 22),

                    Text(
                      'Theme & Appearance',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: titleColor,
                      ),
                    ),

                    const SizedBox(height: 10),

                    _buildThemeTile(
                      isDarkMode: isDarkMode,
                      tileColor: tileColor,
                      shadowColor: tileShadowColor,
                      titleColor: titleColor,
                      iconBoxBackground: iconBoxBackground,
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _handleLogin,
                        child: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text('Log In'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}