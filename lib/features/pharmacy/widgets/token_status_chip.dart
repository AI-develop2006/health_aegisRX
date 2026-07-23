// ─────────────────────────────────────────────────────────────
// AegisRx Pharmacy Widget — TokenStatusChip
// Migrated to AegisRx Design System
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:health_lock/core/theme/design_system.dart';

class TokenStatusChip extends StatelessWidget {
  final bool isDispensed;

  const TokenStatusChip({super.key, required this.isDispensed});

  @override
  Widget build(BuildContext context) {
    final chipColor = isDispensed ? AegisColors.danger : AegisColors.success;
    final chipBg    = isDispensed ? AegisColors.dangerLight : AegisColors.successLight;
    final chipText  = isDispensed ? 'BURNED · DISPENSED' : 'ACTIVE · AVAILABLE';
    final chipIcon  = isDispensed
        ? Icons.local_fire_department_rounded
        : Icons.verified_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AegisTokens.chipPaddingH,
        vertical: AegisTokens.chipPaddingV + 2,
      ),
      decoration: BoxDecoration(
        color: chipBg,
        borderRadius: AegisRadius.chip,
        border: Border.all(color: chipColor.withValues(alpha: 0.45), width: AegisBorders.thin),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(chipIcon, size: AegisIconSize.xs, color: chipColor),
          const SizedBox(width: AegisSpacing.xs),
          Text(
            chipText,
            style: AegisTypography.labelSmall.copyWith(
              color: chipColor,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
