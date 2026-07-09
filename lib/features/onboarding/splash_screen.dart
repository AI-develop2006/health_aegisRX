import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/state/app_state.dart';

// ── Design Tokens ──────────────────────────────────────────────────────────
const _kBg       = Color(0xFF0A0F1D);  // 60% Midnight Navy
const _kBorder   = Color(0xFF334155);  // 30% Border
const _kAccent   = Color(0xFF0EA5E9);  // 10% Cyber Shield Blue
const _kText     = Color(0xFFFFFFFF);
const _kMuted    = Color(0xFF94A3B8);

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

    // Infinite Spin animation for the 3D rotating shield
    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..repeat();

    // Shield scale animation on entrance: 0 → 900ms
    _shieldCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _shieldScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _shieldCtrl, curve: Curves.elasticOut),
    );
    _shieldOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _shieldCtrl,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    // Text slide & fade: 500ms → 1200ms
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

    // Progress bar fill: 400ms → 2800ms
    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _progressVal = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressCtrl, curve: Curves.easeInOut),
    );

    // Staggered trigger sequences
    _shieldCtrl.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _textCtrl.forward();
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _progressCtrl.forward();
    });

    // Navigate to dashboard/onboarding after exactly 3.0 seconds
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

  // Staggered water ripple ring widgets (React aegis-ripple-1, 2, 3 conversion)
  Widget _buildRipple(int index) {
    double delayFraction = 0.0;
    if (index == 2) delayFraction = 0.33;
    if (index == 3) delayFraction = 0.66;

    return AnimatedBuilder(
      animation: _spinCtrl,
      builder: (context, child) {
        double progress = (_spinCtrl.value + delayFraction) % 1.0;
        double scale = 0.55 + (1.35 - 0.55) * progress;
        double opacity = 0.8 * (1.0 - progress);

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
                  color: const Color(0xFFFACC15), // Gold ripple borders
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFACC15).withOpacity(0.18),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
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
      backgroundColor: _kBg,
      body: Stack(
        children: [
          // Security mesh grid canvas background
          Positioned.fill(
            child: CustomPaint(painter: SecurityMeshPainter()),
          ),

          // Main Screen Contents
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Staggered Entrance Wrapper ──────────────────
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
                      // Ground pulse shadow (pulses out-of-phase with spin rotation)
                      Transform.translate(
                        offset: const Offset(0, 108),
                        child: AnimatedBuilder(
                          animation: _spinCtrl,
                          builder: (context, child) {
                            final pulseFactor = 0.8 + 0.2 * math.sin(_spinCtrl.value * math.pi * 2).abs();
                            return Opacity(
                              opacity: 0.6 + 0.4 * math.sin(_spinCtrl.value * math.pi * 2).abs(),
                              child: Container(
                                width: 100 * pulseFactor,
                                height: 12,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0x520A0A26),
                                      blurRadius: 12,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      // Staggered water ripples
                      _buildRipple(1),
                      _buildRipple(2),
                      _buildRipple(3),

                      // 3D Rotating SVG-Painted Shield
                      AnimatedBuilder(
                        animation: _spinCtrl,
                        builder: (context, child) {
                          final angle = _spinCtrl.value * math.pi * 2;
                          return Transform(
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.001) // 3D Perspective
                              ..rotateY(angle),      // Rotate Y axis
                            alignment: Alignment.center,
                            child: SizedBox(
                              width: 130,
                              height: 175,
                              child: CustomPaint(
                                painter: AegisShieldPainter(),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 48),

                // ── Branding Text ──────────────────────────────
                SlideTransition(
                  position: _textSlide,
                  child: FadeTransition(
                    opacity: _textOpacity,
                    child: Column(
                      children: [
                        Text(
                          'AegisRx',
                          style: GoogleFonts.sora(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            color: _kText,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'HEALTHLOCK',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _kAccent,
                            letterSpacing: 4.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Patient-sovereign health, safely shared.',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: _kMuted,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 52),

                // ── Progress bar loader ────────────────────────
                FadeTransition(
                  opacity: _textOpacity,
                  child: SizedBox(
                    width: size.width * 0.55,
                    child: AnimatedBuilder(
                      animation: _progressVal,
                      builder: (_, __) => ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _progressVal.value,
                          backgroundColor: _kBorder,
                          valueColor: const AlwaysStoppedAnimation<Color>(_kAccent),
                          minHeight: 2,
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
            bottom: 32,
            left: 0,
            right: 0,
            child: Center(
              child: FadeTransition(
                opacity: _textOpacity,
                child: Text(
                  'v1.0.0 · Protected by End-to-End Encryption',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: _kMuted.withOpacity(0.5),
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

// ── Security Mesh CustomPainter ────────────────────────────────────────────
class SecurityMeshPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0EA5E9).withOpacity(0.03)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const step = 48.0;
    // Vertical lines
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    // Horizontal lines
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    // Diagonal lines
    final diagPaint = Paint()
      ..color = const Color(0xFF0EA5E9).withOpacity(0.015)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    for (double d = -size.height; d <= size.width + size.height; d += step * 3) {
      canvas.drawLine(Offset(d, 0), Offset(d + size.height, size.height), diagPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── SVG Canvas Painter representing your AegisShield Design ─────────────────
class AegisShieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final Rect rect = Rect.fromLTWH(0, 0, w, h);

    // 1. Setup Gradients
    // Purple -> Green -> Cyan Linear Gradient fill
    final outerGrad = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: const [
        Color(0xFF8B5CF6),
        Color(0xFF10B981),
        Color(0xFF06B6D4),
      ],
      stops: const [0.0, 0.45, 1.0],
    ).createShader(rect);

    // Sheen Overlay
    final sheenGrad = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        Colors.white.withOpacity(0.55),
        Colors.white.withOpacity(0.05),
        Colors.black.withOpacity(0.35),
      ],
      stops: const [0.0, 0.45, 1.0],
    ).createShader(rect);

    // Inner Shield Gradient
    final innerGrad = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: const [
        Color(0xFF1A1550),
        Color(0xFF0B0836),
      ],
    ).createShader(rect);

    // Radial Gold Glow
    final glowGrad = RadialGradient(
      center: const Alignment(0.0, -0.1),
      radius: 0.55,
      colors: [
        const Color(0xFFFACC15).withOpacity(0.55),
        const Color(0xFFFACC15).withOpacity(0.0),
      ],
    ).createShader(rect);

    // 2. Setup Vector Paths
    // Outer Path: M55 2 L106 20 L106 78 Q106 120 55 148 Q4 120 4 78 L4 20 Z
    final pathOuter = Path()
      ..moveTo(w * 0.5, h * (2/150))
      ..lineTo(w * (106/110), h * (20/150))
      ..lineTo(w * (106/110), h * (78/150))
      ..quadraticBezierTo(w * (106/110), h * (120/150), w * 0.5, h * (148/150))
      ..quadraticBezierTo(w * (4/110), h * (120/150), w * (4/110), h * (78/150))
      ..lineTo(w * (4/110), h * (20/150))
      ..close();

    // Inner Path: M55 12 L96 26 L96 76 Q96 112 55 136 Q14 112 14 76 L14 26 Z
    final pathInner = Path()
      ..moveTo(w * 0.5, h * (12/150))
      ..lineTo(w * (96/110), h * (26/150))
      ..lineTo(w * (96/110), h * (76/150))
      ..quadraticBezierTo(w * (96/110), h * (112/150), w * 0.5, h * (136/150))
      ..quadraticBezierTo(w * (14/110), h * (112/150), w * (14/110), h * (76/150))
      ..lineTo(w * (14/110), h * (26/150))
      ..close();

    // 3. Draw Outer Shield
    final paintOuter = Paint()..shader = outerGrad;
    canvas.drawPath(pathOuter, paintOuter);

    // Sheen
    final paintSheen = Paint()..shader = sheenGrad;
    canvas.drawPath(pathOuter, paintSheen);

    // Gold Outer Stroke glow outline
    final paintOuterStroke = Paint()
      ..color = const Color(0xFFFACC15).withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(pathOuter, paintOuterStroke);

    // 4. Draw Inner Shield
    final paintInner = Paint()..shader = innerGrad;
    canvas.drawPath(pathInner, paintInner);

    // Glow overlay
    final paintGlow = Paint()..shader = glowGrad;
    canvas.drawPath(pathInner, paintGlow);

    // Gold Inner Stroke
    final paintInnerStroke = Paint()
      ..color = const Color(0xFFFACC15).withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(pathInner, paintInnerStroke);

    // 5. Draw Padlock (translated to center at 55, 74)
    canvas.save();
    canvas.translate(w * (55/110), h * (74/150));
    
    // Scale padlock to current dimensions
    final padlockScale = w / 110.0;
    canvas.scale(padlockScale);

    // Gold Paint
    final goldPaint = Paint()
      ..color = const Color(0xFFFACC15)
      ..style = PaintingStyle.fill;

    // Padlock Shackle Path
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
    canvas.drawPath(shacklePath, goldPaint);

    // Padlock Body
    final bodyRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-15, 0, 30, 24),
      const Radius.circular(4),
    );
    canvas.drawRRect(bodyRect, goldPaint);

    // Keyhole circle & slots
    final darkPaint = Paint()
      ..color = const Color(0xFF0B0836)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(0, 10), 3, darkPaint);
    canvas.drawRect(const Rect.fromLTWH(-1.2, 10, 2.4, 7), darkPaint);
    canvas.restore();

    // 6. Draw Checkmark: M40 108 L52 118 L72 96
    final checkmarkPath = Path()
      ..moveTo(w * (40/110), h * (108/150))
      ..lineTo(w * (52/110), h * (118/150))
      ..lineTo(w * (72/110), h * (96/150));

    final checkPaint = Paint()
      ..color = const Color(0xFF10B981)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(checkmarkPath, checkPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
