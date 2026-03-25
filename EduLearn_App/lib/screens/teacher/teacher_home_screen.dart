import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../theme.dart';
import 'teacher_classes_screen.dart';
import 'teacher_report_screen.dart';
import '../../services/ai_service.dart';

class TeacherHomeScreen extends StatelessWidget {
  final Map<String, dynamic> teacher;
  final List<dynamic> assignments;
  final int totalAssignedStudents;

  const TeacherHomeScreen({
    super.key,
    required this.teacher,
    required this.assignments,
    required this.totalAssignedStudents,
  });

  String get fullName => (teacher['full_name'] ?? '').toString();
  String get teacherCode => (teacher['teacher_code'] ?? '').toString();
  String? get imageUrl => teacher['image'] as String?;

  String get _firstName {
    final parts = fullName.trim().split(' ').where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return fullName;
    return parts.first;
  }

  int _calculateActiveClasses(List<dynamic> assignments) {
    final Set<String> uniqueClasses = {};

    for (final item in assignments) {
      if (item is Map<String, dynamic>) {
        final grade = (item['class_grade'] ?? '').toString();
        final section = (item['class_section'] ?? '').toString();

        if (grade.isNotEmpty || section.isNotEmpty) {
          uniqueClasses.add('$grade-$section');
        }
      }
    }

    return uniqueClasses.length;
  }

