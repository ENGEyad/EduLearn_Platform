import 'package:flutter/material.dart';
import '../../theme.dart';
<<<<<<< HEAD
import '../../services/api_service.dart';

=======

// ✅ بدل ApiService
import '../../services/auth_service.dart';

// 👇 بدلنا StudentHomeScreen بـ StudentMainScreen
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
import '../student/student_main_screen.dart';
import '../teacher/teacher_main_screen.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  bool isStudent = true;

  final _formKey = GlobalKey<FormState>();

  final TextEditingController fullNameCtrl = TextEditingController();
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController passwordCtrl = TextEditingController();
  final TextEditingController idCtrl = TextEditingController();

  bool obscurePassword = true;
  bool isLoading = false;

<<<<<<< HEAD
  late AnimationController _tabAnimCtrl;
  late Animation<double> _tabIndicatorAnim;

  @override
  void initState() {
    super.initState();
    _tabAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _tabIndicatorAnim = CurvedAnimation(
      parent: _tabAnimCtrl,
      curve: Curves.easeInOut,
    );
=======
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
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
  }

  @override
  void dispose() {
    fullNameCtrl.dispose();
    emailCtrl.dispose();
    passwordCtrl.dispose();
    idCtrl.dispose();
    _tabAnimCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleCreateAccount() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);

    try {
      if (isStudent) {
        final res = await ApiService.authStudent(
          fullName: fullNameCtrl.text.trim(),
          academicId: idCtrl.text.trim(),
          email:
              emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
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
        final res = await ApiService.authTeacher(
          fullName: fullNameCtrl.text.trim(),
          teacherCode: idCtrl.text.trim(),
          email:
              emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: EduTheme.accentWarm,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Widget _buildRoleToggle() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFFEBF0FB),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _roleTab(
            label: 'Student',
            icon: Icons.school_rounded,
            selected: isStudent,
            onTap: () => setState(() => isStudent = true),
          ),
          _roleTab(
            label: 'Teacher',
            icon: Icons.psychology_rounded,
            selected: !isStudent,
            onTap: () => setState(() => isStudent = false),
          ),
        ],
      ),
    );
  }

  Widget _roleTab({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: EduTheme.primary.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? EduTheme.primary : EduTheme.textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? EduTheme.primary : EduTheme.textMuted,
                  fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: EduTheme.textMuted, size: 20),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: EduTheme.background,
      body: Column(
        children: [
          // ── Gradient Hero Header ──────────────────────────────────────────
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: EduTheme.heroGradient,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(36),
                bottomRight: Radius.circular(36),
              ),
            ),
<<<<<<< HEAD
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 2),
                      ),
                      child: const Icon(
                        Icons.school_rounded,
                        color: Colors.white,
                        size: 34,
                      ),
=======
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
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Join EduLearn',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Let's get started with your account.",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.75),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildRoleToggle(),
                    const SizedBox(height: 8),
                  ],
                ),
<<<<<<< HEAD
              ),
=======
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
>>>>>>> 6a86bc1197f81540b5d636365760ead1205a1492
            ),
          ),

          // ── Form ─────────────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: size.width * 0.07,
                vertical: 24,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _fieldLabel('Full Name'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: fullNameCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration:
                          _fieldDecoration('e.g., Jane Doe', Icons.person_outline_rounded),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Full name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _fieldLabel('Email Address'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: emailCtrl,
                      decoration: _fieldDecoration(
                          'you@example.com', Icons.email_outlined),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    _fieldLabel('Password'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: passwordCtrl,
                      obscureText: obscurePassword,
                      decoration: InputDecoration(
                        hintText: 'Enter your password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded,
                            color: EduTheme.textMuted, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: EduTheme.textMuted,
                            size: 20,
                          ),
                          onPressed: () => setState(
                              () => obscurePassword = !obscurePassword),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _fieldLabel(isStudent ? 'Student ID' : 'Teacher Code'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: idCtrl,
                      decoration: _fieldDecoration(
                        isStudent
                            ? 'Enter your student ID'
                            : 'Enter your teacher code',
                        isStudent
                            ? Icons.badge_outlined
                            : Icons.key_outlined,
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
                    const SizedBox(height: 28),
                    // CTA Button
                    _GradientButton(
                      label: 'Create Account',
                      isLoading: isLoading,
                      onPressed: isLoading ? null : _handleCreateAccount,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: TextStyle(
                            color: EduTheme.textMuted,
                            fontSize: 14,
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
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 13,
        color: EduTheme.primaryDark,
      ),
    );
  }
}

// ── Shared Gradient CTA Button ────────────────────────────────────────────────
class _GradientButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _GradientButton({
    required this.label,
    required this.isLoading,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 54,
        decoration: BoxDecoration(
          gradient: onPressed != null
              ? EduTheme.primaryGradient
              : const LinearGradient(
                  colors: [Color(0xFFB0BEC5), Color(0xFFB0BEC5)]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: onPressed != null
              ? EduTheme.elevatedShadow
              : [],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    letterSpacing: 0.5,
                  ),
                ),
        ),
      ),
    );
  }
}
