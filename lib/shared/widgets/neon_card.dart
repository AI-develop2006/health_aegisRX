// ─────────────────────────────────────────────────────────────
// AegisRx Shared Widget — NeonCard
// Migrated to AegisRx Design System
// Repurposed as a glowing accent card for AI/Blockchain features
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:health_lock/core/theme/design_system.dart';

class NeonCard extends StatelessWidget {
  final Widget child;
  final Color? neonColor;
  final double borderWidth;
  final EdgeInsetsGeometry padding;

  const NeonCard({
    super.key,
    required this.child,
    this.neonColor,
    this.borderWidth = AegisBorders.thin,
    this.padding = const EdgeInsets.all(AegisTokens.cardPaddingV),
  });

  @override
  Widget build(BuildContext context) {
    // Default to AI violet — NeonCard is used for AI / blockchain accent panels
    final resolvedColor = neonColor ?? AegisColors.tertiary;

    return Container(
      decoration: BoxDecoration(
        color: AegisColors.surface,
        borderRadius: AegisRadius.card,
        border: Border.all(
          color: resolvedColor.withValues(alpha: 0.35),
          width: borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: resolvedColor.withValues(alpha: 0.08),
            blurRadius: 16,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: padding,
      child: child,
    );
  }
}
