import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../services/auth_service.dart';

class StudentEditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> student;

  const StudentEditProfileScreen({super.key, required this.student});

  @override
  State<StudentEditProfileScreen> createState() => _StudentEditProfileScreenState();
}

class _StudentEditProfileScreenState extends State<StudentEditProfileScreen> {
  late TextEditingController _fullNameCtrl;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _fullNameCtrl = TextEditingController(text: widget.student['full_name']);
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() => isLoading = true);
    try {
      final updatedData = await AuthService.authStudent(
        fullName: _fullNameCtrl.text.trim(),
        academicId: widget.student['academic_id'],
      );
      // تحديث الجلسة
      widget.student.addAll(updatedData['student']);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')));
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
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _fullNameCtrl,
              decoration: const InputDecoration(labelText: 'Full Name'),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: isLoading ? null : _saveProfile,
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