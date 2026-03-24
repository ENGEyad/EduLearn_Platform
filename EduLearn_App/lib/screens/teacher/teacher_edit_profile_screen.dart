import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../services/auth_service.dart';

class TeacherEditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> teacher;

  const TeacherEditProfileScreen({super.key, required this.teacher});

  @override
  State<TeacherEditProfileScreen> createState() => _TeacherEditProfileScreenState();
}

class _TeacherEditProfileScreenState extends State<TeacherEditProfileScreen> {
  late TextEditingController _fullNameCtrl;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _fullNameCtrl = TextEditingController(text: widget.teacher['full_name']);
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() => isLoading = true);
    try {
      final updatedData = await AuthService.authTeacher(
        fullName: _fullNameCtrl.text.trim(),
        teacherCode: widget.teacher['teacher_code'],
      );
      widget.teacher.addAll(updatedData['teacher']);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Profile updated successfully')));
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