  void _openClassesFromQuickAccess(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TeacherClassesScreen(
          teacher: teacher,
          assignments: assignments,
          totalAssignedStudents: totalAssignedStudents,
        ),
      ),
    );
  }

  void _openPerformanceReports(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TeacherReportScreen(
          teacher: teacher,
          totalStudents: totalAssignedStudents,
        ),
      ),
    );
  }

  Future<void> _uploadMaterial(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.isNotEmpty) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Uploading PDF to AI...')),
        );

        final response = await AIService.uploadPDF(result.files.first);

        if (!context.mounted) return;
        if (response != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'AI Extraction Success: ${response['total_chunks']} chunks created!',
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to upload PDF to AI Server'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;
    final int activeClasses = _calculateActiveClasses(assignments);

    final Color pageBackground = theme.scaffoldBackgroundColor;
    final Color cardColor = theme.cardColor;
    final Color titleColor = theme.colorScheme.onSurface;
    final Color mutedColor =
        theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.72) ??
        (isDarkMode ? EduTheme.darkTextMuted : EduTheme.textMuted);

    final Color iconBoxColor =
        isDarkMode ? EduTheme.darkSurface : const Color(0xFFE8F3FF);

    final Color softAccentColor =
        isDarkMode ? const Color(0xFF1E2A3A) : const Color(0xFFF4F7FC);

    final Color shadowColor = isDarkMode
        ? Colors.black.withValues(alpha: 0.18)
        : const Color(0x11000000);

    return Scaffold(
      backgroundColor: pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TeacherHeaderCard(
                      fullName: fullName.isEmpty ? 'Teacher' : fullName,
                      firstName: _firstName.isEmpty ? 'Teacher' : _firstName,
                      teacherCode: teacherCode.isEmpty ? '--' : teacherCode,
                      imageUrl: imageUrl,
                      activeClasses: activeClasses,
                      totalStudents: totalAssignedStudents,
                      cardColor: cardColor,
                      titleColor: titleColor,
                      mutedColor: mutedColor,
                      iconBoxColor: iconBoxColor,
                      shadowColor: shadowColor,
                    ),

                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            title: 'Lessons Created',
                            value: '24',
                            cardColor: cardColor,
                            titleColor: titleColor,
                            mutedColor: mutedColor,
                            shadowColor: shadowColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            title: 'Active Classes',
                            value: activeClasses.toString(),
                            cardColor: cardColor,
                            titleColor: titleColor,
                            mutedColor: mutedColor,
                            shadowColor: shadowColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            title: 'Total Students',
                            value: totalAssignedStudents.toString(),
                            cardColor: cardColor,
                            titleColor: titleColor,
                            mutedColor: mutedColor,
                            shadowColor: shadowColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            title: 'Pending Tasks',
                            value: '8',
                            cardColor: cardColor,
                            titleColor: titleColor,
                            mutedColor: mutedColor,
                            shadowColor: shadowColor,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    Text(
                      'Quick Access',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 12),

                    _QuickActionCard(
                      title: 'Upload AI Material',
                      subtitle: 'Add a PDF for the AI Tutor',
                      icon: Icons.smart_toy_outlined,
                      onTap: () => _uploadMaterial(context),
                      cardColor: cardColor,
                      titleColor: titleColor,
                      mutedColor: mutedColor,
                      iconBoxColor: iconBoxColor,
                      shadowColor: shadowColor,
                    ),
                    const SizedBox(height: 10),
                    _QuickActionCard(
                      title: 'View All Classes',
                      subtitle: 'Manage your class rosters and schedules',
                      icon: Icons.school_outlined,
                      onTap: () => _openClassesFromQuickAccess(context),
                      cardColor: cardColor,
                      titleColor: titleColor,
                      mutedColor: mutedColor,
                      iconBoxColor: iconBoxColor,
                      shadowColor: shadowColor,
                    ),
                    const SizedBox(height: 10),
                    _QuickActionCard(
                      title: 'Check Performance',
                      subtitle: 'Review student progress and analytics',
                      icon: Icons.show_chart_rounded,
                      onTap: () => _openPerformanceReports(context),
                      cardColor: cardColor,
                      titleColor: titleColor,
                      mutedColor: mutedColor,
                      iconBoxColor: iconBoxColor,
                      shadowColor: shadowColor,
                    ),

                    const SizedBox(height: 28),

                    Text(
                      "What's New",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 12),

                    _WhatsNewItem(
                      icon: Icons.help_outline_rounded,
                      title: "Alex Morgan asked a question in 'Algebra II'",
                      time: '2 hours ago',
                      cardColor: cardColor,
                      titleColor: titleColor,
                      mutedColor: mutedColor,
                      iconBoxColor: iconBoxColor,
                      shadowColor: shadowColor,
                    ),
                    const SizedBox(height: 10),
                    _WhatsNewItem(
                      icon: Icons.assignment_turned_in_outlined,
                      title: '5 new assignments submitted for grading',
                      time: '8 hours ago',
                      cardColor: cardColor,
                      titleColor: titleColor,
                      mutedColor: mutedColor,
                      iconBoxColor: iconBoxColor,
                      shadowColor: shadowColor,
                    ),
                    const SizedBox(height: 10),
                    _WhatsNewItem(
                      icon: Icons.check_circle_outline_rounded,
                      title: "Reminder: 'Chapter 5 Quiz' is due tomorrow",
                      time: 'Yesterday',
                      cardColor: cardColor,
                      titleColor: titleColor,
                      mutedColor: mutedColor,
                      iconBoxColor: iconBoxColor,
                      shadowColor: shadowColor,
                    ),

                    const SizedBox(height: 18),

                    Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: shadowColor,
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 62,
                            height: 62,
                            decoration: BoxDecoration(
                              color: softAccentColor,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(
                              Icons.auto_graph_rounded,
                              color: EduTheme.primary,
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Today’s focus',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: mutedColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Track class engagement and follow up on pending reviews.',
                                  style: TextStyle(
                                    color: titleColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeacherHeaderCard extends StatelessWidget {
  final String fullName;
  final String firstName;
  final String teacherCode;
  final String? imageUrl;
  final int activeClasses;
  final int totalStudents;
  final Color cardColor;
  final Color titleColor;
  final Color mutedColor;
  final Color iconBoxColor;
  final Color shadowColor;

  const _TeacherHeaderCard({
    required this.fullName,
    required this.firstName,
    required this.teacherCode,
    required this.imageUrl,
    required this.activeClasses,
    required this.totalStudents,
    required this.cardColor,
    required this.titleColor,
    required this.mutedColor,
    required this.iconBoxColor,
    required this.shadowColor,
  });

  @override
  Widget build(BuildContext context) {
    final ImageProvider? avatarProvider =
        imageUrl != null && imageUrl!.isNotEmpty ? NetworkImage(imageUrl!) : null;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: iconBoxColor,
                backgroundImage: avatarProvider,
                child: avatarProvider == null
                    ? Text(
                        firstName.isNotEmpty ? firstName[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: titleColor,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back, $firstName',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      fullName,
                      style: TextStyle(
                        color: mutedColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: iconBoxColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.notifications_none_rounded,
                      color: titleColor,
                      size: 22,
                    ),
                  ),
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: cardColor,
                          width: 2,
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          '3',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _InfoChip(
                  icon: Icons.badge_outlined,
                  label: 'Teacher Code',
                  value: teacherCode,
                  iconBoxColor: iconBoxColor,
                  titleColor: titleColor,
                  mutedColor: mutedColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InfoChip(
                  icon: Icons.group_work_outlined,
                  label: 'Classes',
                  value: '$activeClasses',
                  iconBoxColor: iconBoxColor,
                  titleColor: titleColor,
                  mutedColor: mutedColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _WideInfoChip(
            icon: Icons.groups_2_outlined,
            label: 'Assigned Students',
            value: '$totalStudents',
            iconBoxColor: iconBoxColor,
            titleColor: titleColor,
            mutedColor: mutedColor,
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconBoxColor;
  final Color titleColor;
  final Color mutedColor;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconBoxColor,
    required this.titleColor,
    required this.mutedColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: iconBoxColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: EduTheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: mutedColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: titleColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WideInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconBoxColor;
  final Color titleColor;
  final Color mutedColor;

  const _WideInfoChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconBoxColor,
    required this.titleColor,
    required this.mutedColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: iconBoxColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: EduTheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: mutedColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    color: titleColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color cardColor;
  final Color titleColor;
  final Color mutedColor;
  final Color shadowColor;

  const _StatCard({
    required this.title,
    required this.value,
    required this.cardColor,
    required this.titleColor,
    required this.mutedColor,
    required this.shadowColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: mutedColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: EduTheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  final Color cardColor;
  final Color titleColor;
  final Color mutedColor;
  final Color iconBoxColor;
  final Color shadowColor;

  const _QuickActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
    required this.cardColor,
    required this.titleColor,
    required this.mutedColor,
    required this.iconBoxColor,
    required this.shadowColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: mutedColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconBoxColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: EduTheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WhatsNewItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String time;
  final Color cardColor;
  final Color titleColor;
  final Color mutedColor;
  final Color iconBoxColor;
  final Color shadowColor;

  const _WhatsNewItem({
    required this.icon,
    required this.title,
    required this.time,
    required this.cardColor,
    required this.titleColor,
    required this.mutedColor,
    required this.iconBoxColor,
    required this.shadowColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconBoxColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: EduTheme.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: titleColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: mutedColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}