import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../services/api_service.dart';
import '../student/student_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController fullNameCtrl = TextEditingController();
  final TextEditingController idCtrl = TextEditingController();

  bool isLoading = false;

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final res = await AuthService.authStudent(
        fullName: fullNameCtrl.text.trim(),
        academicId: idCtrl.text.trim(),
      );

      final Map<String, dynamic> student =
          (res['student'] as Map<String, dynamic>);

      // 👇 قراءة قائمة المواد المعينة من الـ JSON (assigned_subjects)
      final List<dynamic> assignedSubjects =
          (student['assigned_subjects'] as List<dynamic>?) ?? [];

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => StudentHomeScreen(
            student: student,
            assignedSubjects: assignedSubjects,
          ),
        ),
      );
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
    idCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: EduTheme.background,
      appBar: AppBar(
        title: const Text('Log In'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: size.width * 0.08,
              vertical: 24,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  Text(
                    'Welcome back to EduLearn',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: EduTheme.primaryDark,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  const Text('Full Name'),
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
                  const Text('Student ID'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: idCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Enter your student ID',
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Student ID is required';
                      }
                      return null;
                    },
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
                                valueColor:
                                    AlwaysStoppedAnimation(Colors.white),
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
    );
  }
}
