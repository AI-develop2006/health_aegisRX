// ════════════════════════════════════════════════════════════════════════════
// AegisRx — Splash Screen
// Design System: AegisRx Clinical Precision
// Business logic: UNCHANGED — completeSplash() call preserved exactly
// ════════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/design_system.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _shieldCtrl;
  late AnimationController _textCtrl;
  late AnimationController _progressCtrl;
  late AnimationController _spinCtrl;

  late Animation<double> _shieldScale;
  late Animation<double> _shieldOpacity;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _progressVal;

  @override
  void initState() {
    super.initState();

    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..repeat();

    _shieldCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _shieldScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _shieldCtrl, curve: Curves.elasticOut),
    );
    _shieldOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shieldCtrl, curve: const Interval(0.0, 0.5, curve: Curves.easeOut)),
    );

    _textCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut),
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOutQuart));

    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _progressVal = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressCtrl, curve: Curves.easeInOut),
    );

    _shieldCtrl.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _textCtrl.forward();
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _progressCtrl.forward();
    });

    // ── BUSINESS LOGIC UNCHANGED ──
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Provider.of<AppState>(context, listen: false).completeSplash();
      }
    });
  }

  @override
  void dispose() {
    _shieldCtrl.dispose();
    _textCtrl.dispose();
    _progressCtrl.dispose();
    _spinCtrl.dispose();
    super.dispose();
  }

  Widget _buildRipple(int index) {
    double delayFraction = 0.0;
    if (index == 2) delayFraction = 0.33;
    if (index == 3) delayFraction = 0.66;

    return AnimatedBuilder(
      animation: _spinCtrl,
      builder: (context, child) {
        double progress = (_spinCtrl.value + delayFraction) % 1.0;
        double scale = 0.55 + (1.35 - 0.55) * progress;
        double opacity = 0.6 * (1.0 - progress);
        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AegisColors.primary.withValues(alpha: 0.3),
                  width: 1.2,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: AegisColors.background,
      body: Stack(
        children: [
          // Subtle grid background using the clinical grid pattern
          Positioned.fill(child: CustomPaint(painter: _SplashGridPainter())),

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Shield animation ──────────────────────────────
                AnimatedBuilder(
                  animation: _shieldCtrl,
                  builder: (context, child) => Opacity(
                    opacity: _shieldOpacity.value,
                    child: Transform.scale(
                      scale: _shieldScale.value,
                      child: child,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      _buildRipple(1),
                      _buildRipple(2),
                      _buildRipple(3),
                      AnimatedBuilder(
                        animation: _spinCtrl,
                        builder: (context, child) {
                          final angle = _spinCtrl.value * math.pi * 2;
                          return Transform(
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.001)
                              ..rotateY(angle),
                            alignment: Alignment.center,
                            child: SizedBox(
                              width: 130,
                              height: 175,
                              child: CustomPaint(painter: AegisShieldPainter()),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AegisSpacing.xxl),

                // ── Branding text ─────────────────────────────────
                SlideTransition(
                  position: _textSlide,
                  child: FadeTransition(
                    opacity: _textOpacity,
                    child: Column(
                      children: [
                        Text(
                          'AegisRx',
                          style: AegisTypography.displayMedium.copyWith(
                            color: AegisColors.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: AegisSpacing.xs),
                        Text(
                          'HEALTHLOCK',
                          style: AegisTypography.labelCaps.copyWith(
                            color: AegisColors.primary,
                            letterSpacing: 4.5,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: AegisSpacing.md),
                        Text(
                          'Patient-sovereign health, safely shared.',
                          style: AegisTypography.bodyMedium.copyWith(
                            color: AegisColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AegisSpacing.xxl),

                // ── Progress bar ──────────────────────────────────
                FadeTransition(
                  opacity: _textOpacity,
                  child: SizedBox(
                    width: size.width * 0.55,
                    child: AnimatedBuilder(
                      animation: _progressVal,
                      builder: (_, child) => ClipRRect(
                        borderRadius: BorderRadius.circular(AegisRadius.xs),
                        child: LinearProgressIndicator(
                          value: _progressVal.value,
                          backgroundColor: AegisColors.border,
                          valueColor: AlwaysStoppedAnimation<Color>(AegisColors.primary),
                          minHeight: 3,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Footer
          Positioned(
            bottom: AegisSpacing.xl,
            left: 0,
            right: 0,
            child: Center(
              child: FadeTransition(
                opacity: _textOpacity,
                child: Text(
                  'v1.0.0 · Protected by End-to-End Encryption',
                  style: AegisTypography.labelSmall.copyWith(
                    color: AegisColors.textTertiary,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Subtle Clinical Grid Background ───────────────────────────────────────
class _SplashGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AegisColors.primary.withValues(alpha: 0.035)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    const step = 48.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── AegisShield SVG Painter (business logic — UNCHANGED) ──────────────────
class AegisShieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final Rect rect = Rect.fromLTWH(0, 0, w, h);

    final outerGrad = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF2563EB), Color(0xFF14B8A6), Color(0xFF7C3AED)],
      stops: [0.0, 0.45, 1.0],
    ).createShader(rect);

    final sheenGrad = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        Colors.white.withOpacity(0.45),
        Colors.white.withOpacity(0.05),
        Colors.black.withOpacity(0.2),
      ],
      stops: const [0.0, 0.45, 1.0],
    ).createShader(rect);

    final innerGrad = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFEFF6FF), Color(0xFFF0FDFA)],
    ).createShader(rect);

    final glowGrad = RadialGradient(
      center: const Alignment(0.0, -0.1),
      radius: 0.55,
      colors: [
        AegisColors.primary.withOpacity(0.4),
        AegisColors.primary.withOpacity(0.0),
      ],
    ).createShader(rect);

    final pathOuter = Path()
      ..moveTo(w * 0.5, h * (2 / 150))
      ..lineTo(w * (106 / 110), h * (20 / 150))
      ..lineTo(w * (106 / 110), h * (78 / 150))
      ..quadraticBezierTo(w * (106 / 110), h * (120 / 150), w * 0.5, h * (148 / 150))
      ..quadraticBezierTo(w * (4 / 110), h * (120 / 150), w * (4 / 110), h * (78 / 150))
      ..lineTo(w * (4 / 110), h * (20 / 150))
      ..close();

    final pathInner = Path()
      ..moveTo(w * 0.5, h * (12 / 150))
      ..lineTo(w * (96 / 110), h * (26 / 150))
      ..lineTo(w * (96 / 110), h * (76 / 150))
      ..quadraticBezierTo(w * (96 / 110), h * (112 / 150), w * 0.5, h * (136 / 150))
      ..quadraticBezierTo(w * (14 / 110), h * (112 / 150), w * (14 / 110), h * (76 / 150))
      ..lineTo(w * (14 / 110), h * (26 / 150))
      ..close();

    canvas.drawPath(pathOuter, Paint()..shader = outerGrad);
    canvas.drawPath(pathOuter, Paint()..shader = sheenGrad);
    canvas.drawPath(
      pathOuter,
      Paint()
        ..color = AegisColors.primary.withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    canvas.drawPath(pathInner, Paint()..shader = innerGrad);
    canvas.drawPath(pathInner, Paint()..shader = glowGrad);
    canvas.drawPath(
      pathInner,
      Paint()
        ..color = AegisColors.primary.withOpacity(0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    canvas.save();
    canvas.translate(w * (55 / 110), h * (74 / 150));
    final padlockScale = w / 110.0;
    canvas.scale(padlockScale);

    final primaryPaint = Paint()
      ..color = AegisColors.primary
      ..style = PaintingStyle.fill;

    final shacklePath = Path()
      ..moveTo(-11, -6)
      ..quadraticBezierTo(-11, -20, 0, -20)
      ..quadraticBezierTo(11, -20, 11, -6)
      ..lineTo(11, 0)
      ..lineTo(7, 0)
      ..lineTo(7, -6)
      ..quadraticBezierTo(7, -16, 0, -16)
      ..quadraticBezierTo(-7, -16, -7, -6)
      ..lineTo(-7, 0)
      ..lineTo(-11, 0)
      ..close();
    canvas.drawPath(shacklePath, primaryPaint);

    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-15, 0, 30, 24), const Radius.circular(4)),
      primaryPaint,
    );

    final holePaint = Paint()
      ..color = AegisColors.primarySurface
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(0, 10), 3, holePaint);
    canvas.drawRect(const Rect.fromLTWH(-1.2, 10, 2.4, 7), holePaint);
    canvas.restore();

    final checkmarkPath = Path()
      ..moveTo(w * (40 / 110), h * (108 / 150))
      ..lineTo(w * (52 / 110), h * (118 / 150))
      ..lineTo(w * (72 / 110), h * (96 / 150));
    canvas.drawPath(
      checkmarkPath,
      Paint()
        ..color = AegisColors.secondary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
