import 'package:flutter/material.dart';
import 'theme.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const EduLearnApp());
}

class EduLearnApp extends StatelessWidget {
  const EduLearnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EduLearn',
      debugShowCheckedModeBanner: false,
      theme: EduTheme.light(),
      home: const SplashScreen(),
    );
  }
}
