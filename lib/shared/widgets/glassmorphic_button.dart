// ─────────────────────────────────────────────────────────────
// AegisRx Shared Widget — GlassmorphicButton
// Migrated to AegisRx Design System
// ─────────────────────────────────────────────────────────────

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:health_lock/core/theme/design_system.dart';

class GlassmorphicButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final double borderRadius;
  final Color? baseColor;

  const GlassmorphicButton({
    super.key,
    this.onPressed,
    required this.child,
    this.borderRadius = AegisRadius.md,
    this.baseColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final resolvedColor = baseColor ?? cs.primary;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: resolvedColor.withValues(alpha: 0.18),
            foregroundColor: Colors.white,
            shadowColor: Colors.transparent,
            elevation: 0,
            side: BorderSide(
              color: resolvedColor.withValues(alpha: 0.35),
              width: AegisBorders.thin,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AegisSpacing.lg,
              vertical: AegisSpacing.md,
            ),
            minimumSize: const Size.fromHeight(AegisTokens.btnHeight),
            textStyle: AegisTypography.labelLarge,
          ),
          onPressed: onPressed,
          child: child,
        ),
      ),
    );
  }
}
