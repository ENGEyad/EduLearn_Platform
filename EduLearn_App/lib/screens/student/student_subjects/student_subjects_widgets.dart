part of 'student_subjects_screen.dart';

class _SubjectsLoadingView extends StatelessWidget {
  const _SubjectsLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}

class _SubjectsEmptyView extends StatelessWidget {
  final Color mutedColor;
  final String message;

  const _SubjectsEmptyView({
    required this.mutedColor,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 120),
        Center(
          child: Text(
            message,
            style: TextStyle(
              color: mutedColor,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

class _SubjectGridCard extends StatelessWidget {
  final _StudentSubjectItem item;
  final Color cardColor;
  final Color titleColor;
  final Color mutedColor;
  final Color shadowColor;
  final VoidCallback onTap;

  const _SubjectGridCard({
    required this.item,
    required this.cardColor,
    required this.titleColor,
    required this.mutedColor,
    required this.shadowColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              item.icon,
              color: EduTheme.primary,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              item.subjectName,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 4),
            if (item.teacherName.isNotEmpty)
              Text(
                item.teacherName,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: mutedColor,
                ),
              ),
          ],
        ),
      ),
    );
  }
}