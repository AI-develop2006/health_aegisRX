import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/state/app_state.dart';

// ── Design Tokens ──────────────────────────────────────────────────────────
const _kBg       = Color(0xFF0A0F1D);  // 60% Midnight Navy
const _kCard     = Color(0xFF1E293B);  // 30% Slate container
const _kBorder   = Color(0xFF334155);  // 30% Border
const _kAccent   = Color(0xFF0EA5E9);  // 10% Cyber Shield Blue
const _kSuccess  = Color(0xFF10B981);  // Mint Emerald
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

  late Animation<double> _shieldScale;
  late Animation<double> _shieldOpacity;
  late Animation<double> _ringPulse;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _progressVal;

  @override
  void initState() {
    super.initState();

    // Shield animation: 0 → 800ms
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
    _ringPulse = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _shieldCtrl, curve: Curves.easeInOut),
    );

    // Text animation: 500ms → 1400ms
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

    // Progress fill: 0 → 2500ms
    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _progressVal = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressCtrl, curve: Curves.easeInOut),
    );

    // Staggered start
    _shieldCtrl.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _textCtrl.forward();
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _progressCtrl.forward();
    });

    // Pulse shield after initial animation
    _shieldCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        _shieldCtrl.repeat(reverse: true);
      }
    });

    // Navigate after 2.5 seconds
    Timer(const Duration(milliseconds: 2600), () {
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          // Security mesh background
          Positioned.fill(
            child: CustomPaint(painter: SecurityMeshPainter()),
          ),

          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Animated Shield Badge ──────────────────────
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
                      // Outer glow ring
                      AnimatedBuilder(
                        animation: _ringPulse,
                        builder: (_, __) => Transform.scale(
                          scale: _ringPulse.value,
                          child: Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _kAccent.withValues(alpha: 0.15),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Inner ring
                      Container(
                        width: 112,
                        height: 112,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _kCard,
                          border: Border.all(color: _kAccent.withValues(alpha: 0.4), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: _kAccent.withValues(alpha: 0.25),
                              blurRadius: 28,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          CupertinoIcons.shield_fill,
                          size: 52,
                          color: _kAccent,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 36),

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

                // ── Progress bar ───────────────────────────────
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
                    color: _kMuted.withValues(alpha: 0.5),
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
      ..color = const Color(0xFF0EA5E9).withValues(alpha: 0.03)
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
    // Diagonal accent lines
    final diagPaint = Paint()
      ..color = const Color(0xFF0EA5E9).withValues(alpha: 0.015)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    for (double d = -size.height; d <= size.width + size.height; d += step * 3) {
      canvas.drawLine(Offset(d, 0), Offset(d + size.height, size.height), diagPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
