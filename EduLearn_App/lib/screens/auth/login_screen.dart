import 'package:flutter/material.dart';

import '../../l10n/core/app_localizations.dart';
import '../../l10n/getters/auth/login_l10n.dart';
import '../../services/auth_service.dart';
import '../../theme.dart';
import '../student/student_main/student_main_screen.dart';
import '../teacher/teacher_main/teacher_main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController fullNameCtrl = TextEditingController();
  final TextEditingController idCtrl = TextEditingController();

  bool isStudent = true;
  bool isLoading = false;

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      if (isStudent) {
        final res = await AuthService.authStudent(
          fullName: fullNameCtrl.text.trim(),
          academicId: idCtrl.text.trim(),
        );

        final Map<String, dynamic> student =
            (res['student'] as Map<String, dynamic>);

        if (!mounted) return;

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => StudentMainScreen(student: student),
          ),
        );
      } else {
        final res = await AuthService.authTeacher(
          fullName: fullNameCtrl.text.trim(),
          teacherCode: idCtrl.text.trim(),
        );

        final Map<String, dynamic> teacher =
            (res['teacher'] as Map<String, dynamic>);

        if (!mounted) return;

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => TeacherMainScreen(teacher: teacher),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    fullNameCtrl.dispose();
    idCtrl.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData prefixIcon,
    required Color iconColor,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: Icon(
        prefixIcon,
        size: 20,
        color: iconColor,
      ),
    );
  }

  Widget _buildRoleToggle({
    required ThemeData theme,
    required Color tileColor,
    required Color shadowColor,
    required Color mutedColor,
    required Color selectedBackgroundColor,
    required Color selectedTextColor,
    required Color borderColor,
    required Color selectedBorderColor,
    required String studentLabel,
    required String teacherLabel,
  }) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: tileColor,
        borderRadius: EduTheme.radiusLarge,
        border: Border.all(color: borderColor),
        boxShadow: EduTheme.subtleShadow(theme.brightness == Brightness.dark),
      ),
      padding: const EdgeInsets.all(5),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final segmentWidth = (constraints.maxWidth - 10) / 2;

          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                left: isStudent ? 0 : segmentWidth,
                top: 0,
                bottom: 0,
                width: segmentWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: selectedBackgroundColor,
                    borderRadius: EduTheme.radiusMedium,
                    border: Border.all(color: selectedBorderColor),
                    boxShadow: [
                      BoxShadow(
                        color: shadowColor,
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: _RoleSegment(
                      label: studentLabel,
                      selected: isStudent,
                      selectedTextColor: selectedTextColor,
                      unselectedTextColor: mutedColor,
                      onTap: () {
                        if (!isStudent) {
                          setState(() => isStudent = true);
                        }
                      },
                    ),
                  ),
                  Expanded(
                    child: _RoleSegment(
                      label: teacherLabel,
                      selected: !isStudent,
                      selectedTextColor: selectedTextColor,
                      unselectedTextColor: mutedColor,
                      onTap: () {
                        if (isStudent) {
                          setState(() => isStudent = false);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final Color titleColor = theme.colorScheme.onSurface;
    final Color mutedColor = theme.textTheme.bodySmall?.color ??
        (isDarkMode ? EduTheme.darkTextMuted : EduTheme.textMuted);
    final Color tileColor = theme.cardColor;
    final Color cardShadowColor =
        Colors.black.withValues(alpha: isDarkMode ? 0.22 : 0.08);
    final Color logoBackground = isDarkMode
        ? EduTheme.darkSurfaceContainer
        : EduTheme.softPrimaryBackground;
    final Color selectedSegmentBackground =
        isDarkMode ? EduTheme.darkSurfaceContainerHigh : Colors.white;
    final Color subtleBorderColor = isDarkMode
        ? EduTheme.darkInputBorder.withValues(alpha: 0.95)
        : EduTheme.inputBorder.withValues(alpha: 0.95);
    final Color selectedBorderColor = theme.colorScheme.primary
        .withValues(alpha: isDarkMode ? 0.34 : 0.18);
    final Color selectedTextColor = theme.colorScheme.primary;
    final Color inputIconColor =
        isDarkMode ? EduTheme.darkTextMuted : EduTheme.secondary;
    final Color helperCardColor =
        isDarkMode ? theme.cardColor : EduTheme.surfaceContainerLow;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: EduTheme.pageGradient(isDarkMode),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: size.width * 0.07,
                vertical: 24,
              ),
              child: Form(
                key: _formKey,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 24),
                    decoration: BoxDecoration(
                      color: helperCardColor,
                      borderRadius: EduTheme.radiusXL,
                      border: Border.all(color: subtleBorderColor),
                      boxShadow: EduTheme.cardShadow(isDarkMode),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.loginAppName,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    l10n.loginWelcomeBack,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      color: titleColor,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    l10n.loginDescription,
                                    style:
                                        theme.textTheme.bodyMedium?.copyWith(
                                      color: mutedColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Container(
                              width: 78,
                              height: 78,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: logoBackground,
                                shape: BoxShape.circle,
                                border: Border.all(color: subtleBorderColor),
                                boxShadow:
                                    EduTheme.subtleShadow(isDarkMode),
                              ),
                              child: Image.asset(
                                'assets/icons/app_icon.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 26),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: tileColor,
                            borderRadius: EduTheme.radiusLarge,
                            border: Border.all(color: subtleBorderColor),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.loginAccountType,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: titleColor,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 10),
                              _buildRoleToggle(
                                theme: theme,
                                tileColor: tileColor,
                                shadowColor: cardShadowColor,
                                mutedColor: mutedColor,
                                selectedBackgroundColor:
                                    selectedSegmentBackground,
                                selectedTextColor: selectedTextColor,
                                borderColor: subtleBorderColor,
                                selectedBorderColor: selectedBorderColor,
                                studentLabel: l10n.loginStudentRole,
                                teacherLabel: l10n.loginTeacherRole,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          l10n.loginFullName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: titleColor,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: fullNameCtrl,
                          decoration: _inputDecoration(
                            hintText: l10n.loginFullNameHint,
                            prefixIcon: Icons.person_outline_rounded,
                            iconColor: inputIconColor,
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return l10n.loginFullNameRequired;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),
                        Text(
                          isStudent ? l10n.loginStudentId : l10n.loginTeacherCode,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: titleColor,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: idCtrl,
                          decoration: _inputDecoration(
                            hintText: isStudent
                                ? l10n.loginStudentIdHint
                                : l10n.loginTeacherCodeHint,
                            prefixIcon: isStudent
                                ? Icons.badge_outlined
                                : Icons.verified_user_outlined,
                            iconColor: inputIconColor,
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return isStudent
                                  ? l10n.loginStudentIdRequired
                                  : l10n.loginTeacherCodeRequired;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(56),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor:
                                          AlwaysStoppedAnimation(Colors.white),
                                    ),
                                  )
                                : Text(l10n.loginButton),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          isStudent
                              ? l10n.loginStudentHelper
                              : l10n.loginTeacherHelper,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: mutedColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleSegment extends StatelessWidget {
  final String label;
  final bool selected;
  final Color selectedTextColor;
  final Color unselectedTextColor;
  final VoidCallback onTap;

  const _RoleSegment({
    required this.label,
    required this.selected,
    required this.selectedTextColor,
    required this.unselectedTextColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: EduTheme.radiusMedium,
        onTap: onTap,
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            style: TextStyle(
              color: selected ? selectedTextColor : unselectedTextColor,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
              fontSize: 14,
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }
}
