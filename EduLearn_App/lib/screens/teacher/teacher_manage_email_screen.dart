import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class TeacherManageEmailScreen extends StatefulWidget {
  final Map<String, dynamic> teacher;

  const TeacherManageEmailScreen({super.key, required this.teacher});

  @override
  State<TeacherManageEmailScreen> createState() => _TeacherManageEmailScreenState();
}

class _TeacherManageEmailScreenState extends State<TeacherManageEmailScreen> {
  late TextEditingController _emailCtrl;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(text: widget.teacher['email']);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _updateEmail() async {
    setState(() => isLoading = true);
    try {
      final updatedData = await AuthService.authTeacher(
        fullName: widget.teacher['full_name'],
        teacherCode: widget.teacher['teacher_code'],
        email: _emailCtrl.text.trim(),
      );
      widget.teacher.addAll(updatedData['teacher']);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Email updated successfully')));
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
      appBar: AppBar(title: const Text('Manage Email')),
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