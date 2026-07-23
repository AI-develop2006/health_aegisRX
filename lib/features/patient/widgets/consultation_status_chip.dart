// ─────────────────────────────────────────────────────────────
// AegisRx Patient Widget — ConsultationStatusChip
// Migrated to AegisRx Design System
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:health_lock/core/theme/design_system.dart';

class ConsultationStatusChip extends StatelessWidget {
  final String status;

  const ConsultationStatusChip({super.key, required this.status});

  Color _chipColor() {
    switch (status.toLowerCase()) {
      case 'active':
      case 'accepted':
        return AegisColors.success;
      case 'pending':
        return AegisColors.warning;
      case 'rejected':
        return AegisColors.danger;
      default:
        return AegisColors.textTertiary;
    }
  }

  Color _chipBg() {
    switch (status.toLowerCase()) {
      case 'active':
      case 'accepted':
        return AegisColors.successLight;
      case 'pending':
        return AegisColors.warningLight;
      case 'rejected':
        return AegisColors.dangerLight;
      default:
        return AegisColors.surfaceDim;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _chipColor();
    final bg = _chipBg();
    final label = status.toLowerCase() == 'inactive'
        ? 'NO SESSION'
        : status.toUpperCase();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AegisTokens.chipPaddingH,
        vertical: AegisTokens.chipPaddingV + 2,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AegisRadius.chip,
        border: Border.all(color: color.withValues(alpha: 0.4), width: AegisBorders.thin),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AegisSpacing.xs + 2),
          Text(
            label,
            style: AegisTypography.labelSmall.copyWith(
              color: color,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}
