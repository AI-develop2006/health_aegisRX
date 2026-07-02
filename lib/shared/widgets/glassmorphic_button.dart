import 'dart:ui';
import 'package:flutter/material.dart';

class GlassmorphicButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;
  final double borderRadius;
  final Color baseColor;

  const GlassmorphicButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.borderRadius = 12.0,
    this.baseColor = const Color(0xFF0F52BA),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: baseColor.withOpacity(0.2),
            foregroundColor: Colors.white,
            side: BorderSide(
              color: baseColor.withOpacity(0.4),
              width: 1.0,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            elevation: 0,
          ),
          onPressed: onPressed,
          child: child,
        ),
      ),
    );
  }
}
