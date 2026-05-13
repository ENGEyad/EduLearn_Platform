part of 'student_subjects_screen.dart';

class _StudentSubjectItem {
  final int subjectId;
  final String subjectName;
  final String teacherName;
  final String? teacherImage;
  final IconData icon;

  const _StudentSubjectItem({
    required this.subjectId,
    required this.subjectName,
    required this.teacherName,
    required this.teacherImage,
    required this.icon,
  });

  static _StudentSubjectItem? fromMap(Map<String, dynamic> map) {
    final String subjectName = (map['subject_name'] ?? '').toString().trim();
    if (subjectName.isEmpty) return null;

    final dynamic rawSubjectId = map['subject_id'];
    int? subjectId;

    if (rawSubjectId is int) {
      subjectId = rawSubjectId;
    } else if (rawSubjectId is String) {
      subjectId = int.tryParse(rawSubjectId);
    }

    if (subjectId == null) return null;

    final String teacherName = (map['teacher_name'] ?? '').toString().trim();
    final String? teacherImage = map['teacher_image'] as String?;

    return _StudentSubjectItem(
      subjectId: subjectId,
      subjectName: subjectName,
      teacherName: teacherName,
      teacherImage: teacherImage,
      icon: _subjectIconForName(subjectName),
    );
  }

  static IconData _subjectIconForName(String subjectName) {
    switch (subjectName) {
      case 'Quran':
        return Icons.menu_book_rounded;
      case 'Islamic Education':
        return Icons.account_balance_rounded;
      case 'Arabic Language':
        return Icons.language_rounded;
      case 'English Language':
        return Icons.translate_rounded;
      case 'Science':
        return Icons.science_rounded;
      case 'Mathematics':
        return Icons.calculate_rounded;
      case 'Social Studies':
        return Icons.public_rounded;
      case 'Chemistry':
        return Icons.biotech_rounded;
      case 'Physics':
        return Icons.bolt_rounded;
      case 'Biology':
        return Icons.eco_rounded;
      case 'Calculus':
        return Icons.functions_rounded;
      case 'Algebra and Geometry':
        return Icons.square_foot_rounded;
      case 'Geography':
        return Icons.map_rounded;
      case 'History':
        return Icons.history_edu_rounded;
      case 'National Education':
        return Icons.flag_rounded;
      default:
        return Icons.menu_book_rounded;
    }
  }
}