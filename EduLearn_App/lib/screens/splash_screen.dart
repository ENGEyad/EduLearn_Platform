import 'dart:async';
import 'package:flutter/material.dart';
import '../theme.dart';
import 'auth/register_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // بعد 3 ثواني انتقل لصفحة التسجيل/الدخول
    Timer(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const RegisterScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // الدائرة مع أيقونة الشعار – تقدر تضيف صورتك بدل الأيقونة
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: EduTheme.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.school_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'EduLearn',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: EduTheme.primaryDark,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Empowering smart, connected learning.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: EduTheme.textMuted,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
