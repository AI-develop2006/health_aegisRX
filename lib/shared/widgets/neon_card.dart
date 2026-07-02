import 'package:flutter/material.dart';

class NeonCard extends StatelessWidget {
  final Widget child;
  final Color neonColor;
  final double borderWidth;
  final EdgeInsetsGeometry padding;

  const NeonCard({
    super.key,
    required this.child,
    this.neonColor = const Color(0xFF00A86B), // emerald accent
    this.borderWidth = 1.0,
    this.padding = const EdgeInsets.all(16.0),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141A2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: neonColor.withOpacity(0.5),
          width: borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: neonColor.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: padding,
      child: child,
    );
  }
}
