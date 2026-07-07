import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RiskGauge extends StatelessWidget {
  final int severityScore; // out of 100

  const RiskGauge({super.key, required this.severityScore});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: const Size(160, 90),
          painter: SemicircleGaugePainter(score: severityScore),
        ),
        const SizedBox(height: 8),
        Text(
          '$severityScore/100',
          style: GoogleFonts.sora(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF4A3325), // Deep Matte Bronze
          ),
        ),
        Text(
          severityScore <= 30
              ? 'LOW RISK'
              : (severityScore <= 70 ? 'MEDIUM RISK' : 'CRITICAL RISK'),
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: severityScore <= 30
                ? const Color(0xFF2E8B90) // Deep Medical Teal
                : (severityScore <= 70
                    ? const Color(0xFFD97736) // Warm Amber
                    : const Color(0xFFB33A3A)), // Burgundy Red
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

class SemicircleGaugePainter extends CustomPainter {
  final int score;

  SemicircleGaugePainter({required this.score});

  @override
  void paint(Canvas canvas, Size size) {
    final double centerX = size.width / 2;
    final double centerY = size.height;
    final double radius = size.width / 2 - 10;

    final Offset center = Offset(centerX, centerY);

    // Segment color declarations
    final Paint paintTeal = Paint()
      ..color = const Color(0xFF2E8B90)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.butt;

    final Paint paintCopper = Paint()
      ..color = const Color(0xFFB88E74)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.butt;

    final Paint paintAmber = Paint()
      ..color = const Color(0xFFD97736)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.butt;

    final Paint paintBurgundy = Paint()
      ..color = const Color(0xFFB33A3A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.butt;

    // Drawing semicircle gauge segments (from PI to 2 * PI)
    // 70% Teal (0.7 * PI)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi,
      pi * 0.70,
      false,
      paintTeal,
    );

    // 15% Copper (0.15 * PI)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi + (pi * 0.70),
      pi * 0.15,
      false,
      paintCopper,
    );

    // 10% Amber (0.10 * PI)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi + (pi * 0.85),
      pi * 0.10,
      false,
      paintAmber,
    );

    // 5% Burgundy (0.05 * PI)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi + (pi * 0.95),
      pi * 0.05,
      false,
      paintBurgundy,
    );

    // Drawing needle indicator based on the actual score
    final double normalizedValue = score / 100.0;
    final double angle = pi + (pi * normalizedValue);

    final Paint needlePaint = Paint()
      ..color = const Color(0xFF4A3325)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final double needleLength = radius - 8;
    final double needleX = centerX + needleLength * cos(angle);
    final double needleY = centerY + needleLength * sin(angle);

    canvas.drawLine(center, Offset(needleX, needleY), needlePaint);

    // Needle pivot circle
    final Paint pivotPaint = Paint()
      ..color = const Color(0xFF4A3325)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 6, pivotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
