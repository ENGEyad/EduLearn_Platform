import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../services/auth_service.dart';

class StudentChangePasswordScreen extends StatefulWidget {
  final Map<String, dynamic> student;

  const StudentChangePasswordScreen({super.key, required this.student});

  @override
  State<StudentChangePasswordScreen> createState() => _StudentChangePasswordScreenState();
}

class _StudentChangePasswordScreenState extends State<StudentChangePasswordScreen> {
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
      final updatedData = await AuthService.authStudent(
        fullName: widget.student['full_name'],
        academicId: widget.student['academic_id'],
        password: _passwordCtrl.text.trim(),
      );
      widget.student.addAll(updatedData['student']);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password updated successfully')));
      Navigator.pop(context, widget.student);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
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