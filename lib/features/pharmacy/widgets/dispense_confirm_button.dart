// ─────────────────────────────────────────────────────────────
// AegisRx Pharmacy Widget — DispenseConfirmButton
// Migrated to AegisRx Design System
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:health_lock/core/theme/design_system.dart';

class DispenseConfirmButton extends StatelessWidget {
  final VoidCallback onConfirmed;
  final bool isEnabled;

  const DispenseConfirmButton({
    super.key,
    required this.onConfirmed,
    required this.isEnabled,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AegisTokens.btnHeight,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isEnabled ? AegisColors.primary : AegisTokens.btnPrimaryDisabled,
          foregroundColor: AegisColors.onPrimary,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: AegisRadius.button),
          textStyle: AegisTypography.labelLarge,
        ),
        onPressed: isEnabled ? onConfirmed : null,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline_rounded,
                size: AegisIconSize.sm),
            const SizedBox(width: AegisSpacing.sm),
            const Text('Confirm & Commit Dispensation'),
          ],
        ),
      ),
    );
  }
}
