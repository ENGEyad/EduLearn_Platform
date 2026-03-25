import 'package:flutter/material.dart';
import '../../theme.dart';
import 'ai_tutor_screen.dart';

class StudentHomeScreen extends StatelessWidget {
  final Map<String, dynamic> student;
  final List<dynamic> assignedSubjects;

  const StudentHomeScreen({
    super.key,
    required this.student,
    required this.assignedSubjects,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;

    final String fullName = (student['full_name'] ?? '').toString().trim();
    final String academicId = (student['academic_id'] ?? '').toString().trim();
    final String? imageUrl = student['image'] as String?;
    final int subjectsCount = assignedSubjects.length;

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

    final Color progressBackground =
        isDarkMode ? const Color(0xFF2A3441) : const Color(0xFFE3E7F3);

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
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StudentHeaderCard(
                      fullName: fullName.isEmpty ? 'Student' : fullName,
                      academicId: academicId.isEmpty ? '--' : academicId,
                      imageUrl: imageUrl,
                      subjectsCount: subjectsCount,
                      cardColor: cardColor,
                      titleColor: titleColor,
                      mutedColor: mutedColor,
                      iconBoxColor: iconBoxColor,
                      shadowColor: shadowColor,
                    ),

                    const SizedBox(height: 24),

                    Text(
                      'Overall Progress',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20),
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
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: 0.68,
                                backgroundColor: progressBackground,
                                valueColor: const AlwaysStoppedAnimation(
                                  EduTheme.primary,
                                ),
                                minHeight: 8,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            '68%',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: EduTheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Keep it up, you're doing great!",
                      style: TextStyle(
                        color: mutedColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 24),

                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AITutorScreen(),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(22),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [EduTheme.primary, EduTheme.primaryDark],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: EduTheme.primary.withValues(alpha: 0.28),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.smart_toy_rounded,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Need Help?',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Ask the AI Tutor',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20),
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
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ongoing Lesson',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: mutedColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Chapter 3:\nPhotosynthesis',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: titleColor,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'You are 75% through this lesson.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: mutedColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                            ),
                          ),
                          Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              color: softAccentColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.local_florist,
                              color: EduTheme.primary,
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    Text(
                      'Upcoming Assessments',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _assessmentCard(
                      title: 'Math Quiz 2',
                      subtitle: 'Due: Friday, 11:59 PM',
                      cardColor: cardColor,
                      titleColor: titleColor,
                      mutedColor: mutedColor,
                      iconBoxColor: iconBoxColor,
                      shadowColor: shadowColor,
                    ),
                    const SizedBox(height: 10),
                    _assessmentCard(
                      title: 'History Essay',
                      subtitle: 'Due: Sunday, 8:00 PM',
                      cardColor: cardColor,
                      titleColor: titleColor,
                      mutedColor: mutedColor,
                      iconBoxColor: iconBoxColor,
                      shadowColor: shadowColor,
                    ),

                    const SizedBox(height: 24),

                    Text(
                      'Recommended for you',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _recommendedCard(
                      title: 'Explore: The Roman Empire',
                      subtitle: 'Expand your historical knowledge.',
                      cardColor: cardColor,
                      titleColor: titleColor,
                      mutedColor: mutedColor,
                      previewColor: softAccentColor,
                      shadowColor: shadowColor,
                    ),
                    const SizedBox(height: 12),
                    _recommendedCard(
                      title: 'Practice: Advanced Algebra',
                      subtitle: 'Struggling with Algebra? Try this.',
                      cardColor: cardColor,
                      titleColor: titleColor,
                      mutedColor: mutedColor,
                      previewColor: softAccentColor,
                      shadowColor: shadowColor,
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _assessmentCard({
    required String title,
    required String subtitle,
    required Color cardColor,
    required Color titleColor,
    required Color mutedColor,
    required Color iconBoxColor,
    required Color shadowColor,
  }) {
    return Container(
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
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconBoxColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.assignment_rounded,
              color: EduTheme.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
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

  static Widget _recommendedCard({
    required String title,
    required String subtitle,
    required Color cardColor,
    required Color titleColor,
    required Color mutedColor,
    required Color previewColor,
    required Color shadowColor,
  }) {
    return Container(
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
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: previewColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Icon(
                Icons.auto_stories_rounded,
                color: EduTheme.primary,
                size: 34,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: mutedColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentHeaderCard extends StatelessWidget {
  final String fullName;
  final String academicId;
  final String? imageUrl;
  final int subjectsCount;
  final Color cardColor;
  final Color titleColor;
  final Color mutedColor;
  final Color iconBoxColor;
  final Color shadowColor;

  const _StudentHeaderCard({
    required this.fullName,
    required this.academicId,
    required this.imageUrl,
    required this.subjectsCount,
    required this.cardColor,
    required this.titleColor,
    required this.mutedColor,
    required this.iconBoxColor,
    required this.shadowColor,
  });

  @override
  Widget build(BuildContext context) {
    final ImageProvider avatarProvider =
        imageUrl != null && imageUrl!.isNotEmpty
        ? NetworkImage(imageUrl!)
        : const AssetImage('assets/avatar_placeholder.png');

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
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, $fullName',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ready to continue learning today?',
                      style: TextStyle(
                        color: mutedColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBoxColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: IconButton(
                  onPressed: () {},
                  icon: Icon(
                    Icons.notifications_none_rounded,
                    color: titleColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _InfoChip(
                  icon: Icons.badge_outlined,
                  label: 'Academic ID',
                  value: academicId,
                  iconBoxColor: iconBoxColor,
                  titleColor: titleColor,
                  mutedColor: mutedColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InfoChip(
                  icon: Icons.menu_book_rounded,
                  label: 'Subjects',
                  value: '$subjectsCount',
                  iconBoxColor: iconBoxColor,
                  titleColor: titleColor,
                  mutedColor: mutedColor,
                ),
              ),
            ],
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