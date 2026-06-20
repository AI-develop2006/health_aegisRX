import 'dart:async';
import 'package:flutter/material.dart';
import 'package:health_lock/core/constants/app_colors.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onFinished;
  const SplashScreen({super.key, required this.onFinished});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.repeat(reverse: true);

    // Transition automatically to Onboarding flow after 2.5 seconds
    Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        widget.onFinished();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.baseCanvas,
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Clean Light Background Gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.0,
                  colors: [
                    Colors.white,
                    AppColors.baseCanvas,
                  ],
                  stops: [0.0, 1.0],
                ),
              ),
            ),
          ),

          // Central Pulsing Lock/Shield Logo (Centered)
          Center(
            child: ScaleTransition(
              scale: _pulseAnimation,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Custom Geometric Shield Logo
                  SizedBox(
                    width: 100,
                    height: 110,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: const Size(100, 110),
                          painter: GeometricShieldPainter(
                            color: AppColors.patientBlue,
                          ),
                        ),
                        const Positioned(
                          top: 32,
                          left: 0,
                          right: 0,
                          child: Icon(
                            Icons.lock_rounded,
                            size: 38,
                            color: AppColors.patientBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Rebranded Title Text
                  Text(
                    'HEALTHLOCK',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.primaryText,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 4.0,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'SECURE MEDICAL VAULT',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.mutedText,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Footer version or loading text
          Positioned(
            bottom: 40,
            child: Text(
              'v1.0.0 • Protected by End-to-End Encryption',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.mutedText.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GeometricShieldPainter extends CustomPainter {
  final Color color;

  GeometricShieldPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;

    final path = Path();
    final w = size.width;
    final h = size.height;

    // Outer geometric shield (Hexagonal top, pointed bottom)
    path.moveTo(w / 2, 0);
    path.lineTo(w, h * 0.25);
    path.lineTo(w, h * 0.72);
    path.lineTo(w / 2, h);
    path.lineTo(0, h * 0.72);
    path.lineTo(0, h * 0.25);
    path.close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, paint);

    // Inner geometric shield lines for high-fidelity technical look
    final innerPath = Path();
    const inset = 9.0;
    final ih = h - inset * 2;

    innerPath.moveTo(w / 2, inset);
    innerPath.lineTo(w - inset, inset + ih * 0.25);
    innerPath.lineTo(w - inset, inset + ih * 0.72);
    innerPath.lineTo(w / 2, h - inset);
    innerPath.lineTo(inset, inset + ih * 0.72);
    innerPath.lineTo(inset, inset + ih * 0.25);
    innerPath.close();

    final innerPaint = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawPath(innerPath, innerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
