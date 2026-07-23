// ─────────────────────────────────────────────────────────────
// AegisRx Shared Widget — LoadingOverlay
// Migrated to AegisRx Design System
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:health_lock/core/theme/design_system.dart';

class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? label;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          AnimatedOpacity(
            opacity: isLoading ? 1.0 : 0.0,
            duration: AegisMotion.moderate,
            curve: AegisMotion.standard,
            child: Container(
              color: AegisColors.background.withValues(alpha: 0.80),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AegisSpacing.lg,
                    vertical: AegisSpacing.base,
                  ),
                  decoration: BoxDecoration(
                    color: AegisColors.surface,
                    borderRadius: AegisRadius.card,
                    boxShadow: AegisShadows.lg,
                    border: Border.all(color: AegisColors.border),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AegisColors.primary,
                          backgroundColor: AegisColors.primarySurface,
                        ),
                      ),
                      if (label != null) ...[
                        const SizedBox(height: AegisSpacing.sm),
                        Text(
                          label!,
                          style: AegisTypography.labelMedium.copyWith(
                            color: AegisColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
