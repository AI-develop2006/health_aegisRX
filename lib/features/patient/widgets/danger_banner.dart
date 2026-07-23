// ─────────────────────────────────────────────────────────────
// AegisRx Patient Widget — DangerBanner
// Migrated to AegisRx Design System
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:health_lock/core/theme/design_system.dart';

class DangerBanner extends StatelessWidget {
  final String message;
  final IconData icon;
  final bool showBorder;

  const DangerBanner({
    super.key,
    required this.message,
    this.icon = Icons.warning_amber_rounded,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AegisColors.dangerLight,
        borderRadius: AegisRadius.card,
        border: showBorder
            ? Border.all(
                color: AegisColors.danger.withValues(alpha: 0.4),
                width: AegisBorders.thin,
              )
            : null,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AegisSpacing.base,
        vertical: AegisSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: AegisColors.danger,
            size: AegisIconSize.md,
          ),
          const SizedBox(width: AegisSpacing.md),
          Expanded(
            child: Text(
              message,
              style: AegisTypography.bodySmall.copyWith(
                color: AegisColors.dangerDark,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
