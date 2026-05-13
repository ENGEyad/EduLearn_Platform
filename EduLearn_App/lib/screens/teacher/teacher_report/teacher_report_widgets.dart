part of 'teacher_report_screen.dart';

class _ReportBackgroundGlow extends StatelessWidget {
  final double? top;
  final double? right;
  final double? bottom;
  final double? left;
  final double width;
  final double height;
  final Color color;

  const _ReportBackgroundGlow({
    this.top,
    this.right,
    this.bottom,
    this.left,
    required this.width,
    required this.height,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      right: right,
      bottom: bottom,
      left: left,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.05),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
          child: Container(color: Colors.transparent),
        ),
      ),
    );
  }
}

class _HeaderStatsRow extends StatelessWidget {
  const _HeaderStatsRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: _CyberStat(
            label: 'EFFICIENCY',
            value: '98%',
            color: Color(0xFF00E5FF),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _CyberStat(
            label: 'SENTIMENT',
            value: 'POSITIVE',
            color: Color(0xFF4CAF50),
          ),
        ),
      ],
    );
  }
}

class _ReportLoadingOverlay extends StatelessWidget {
  const _ReportLoadingOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
        ),
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
}

class _ReportErrorPlaceholder extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onRetry;

  const _ReportErrorPlaceholder({
    required this.errorMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            color: Colors.redAccent,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            errorMessage,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E5FF).withValues(alpha: 0.1),
              side: const BorderSide(color: Color(0xFF00E5FF)),
            ),
            child: const Text('RETRY ANALYTICS'),
          ),
        ],
      ),
    );
  }
}

class _ReportContent extends StatelessWidget {
  final String reportContent;

  const _ReportContent({
    required this.reportContent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.auto_awesome,
                  color: Color(0xFF00E5FF),
                  size: 16,
                ),
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
                  style: GoogleFonts.nunito(
                    color: Colors.white24,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white10, height: 30),
            Text(
              reportContent,
              style: GoogleFonts.nunito(
                color: Colors.white.withValues(alpha: 0.9),
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
                  style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontSize: 8,
                    letterSpacing: 4,
                  ),
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

  const _CyberStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
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
                Shadow(
                  color: color.withValues(alpha: 0.5),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}