import 'package:flutter/material.dart';
import '../../theme.dart';

// ✅ بدل ApiService
import '../../services/auth_service.dart';

// 👇 بدلنا StudentHomeScreen بـ StudentMainScreen
import '../student/student_main_screen.dart';
import '../teacher/teacher_main_screen.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool isStudent = true;

  final _formKey = GlobalKey<FormState>();

  final TextEditingController fullNameCtrl = TextEditingController();
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController passwordCtrl = TextEditingController();
  final TextEditingController idCtrl = TextEditingController();

  bool obscurePassword = true;
  bool isLoading = false;

  Future<void> _handleCreateAccount() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      if (isStudent) {
        // 👨‍🎓 تدفق الطالب
        final res = await AuthService.authStudent(
          fullName: fullNameCtrl.text.trim(),
          academicId: idCtrl.text.trim(),
          email: emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
          password: passwordCtrl.text.trim().isEmpty
              ? null
              : passwordCtrl.text.trim(),
        );

        final dynamic studentRaw = res['student'];
        if (studentRaw == null || studentRaw is! Map<String, dynamic>) {
          throw Exception('Invalid student response from server');
        }

        final Map<String, dynamic> student =
            Map<String, dynamic>.from(studentRaw);

        final List<dynamic> assignedSubjects =
            (student['assigned_subjects'] as List<dynamic>?) ?? [];

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => StudentMainScreen(
              student: student,
              assignedSubjects: assignedSubjects,
            ),
          ),
        );
      } else {
        // 👨‍🏫 تدفق الأستاذ
        final res = await AuthService.authTeacher(
          fullName: fullNameCtrl.text.trim(),
          teacherCode: idCtrl.text.trim(),
          email: emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
          password: passwordCtrl.text.trim().isEmpty
              ? null
              : passwordCtrl.text.trim(),
        );

        final dynamic teacherRaw = res['teacher'];
        if (teacherRaw == null || teacherRaw is! Map<String, dynamic>) {
          throw Exception('Invalid teacher response from server');
        }

        final Map<String, dynamic> teacher =
            Map<String, dynamic>.from(teacherRaw);

        final dynamic assignmentsRaw = teacher['assignments'];
        final List<dynamic> assignments = (assignmentsRaw is List)
            ? List<dynamic>.from(assignmentsRaw)
            : <dynamic>[];

        final int totalAssignedStudents =
            assignments.fold<int>(0, (sum, item) {
          if (item is! Map<String, dynamic>) return sum;
          final dynamic count = item['students_count'];
          if (count is int) return sum + count;
          if (count is num) return sum + count.toInt();
          if (count is String) {
            final parsed = int.tryParse(count);
            if (parsed != null) return sum + parsed;
          }
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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    fullNameCtrl.dispose();
    emailCtrl.dispose();
    passwordCtrl.dispose();
    idCtrl.dispose();
    super.dispose();
  }

  Widget _buildRoleToggle() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEFF3FB),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => isStudent = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isStudent ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: Text(
                  'I am a Student',
                  style: TextStyle(
                    color: isStudent ? EduTheme.primary : EduTheme.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => isStudent = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: !isStudent ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: Text(
                  'I am a Teacher',
                  style: TextStyle(
                    color: !isStudent ? EduTheme.primary : EduTheme.textMuted,
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: EduTheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: size.width * 0.08,
              vertical: 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      color: EduTheme.primary,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Column(
                    children: [
                      Text(
                        'Join EduLearn',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: EduTheme.primaryDark,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Let's get started with your account.",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: EduTheme.textMuted,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildRoleToggle(),
                const SizedBox(height: 24),
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Full Name'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: fullNameCtrl,
                        decoration: const InputDecoration(
                          hintText: 'e.g., Jane Doe',
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Full name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text('Email Address'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: emailCtrl,
                        decoration: const InputDecoration(
                          hintText: 'you@example.com',
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      const Text('Password'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: passwordCtrl,
                        obscureText: obscurePassword,
                        decoration: InputDecoration(
                          hintText: 'Enter your password',
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: EduTheme.textMuted,
                            ),
                            onPressed: () {
                              setState(
                                  () => obscurePassword = !obscurePassword);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(isStudent ? 'Student ID' : 'Teacher Code'),
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
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _handleCreateAccount,
                          child: isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor:
                                        AlwaysStoppedAnimation(Colors.white),
                                  ),
                                )
                              : const Text('Create Account'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account? ',
                            style: TextStyle(
                              color: EduTheme.textMuted,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const LoginScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              'Log In',
                              style: TextStyle(
                                color: EduTheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
