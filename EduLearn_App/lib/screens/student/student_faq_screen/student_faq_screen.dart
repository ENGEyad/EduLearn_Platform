import 'package:flutter/material.dart';

import '../../../l10n/core/app_localizations.dart';
import '../../../l10n/getters/student/student_faq_l10n.dart';
import '../../../theme.dart';

class StudentFaqScreen extends StatefulWidget {
  const StudentFaqScreen({super.key});

  @override
  State<StudentFaqScreen> createState() => _StudentFaqScreenState();
}

class _StudentFaqScreenState extends State<StudentFaqScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategoryKey = 'all';
  String _query = '';

  final List<String> _categoryKeys = const [
    'all',
    'lessons',
    'exercises',
    'account',
    'support',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _categoryLabel(AppLocalizations l10n, String key) {
    switch (key) {
      case 'all':
        return l10n.studentFaqCategoryAll;
      case 'lessons':
        return l10n.studentFaqCategoryLessons;
      case 'exercises':
        return l10n.studentFaqCategoryExercises;
      case 'account':
        return l10n.studentFaqCategoryAccount;
      case 'support':
        return l10n.studentFaqCategorySupport;
      default:
        return key;
    }
  }

  List<_FaqItem> _items(AppLocalizations l10n) {
    return [
      _FaqItem(
        categoryKey: 'lessons',
        question: l10n.studentFaqQOpenLesson,
        steps: [
          l10n.studentFaqOpenLessonStep1,
          l10n.studentFaqOpenLessonStep2,
          l10n.studentFaqOpenLessonStep3,
          l10n.studentFaqOpenLessonStep4,
        ],
      ),
      _FaqItem(
        categoryKey: 'lessons',
        question: l10n.studentFaqQMissingLessons,
        steps: [
          l10n.studentFaqMissingLessonsStep1,
          l10n.studentFaqMissingLessonsStep2,
          l10n.studentFaqMissingLessonsStep3,
          l10n.studentFaqMissingLessonsStep4,
        ],
      ),
      _FaqItem(
        categoryKey: 'exercises',
        question: l10n.studentFaqQSolveExercise,
        steps: [
          l10n.studentFaqSolveExerciseStep1,
          l10n.studentFaqSolveExerciseStep2,
          l10n.studentFaqSolveExerciseStep3,
          l10n.studentFaqSolveExerciseStep4,
        ],
      ),
      _FaqItem(
        categoryKey: 'exercises',
        question: l10n.studentFaqQEditAfterSubmit,
        steps: [
          l10n.studentFaqEditAfterSubmitStep1,
          l10n.studentFaqEditAfterSubmitStep2,
          l10n.studentFaqEditAfterSubmitStep3,
        ],
      ),
      _FaqItem(
        categoryKey: 'exercises',
        question: l10n.studentFaqQSubmitNotWorking,
        steps: [
          l10n.studentFaqSubmitNotWorkingStep1,
          l10n.studentFaqSubmitNotWorkingStep2,
          l10n.studentFaqSubmitNotWorkingStep3,
          l10n.studentFaqSubmitNotWorkingStep4,
        ],
      ),
      _FaqItem(
        categoryKey: 'account',
        question: l10n.studentFaqQChangePassword,
        steps: [
          l10n.studentFaqChangePasswordStep1,
          l10n.studentFaqChangePasswordStep2,
          l10n.studentFaqChangePasswordStep3,
          l10n.studentFaqChangePasswordStep4,
        ],
      ),
      _FaqItem(
        categoryKey: 'account',
        question: l10n.studentFaqQThemeMode,
        steps: [
          l10n.studentFaqThemeModeStep1,
          l10n.studentFaqThemeModeStep2,
          l10n.studentFaqThemeModeStep3,
        ],
      ),
      _FaqItem(
        categoryKey: 'support',
        question: l10n.studentFaqQContactSupport,
        steps: [
          l10n.studentFaqContactSupportStep1,
          l10n.studentFaqContactSupportStep2,
          l10n.studentFaqContactSupportStep3,
          l10n.studentFaqContactSupportStep4,
        ],
      ),
    ];
  }

  List<_FaqItem> _filteredItems(AppLocalizations l10n) {
    return _items(l10n).where((item) {
      final bool matchesCategory =
          _selectedCategoryKey == 'all' || item.categoryKey == _selectedCategoryKey;
      final bool matchesQuery = _query.trim().isEmpty ||
          item.question.toLowerCase().contains(_query.toLowerCase()) ||
          item.steps.any(
            (step) => step.toLowerCase().contains(_query.toLowerCase()),
          );
      return matchesCategory && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color titleColor = theme.colorScheme.onSurface;
    final Color mutedColor =
        theme.textTheme.bodySmall?.color ??
        (isDark ? EduTheme.darkTextMuted : EduTheme.textMuted);
    final Color cardColor = theme.cardColor;
    final Color borderColor = theme.dividerColor.withValues(
      alpha: isDark ? 0.24 : 0.52,
    );
    final Color shadowColor = theme.shadowColor.withValues(
      alpha: isDark ? 0.18 : 0.06,
    );
    final items = _filteredItems(l10n);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        title: Text(l10n.studentFaqTitle),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          MediaQuery.of(context).padding.bottom + 24,
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.studentFaqHeading,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.studentFaqDescription,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: mutedColor,
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value),
                  decoration: InputDecoration(
                    hintText: l10n.studentFaqSearchHint,
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemBuilder: (_, index) {
                final categoryKey = _categoryKeys[index];
                final bool selected = categoryKey == _selectedCategoryKey;
                return ChoiceChip(
                  label: Text(_categoryLabel(l10n, categoryKey)),
                  selected: selected,
                  onSelected: (_) {
                    setState(() => _selectedCategoryKey = categoryKey);
                  },
                );
              },
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemCount: _categoryKeys.length,
            ),
          ),
          const SizedBox(height: 18),
          if (items.isEmpty)
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.search_off_rounded,
                    size: 34,
                    color: mutedColor,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.studentFaqNoResultsTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: titleColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.studentFaqNoResultsSubtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: mutedColor,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ...items.map(
              (item) => _FaqExpandableCard(
                item: item,
                categoryLabel: _categoryLabel(l10n, item.categoryKey),
                titleColor: titleColor,
                mutedColor: mutedColor,
                cardColor: cardColor,
                borderColor: borderColor,
                shadowColor: shadowColor,
              ),
            ),
        ],
      ),
    );
  }
}

