import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../services/auth_service.dart';

class StudentManageEmailScreen extends StatefulWidget {
  final Map<String, dynamic> student;

  const StudentManageEmailScreen({super.key, required this.student});

  @override
  State<StudentManageEmailScreen> createState() => _StudentChangeEmailScreenState();
}

class _StudentChangeEmailScreenState extends State<StudentManageEmailScreen> {
  late TextEditingController _emailCtrl;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(text: widget.student['email']);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _updateEmail() async {
    setState(() => isLoading = true);
    try {
      final updatedData = await AuthService.authStudent(
        fullName: widget.student['full_name'],
        academicId: widget.student['academic_id'],
        email: _emailCtrl.text.trim(),
      );
      widget.student.addAll(updatedData['student']);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email updated successfully')));
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
      appBar: AppBar(title: const Text('Change Email')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: isLoading ? null : _updateEmail,
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