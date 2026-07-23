// ─────────────────────────────────────────────────────────────
// AegisRx Doctor Widget — InteractionWarningCard
// Migrated to AegisRx Design System
// Clinical CDSS drug interaction warning card
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:health_lock/core/theme/design_system.dart';

class InteractionWarningCard extends StatelessWidget {
  final String message;
  final String riskLevel; // LOW, MEDIUM, HIGH, CRITICAL

  const InteractionWarningCard({
    super.key,
    required this.message,
    required this.riskLevel,
  });

  Color _riskColor() {
    switch (riskLevel.toUpperCase()) {
      case 'HIGH':
      case 'CRITICAL':
        return AegisColors.danger;
      case 'MEDIUM':
        return AegisColors.warning;
      default:
        return AegisColors.success;
    }
  }

  Color _riskBg() {
    switch (riskLevel.toUpperCase()) {
      case 'HIGH':
      case 'CRITICAL':
        return AegisColors.dangerLight;
      case 'MEDIUM':
        return AegisColors.warningLight;
      default:
        return AegisColors.successLight;
    }
  }

  IconData _riskIcon() {
    switch (riskLevel.toUpperCase()) {
      case 'HIGH':
      case 'CRITICAL':
        return Icons.dangerous_outlined;
      case 'MEDIUM':
        return Icons.warning_amber_rounded;
      default:
        return Icons.check_circle_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _riskColor();
    final bg = _riskBg();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AegisSpacing.base),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AegisRadius.card,
        border: Border.all(color: color.withValues(alpha: 0.45), width: AegisBorders.thin),
        boxShadow: AegisShadows.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_riskIcon(), color: color, size: AegisIconSize.md),
          const SizedBox(width: AegisSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${riskLevel.toUpperCase()} RISK',
                  style: AegisTypography.labelCaps.copyWith(color: color),
                ),
                const SizedBox(height: AegisSpacing.xs),
                Text(
                  message,
                  style: AegisTypography.bodySmall.copyWith(
                    color: AegisColors.textPrimary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
