// ─────────────────────────────────────────────────────────────
// AegisRx Patient Widget — RiskGauge
// Migrated to AegisRx Design System
// Semicircular health risk gauge with needle indicator
// ─────────────────────────────────────────────────────────────

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:health_lock/core/theme/design_system.dart';

class RiskGauge extends StatelessWidget {
  final int severityScore; // 0–100

  const RiskGauge({super.key, required this.severityScore});

  Color _scoreColor() {
    final ext = AegisRiskTheme.defaultLight;
    return ext.forScore(severityScore);
  }

  String _scoreLabel() {
    if (severityScore <= 30) return 'LOW RISK';
    if (severityScore <= 60) return 'MODERATE RISK';
    if (severityScore <= 80) return 'HIGH RISK';
    return 'CRITICAL RISK';
  }

  @override
  Widget build(BuildContext context) {
    final color = _scoreColor();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: const Size(160, 90),
          painter: SemicircleGaugePainter(score: severityScore),
        ),
        const SizedBox(height: AegisSpacing.sm),
        Text(
          '$severityScore/100',
          style: AegisTypography.displaySmall.copyWith(color: AegisColors.textPrimary),
        ),
        const SizedBox(height: AegisSpacing.xs),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AegisTokens.chipPaddingH,
            vertical: AegisTokens.chipPaddingV,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: AegisRadius.chip,
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Text(
            _scoreLabel(),
            style: AegisTypography.labelSmall.copyWith(
              color: color,
              letterSpacing: 0.8,
            ),
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

    const strokeWidth = 14.0;

    // Segment paints — use AegisColors tokens
    final Paint paintSafe = Paint()
      ..color = AegisColors.success
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final Paint paintModerate = Paint()
      ..color = AegisColors.warning.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final Paint paintHigh = Paint()
      ..color = AegisTokens.riskHigh
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final Paint paintCritical = Paint()
      ..color = AegisColors.danger
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    // Track background
    final Paint trackPaint = Paint()
      ..color = AegisColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 2
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi, pi, false, trackPaint,
    );

    // Colored segments: 60% safe, 20% moderate, 10% high, 10% critical
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
        pi, pi * 0.60, false, paintSafe);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
        pi + pi * 0.60, pi * 0.20, false, paintModerate);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
        pi + pi * 0.80, pi * 0.10, false, paintHigh);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
        pi + pi * 0.90, pi * 0.10, false, paintCritical);

    // Needle
    final double normalizedValue = score / 100.0;
    final double angle = pi + (pi * normalizedValue);

    final Paint needlePaint = Paint()
      ..color = AegisColors.textPrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final double needleLength = radius - 6;
    final double needleX = centerX + needleLength * cos(angle);
    final double needleY = centerY + needleLength * sin(angle);
    canvas.drawLine(center, Offset(needleX, needleY), needlePaint);

    // Pivot dot
    final Paint pivotPaint = Paint()
      ..color = AegisColors.textPrimary
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 5, pivotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
