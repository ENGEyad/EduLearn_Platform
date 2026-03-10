import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/ai_service.dart';

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
      // Data to feed the AI for the report
      final teacherName = widget.teacher['full_name'] ?? 'Teacher';
      final classStats = {
        'total_students': widget.totalStudents,
        'average_attendance': '94%',
        'average_score': '78/100',
        'active_lessons': 12,
      };

      final studentIssues = [
        {'name': 'Ahmed Ali', 'issue': 'Gradual decline in math scores', 'status': 'Warning'},
        {'name': 'Sara Ahmed', 'issue': 'Outstanding performance in science', 'status': 'Excelled'},
        {'name': 'Omar Khalil', 'issue': 'Needs more practice on geometry', 'status': 'Attention'},
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
          _errorMessage = "Unable to connect to Neural Network. Please try again.";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Deep analysis system offline. Check connection.";
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
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF00E5FF)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'ANALYTICS HUB',
          style: GoogleFonts.orbitron(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF00E5FF),
            letterSpacing: 2,
            shadows: [
              const Shadow(color: Color(0xFF00E5FF), blurRadius: 10),
            ],
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Background Glows
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00E5FF).withOpacity(0.05),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF9C27B0).withOpacity(0.05),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  _buildHeaderStats(),
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
                        ? _buildLoadingOverlay()
                        : _errorMessage != null
                            ? _buildErrorPlaceholder()
                            : _buildReportContent(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStats() {
    return Row(
      children: [
        Expanded(
          child: _CyberStat(
            label: 'EFFICIENCY',
            value: '98%',
            color: const Color(0xFF00E5FF),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _CyberStat(
            label: 'SENTIMENT',
            value: 'POSITIVE',
            color: const Color(0xFF4CAF50),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Color(0xFF00E5FF)),
          const SizedBox(height: 20),
          Text(
            'SYNCHRONIZING NEURAL DATA...',
            style: GoogleFonts.orbitron(
              color: const Color(0xFF00E5FF),
              fontSize: 10,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.redAccent, size: 48),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _fetchReport,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E5FF).withOpacity(0.1),
              side: const BorderSide(color: Color(0xFF00E5FF)),
            ),
            child: const Text('RETRY ANALYTICS'),
          ),
        ],
      ),
    );
  }

  Widget _buildReportContent() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: Color(0xFF00E5FF), size: 16),
                const SizedBox(width: 8),
                Text(
                  'REPORT GENERATED',
                  style: GoogleFonts.orbitron(
                    color: Colors.white54,
                    fontSize: 10,
                  ),
                ),
                const Spacer(),
                Text(
                  DateTime.now().toString().split(' ')[0],
                  style: GoogleFonts.nunito(color: Colors.white24, fontSize: 10),
                ),
              ],
            ),
            const Divider(color: Colors.white10, height: 30),
            Text(
              _reportContent ?? '',
              style: GoogleFonts.nunito(
                color: Colors.white.withOpacity(0.9),
                fontSize: 15,
                height: 1.6,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 40),
            Center(
              child: Opacity(
                opacity: 0.3,
                child: Text(
                  'END OF TRANSMISSION',
                  style: GoogleFonts.orbitron(color: Colors.white, fontSize: 8, letterSpacing: 4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CyberStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _CyberStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.orbitron(
              color: Colors.white38,
              fontSize: 9,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.orbitron(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(color: color.withOpacity(0.5), blurRadius: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