class _FaqExpandableCard extends StatefulWidget {
  final _FaqItem item;
  final String categoryLabel;
  final Color titleColor;
  final Color mutedColor;
  final Color cardColor;
  final Color borderColor;
  final Color shadowColor;

  const _FaqExpandableCard({
    required this.item,
    required this.categoryLabel,
    required this.titleColor,
    required this.mutedColor,
    required this.cardColor,
    required this.borderColor,
    required this.shadowColor,
  });

  @override
  State<_FaqExpandableCard> createState() => _FaqExpandableCardState();
}

class _FaqExpandableCardState extends State<_FaqExpandableCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: widget.cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _expanded
              ? theme.colorScheme.primary.withValues(alpha: 0.38)
              : widget.borderColor,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.shadowColor,
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            widget.categoryLabel,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.item.question,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: widget.titleColor,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: widget.mutedColor,
                    size: 28,
                  ),
                ],
              ),
              if (_expanded) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(widget.item.steps.length, (index) {
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index == widget.item.steps.length - 1 ? 0 : 10,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              margin: const EdgeInsets.only(top: 1),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                widget.item.steps[index],
                                style: TextStyle(
                                  color: widget.titleColor,
                                  fontWeight: FontWeight.w600,
                                  height: 1.42,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FaqItem {
  final String categoryKey;
  final String question;
  final List<String> steps;

  const _FaqItem({
    required this.categoryKey,
    required this.question,
    required this.steps,
  });
}
