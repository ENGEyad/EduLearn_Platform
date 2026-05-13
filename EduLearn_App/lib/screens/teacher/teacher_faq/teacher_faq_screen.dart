import 'package:flutter/material.dart';

import '../../../l10n/core/app_localizations.dart';
import '../../../l10n/getters/teacher/teacher_faq_l10n.dart';
import '../../../theme.dart';

class TeacherFaqScreen extends StatefulWidget {
  final String teacherName;
  final String teacherCode;

  const TeacherFaqScreen({
    super.key,
    required this.teacherName,
    required this.teacherCode,
  });

  @override
  State<TeacherFaqScreen> createState() => _TeacherFaqScreenState();
}

class _TeacherFaqScreenState extends State<TeacherFaqScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String _selectedCategory = 'all';

  List<_FaqItem> _faqItems(AppLocalizations l10n) {
    return [
      _FaqItem(
        categoryKey: 'lessons',
        category: l10n.teacherFaqCategoryLessons,
        question: l10n.teacherFaqQCreateLesson,
        answer: l10n.teacherFaqACreateLesson,
        steps: [
          l10n.teacherFaqStepCreateLesson1,
          l10n.teacherFaqStepCreateLesson2,
          l10n.teacherFaqStepCreateLesson3,
          l10n.teacherFaqStepCreateLesson4,
          l10n.teacherFaqStepCreateLesson5,
        ],
      ),
      _FaqItem(
        categoryKey: 'exercises',
        category: l10n.teacherFaqCategoryExercises,
        question: l10n.teacherFaqQAddExercise,
        answer: l10n.teacherFaqAAddExercise,
        steps: [
          l10n.teacherFaqStepAddExercise1,
          l10n.teacherFaqStepAddExercise2,
          l10n.teacherFaqStepAddExercise3,
          l10n.teacherFaqStepAddExercise4,
          l10n.teacherFaqStepAddExercise5,
        ],
      ),
      _FaqItem(
        categoryKey: 'profile',
        category: l10n.teacherFaqCategoryProfile,
        question: l10n.teacherFaqQEditProfile,
        answer: l10n.teacherFaqAEditProfile,
        steps: [
          l10n.teacherFaqStepEditProfile1,
          l10n.teacherFaqStepEditProfile2,
          l10n.teacherFaqStepEditProfile3,
          l10n.teacherFaqStepEditProfile4,
        ],
      ),
      _FaqItem(
        categoryKey: 'account',
        category: l10n.teacherFaqCategoryAccount,
        question: l10n.teacherFaqQChangePassword,
        answer: l10n.teacherFaqAChangePassword,
        steps: [
          l10n.teacherFaqStepChangePassword1,
          l10n.teacherFaqStepChangePassword2,
          l10n.teacherFaqStepChangePassword3,
          l10n.teacherFaqStepChangePassword4,
          l10n.teacherFaqStepChangePassword5,
        ],
      ),
      _FaqItem(
        categoryKey: 'visibility',
        category: l10n.teacherFaqCategoryVisibility,
        question: l10n.teacherFaqQLessonsNotShowing,
        answer: l10n.teacherFaqALessonsNotShowing,
        steps: [
          l10n.teacherFaqStepLessonsNotShowing1,
          l10n.teacherFaqStepLessonsNotShowing2,
          l10n.teacherFaqStepLessonsNotShowing3,
          l10n.teacherFaqStepLessonsNotShowing4,
        ],
      ),
      _FaqItem(
        categoryKey: 'support',
        category: l10n.teacherFaqCategorySupport,
        question: l10n.teacherFaqQContactSupport,
        answer: l10n.teacherFaqAContactSupport,
        steps: [
          l10n.teacherFaqStepContactSupport1,
          l10n.teacherFaqStepContactSupport2,
          l10n.teacherFaqStepContactSupport3,
          l10n.teacherFaqStepContactSupport4,
        ],
      ),
    ];
  }

  List<_FaqCategoryItem> _categories(AppLocalizations l10n) {
    return [
      _FaqCategoryItem(key: 'all', label: l10n.teacherFaqCategoryAll),
      _FaqCategoryItem(key: 'lessons', label: l10n.teacherFaqCategoryLessons),
      _FaqCategoryItem(key: 'exercises', label: l10n.teacherFaqCategoryExercises),
      _FaqCategoryItem(key: 'profile', label: l10n.teacherFaqCategoryProfile),
      _FaqCategoryItem(key: 'account', label: l10n.teacherFaqCategoryAccount),
      _FaqCategoryItem(key: 'visibility', label: l10n.teacherFaqCategoryVisibility),
      _FaqCategoryItem(key: 'support', label: l10n.teacherFaqCategorySupport),
    ];
  }

  List<_FaqItem> _filteredItems(AppLocalizations l10n) {
    final items = _faqItems(l10n);
    return items.where((item) {
      final categoryMatch = _selectedCategory == 'all' || item.categoryKey == _selectedCategory;
      final normalizedQuery = _query.trim().toLowerCase();
      final queryMatch = normalizedQuery.isEmpty ||
          item.question.toLowerCase().contains(normalizedQuery) ||
          item.answer.toLowerCase().contains(normalizedQuery) ||
          item.category.toLowerCase().contains(normalizedQuery);
      return categoryMatch && queryMatch;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color borderColor = theme.dividerColor.withValues(alpha: isDark ? 0.26 : 0.55);
    final categories = _categories(l10n);
    final filteredItems = _filteredItems(l10n);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.teacherFaqTitle)),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          MediaQuery.of(context).padding.bottom + 28,
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: borderColor),
              boxShadow: EduTheme.subtleShadow(isDark),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.teacherFaqIntroTitle,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.teacherFaqIntroSubtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: l10n.teacherFaqSearchHint,
                    prefixIcon: const Icon(Icons.search_rounded),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = category.key == _selectedCategory;
                return ChoiceChip(
                  label: Text(category.label),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedCategory = category.key),
                );
              },
            ),
          ),
          const SizedBox(height: 18),
          if (filteredItems.isEmpty)
            _EmptyFaqState(query: _query)
          else
            ...filteredItems.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _FaqExpandableCard(item: item),
                )),
        ],
      ),
    );
  }
}

class _FaqExpandableCard extends StatelessWidget {
  final _FaqItem item;

  const _FaqExpandableCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final borderColor = theme.dividerColor.withValues(alpha: isDark ? 0.26 : 0.55);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor),
        boxShadow: EduTheme.subtleShadow(isDark),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.help_outline_rounded, color: theme.colorScheme.primary),
          ),
          title: Text(
            item.question,
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              item.category,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                item.answer,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
              ),
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.teacherFaqSuggestedSteps,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 10),
            ...List.generate(item.steps.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${index + 1}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          item.steps[index],
                          style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _EmptyFaqState extends StatelessWidget {
  final String query;

  const _EmptyFaqState({required this.query});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: EduTheme.subtleShadow(isDark),
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(Icons.search_off_rounded, color: theme.colorScheme.primary, size: 28),
          ),
          const SizedBox(height: 14),
          Text(
            l10n.teacherFaqNoResults,
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            query.trim().isEmpty
                ? l10n.teacherFaqTryAnotherCategory
                : l10n.teacherFaqNoMatch(query),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _FaqCategoryItem {
  final String key;
  final String label;

  const _FaqCategoryItem({
    required this.key,
    required this.label,
  });
}

class _FaqItem {
  final String categoryKey;
  final String category;
  final String question;
  final String answer;
  final List<String> steps;

  const _FaqItem({
    required this.categoryKey,
    required this.category,
    required this.question,
    required this.answer,
    required this.steps,
  });
}
