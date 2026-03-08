import 'package:flutter/material.dart';
import '../../theme.dart';
import 'ai_tutor_screen.dart';

class StudentHomeScreen extends StatelessWidget {
  final Map<String, dynamic> student;          // 👈 بيانات الطالب من الـ API
  final List<dynamic> assignedSubjects;        // 👈 قائمة المواد من الـ API

  const StudentHomeScreen({
    super.key,
    required this.student,
    required this.assignedSubjects,
  });

  @override
  Widget build(BuildContext context) {
    // قراءة البيانات من الـ Map القادمة من الـ API
    final String fullName = (student['full_name'] ?? '').toString();
    final String academicId = (student['academic_id'] ?? '').toString();
    final String? imageUrl = student['image'] as String?;

    return Scaffold(
      backgroundColor: EduTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // المحتوى قابل للسكرول
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // الهيدر
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.white,
                          backgroundImage:
                              (imageUrl != null && imageUrl.isNotEmpty)
                                  ? NetworkImage(imageUrl)
                                  : const AssetImage(
                                      'assets/avatar_placeholder.png',
                                    ) as ImageProvider,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hello, $fullName!',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: EduTheme.primaryDark,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'ID: $academicId',
                                style: const TextStyle(
                                  color: EduTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.notifications_none_rounded),
                          color: EduTheme.primaryDark,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Overall Progress
                    const Text(
                      'Overall Progress',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: EduTheme.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: const [
                        Expanded(
                          child: LinearProgressIndicator(
                            value: 0.68,
                            backgroundColor: Color(0xFFE3E7F3),
                            minHeight: 6,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          '68%',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: EduTheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Keep it up, you're doing great!",
                      style: TextStyle(
                        color: EduTheme.textMuted,
                        fontSize: 12,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // AI Tutor Card
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AITutorScreen()),
                        );
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [EduTheme.primary, EduTheme.primaryDark],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: EduTheme.primary.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.smart_toy_rounded,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'Need Help?',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
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

                    // بطاقة الدرس الحالي (ثابتة الآن كمثال)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Ongoing Lesson',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: EduTheme.textMuted,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Chapter 3:\nPhotosynthesis',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: EduTheme.primaryDark,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'You are 75% through this lesson.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: EduTheme.textMuted,
                                  ),
                                ),
                                SizedBox(height: 12),
                              ],
                            ),
                          ),
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE5F5F5),
                              borderRadius: BorderRadius.circular(18),
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

                    const Text(
                      'Upcoming Assessments',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: EduTheme.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _assessmentCard(
                      title: 'Math Quiz 2',
                      subtitle: 'Due: Friday, 11:59 PM',
                    ),
                    const SizedBox(height: 8),
                    _assessmentCard(
                      title: 'History Essay',
                      subtitle: 'Due: Sunday, 8:00 PM',
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      'Recommended for you',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: EduTheme.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _recommendedCard(
                      title: 'Explore: The Roman Empire',
                      subtitle: 'Expand your historical knowledge.',
                    ),
                    const SizedBox(height: 12),
                    _recommendedCard(
                      title: 'Practice: Advanced Algebra',
                      subtitle: 'Struggling with Algebra? Try this.',
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
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFE5F2FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.assignment_rounded,
              color: EduTheme.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: EduTheme.primaryDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: EduTheme.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _recommendedCard({
    required String title,
    required String subtitle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E9F6),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: EduTheme.primaryDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: EduTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
