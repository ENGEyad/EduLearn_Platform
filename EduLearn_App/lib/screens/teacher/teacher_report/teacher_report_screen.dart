import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/ai_service.dart';

part 'teacher_report_widgets.dart';

class TeacherReportScreen extends StatefulWidget {
  final Map<String, dynamic> teacher;
  final int totalStudents;

  const TeacherReportScreen({
    super.key,
    required this.teacher,
    required this.totalStudents,
  });

  @override
  State<TeacherReportScreen> createState() => _TeacherReportScreenState();
}

class _TeacherReportScreenState extends State<TeacherReportScreen> {
  bool _isLoading = true;
  String? _reportContent;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchReport();
  }

  Future<void> _fetchReport() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final teacherName = widget.teacher['full_name'] ?? 'Teacher';

      final classStats = {
        'total_students': widget.totalStudents,
        'average_attendance': '94%',
        'average_score': '78/100',
        'active_lessons': 12,
      };

      final studentIssues = [
        {
          'name': 'Ahmed Ali',
          'issue': 'Gradual decline in math scores',
          'status': 'Warning',
        },
        {
          'name': 'Sara Ahmed',
          'issue': 'Outstanding performance in science',
          'status': 'Excelled',
        },
        {
          'name': 'Omar Khalil',
          'issue': 'Needs more practice on geometry',
          'status': 'Attention',
        },
      ];

      final response = await AIService.getTeacherDailyReport(
        teacherName: teacherName,
        classStats: classStats,
        studentIssues: studentIssues,
      );

      if (response != null && response['report'] != null) {
        setState(() {
          _reportContent = response['report'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              'Unable to connect to Neural Network. Please try again.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Deep analysis system offline. Check connection.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF00E5FF),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'ANALYTICS HUB',
          style: GoogleFonts.orbitron(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF00E5FF),
            letterSpacing: 2,
            shadows: const [
              Shadow(color: Color(0xFF00E5FF), blurRadius: 10),
            ],
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          const _ReportBackgroundGlow(
            top: -100,
            right: -50,
            width: 300,
            height: 300,
            color: Color(0xFF00E5FF),
          ),
          const _ReportBackgroundGlow(
            bottom: -50,
            left: -50,
            width: 250,
            height: 250,
            color: Color(0xFF9C27B0),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  const _HeaderStatsRow(),
                  const SizedBox(height: 30),
                  Text(
                    'AI DAILY INSIGHTS',
                    style: GoogleFonts.orbitron(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _isLoading
                        ? const _ReportLoadingOverlay()
                        : _errorMessage != null
                            ? _ReportErrorPlaceholder(
                                errorMessage: _errorMessage!,
                                onRetry: _fetchReport,
                              )
                            : _ReportContent(
                                reportContent: _reportContent ?? '',
                              ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}