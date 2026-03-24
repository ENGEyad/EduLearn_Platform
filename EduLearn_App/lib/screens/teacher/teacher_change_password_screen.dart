import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class TeacherChangePasswordScreen extends StatefulWidget {
  final Map<String, dynamic> teacher;

  const TeacherChangePasswordScreen({super.key, required this.teacher});

  @override
  State<TeacherChangePasswordScreen> createState() => _TeacherChangePasswordScreenState();
}

class _TeacherChangePasswordScreenState extends State<TeacherChangePasswordScreen> {
  final TextEditingController _passwordCtrl = TextEditingController();
  bool isLoading = false;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    if (_passwordCtrl.text.trim().isEmpty) return;
    setState(() => isLoading = true);
    try {
      final updatedData = await AuthService.authTeacher(
        fullName: widget.teacher['full_name'],
        teacherCode: widget.teacher['teacher_code'],
        password: _passwordCtrl.text.trim(),
      );
      widget.teacher.addAll(updatedData['teacher']);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Password updated successfully')));
      Navigator.pop(context, widget.teacher);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change Password')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _passwordCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New Password'),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: isLoading ? null : _updatePassword,
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}