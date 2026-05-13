import 'dart:async';
import 'package:flutter/material.dart';

import '../l10n/core/app_localizations.dart';
import '../l10n/getters/common/splash_l10n.dart';
import '../services/auth_service.dart';
import '../services/student_service.dart';
import '../services/teacher_data_service.dart';
import '../theme.dart';
import 'student/student_main/student_main_screen.dart';
import 'teacher/teacher_main/teacher_main_screen.dart';
import 'auth/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.elasticOut),
      ),
    );

    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.08), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.08, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.7, 1.0, curve: Curves.easeInOut),
    ));

    _controller.forward();
    _checkLogin();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkLogin() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    final token = await AuthService.getToken();
    final userData = await AuthService.getUserData();
    final userType = await AuthService.getUserType();

    if (token != null && userData != null && userType != null) {
      try {
        if (userType == 'student') {
          await StudentService.fetchStudentSubjects();
        } else if (userType == 'teacher') {
          await TeacherDataService.fetchAssignmentsSummary();
        } else {
          await AuthService.logout();
          _goToLogin();
          return;
        }

        if (mounted) {
          if (userType == 'student') {
            Navigator.of(context).pushReplacement(
              PageRouteBuilder(
                transitionDuration: const Duration(milliseconds: 550),
                pageBuilder: (_, __, ___) => StudentMainScreen(student: userData),
                transitionsBuilder: (_, animation, __, child) =>
                    FadeTransition(opacity: animation, child: child),
              ),
            );
          } else {
            Navigator.of(context).pushReplacement(
              PageRouteBuilder(
                transitionDuration: const Duration(milliseconds: 550),
                pageBuilder: (_, __, ___) => TeacherMainScreen(teacher: userData),
                transitionsBuilder: (_, animation, __, child) =>
                    FadeTransition(opacity: animation, child: child),
              ),
            );
          }
        }
      } catch (_) {
        await AuthService.logout();
        _goToLogin();
      }
    } else {
      _goToLogin();
    }
  }

  void _goToLogin() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) => const LoginScreen(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: EduTheme.pageGradient(isDark)),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Opacity(
                        opacity: (1 - _controller.value).clamp(0.0, 0.3),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              radius: 0.8,
                              colors: [
                                theme.colorScheme.primary.withAlpha(25),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _scaleAnimation.value *
                              (_controller.isCompleted
                                  ? _pulseAnimation.value
                                  : 1.0),
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                boxShadow: EduTheme.subtleShadow(isDark),
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(EduTheme.spaceLg),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface,
                                  borderRadius: EduTheme.radiusLarge,
                                  border: Border.all(
                                    color: theme.colorScheme.primary
                                        .withAlpha(isDark ? 50 : 80),
                                    width: 1.2,
                                  ),
                                  boxShadow: EduTheme.cardShadow(isDark),
                                ),
                                child: ClipRRect(
                                  borderRadius: EduTheme.radiusMedium,
                                  child: Image.asset(
                                    'assets/icons/app_icon.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: EduTheme.spaceXl * 2),
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return Opacity(
                          opacity: (_controller.value *
                                  (1 -
                                      (_controller.value - 0.5)
                                          .clamp(0, 0.3)))
                              .clamp(0.0, 1.0),
                          child: Transform.translate(
                            offset: Offset(0, 16 * (1 - _controller.value).clamp(0, 1)),
                            child: Column(
                              children: [
                                Text(
                                  l10n.splashAppName,
                                  style: theme.textTheme.displaySmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    foreground: Paint()
                                      ..shader = LinearGradient(
                                        colors: [
                                          theme.colorScheme.primary,
                                          theme.colorScheme.tertiary ,
                                              theme.colorScheme.secondary,
                                        ],
                                      ).createShader(
                                        const Rect.fromLTWH(0, 0, 200, 70),
                                      ),
                                  ),
                                ),
                                const SizedBox(height: EduTheme.spaceSm),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: EduTheme.spaceLg,
                                    vertical: EduTheme.spaceXs,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withAlpha(25),
                                    borderRadius: EduTheme.radiusPill,
                                  ),
                                  child: Text(
                                    l10n.splashSubtitle,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: theme.colorScheme.primary.withAlpha(200),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: EduTheme.spaceXl * 2.5),
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return SizedBox(
                          width: 140,
                          child: Column(
                            children: [
                              ClipRRect(
                                borderRadius: EduTheme.radiusPill,
                                child: LinearProgressIndicator(
                                  minHeight: 4,
                                  value: _controller.value,
                                  backgroundColor: theme.colorScheme.primary.withAlpha(35),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: EduTheme.spaceMd),
                              Text(
                                l10n.splashPreparing,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.primary.withAlpha(180),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: EduTheme.spaceXl,
                left: 0,
                right: 0,
                child: Text(
                  l10n.splashCopyright,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(150),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
