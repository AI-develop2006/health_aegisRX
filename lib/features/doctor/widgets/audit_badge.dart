// ─────────────────────────────────────────────────────────────
// AegisRx Doctor Widget — AuditBadge
// Migrated to AegisRx Design System
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:health_lock/core/theme/design_system.dart';

class AuditBadge extends StatelessWidget {
  final int severityScore;

  const AuditBadge({super.key, required this.severityScore});

  Color _badgeColor() {
    if (severityScore >= 8) return AegisColors.danger;
    if (severityScore >= 5) return AegisColors.warning;
    return AegisColors.success;
  }

  Color _badgeBg() {
    if (severityScore >= 8) return AegisColors.dangerLight;
    if (severityScore >= 5) return AegisColors.warningLight;
    return AegisColors.successLight;
  }

  @override
  Widget build(BuildContext context) {
    final color = _badgeColor();
    final bg = _badgeBg();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AegisTokens.chipPaddingH,
        vertical: AegisTokens.chipPaddingV,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AegisRadius.chip,
        border: Border.all(color: color.withValues(alpha: 0.5), width: AegisBorders.thin),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shield_outlined, size: AegisIconSize.xs, color: color),
          const SizedBox(width: AegisSpacing.xs),
          Text(
            'Score: $severityScore/10',
            style: AegisTypography.labelSmall.copyWith(
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
