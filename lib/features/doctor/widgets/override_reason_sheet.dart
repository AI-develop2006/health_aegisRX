// ─────────────────────────────────────────────────────────────
// AegisRx Doctor Widget — OverrideReasonSheet
// Migrated to AegisRx Design System
// Clinical bottom sheet for doctor clinical override
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:health_lock/core/theme/design_system.dart';

class OverrideReasonSheet extends StatefulWidget {
  final Function(String) onConfirmed;

  const OverrideReasonSheet({super.key, required this.onConfirmed});

  @override
  State<OverrideReasonSheet> createState() => _OverrideReasonSheetState();
}

class _OverrideReasonSheetState extends State<OverrideReasonSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AegisColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AegisRadius.xxl)),
      ),
      padding: EdgeInsets.fromLTRB(
        AegisSpacing.lg,
        AegisSpacing.base,
        AegisSpacing.lg,
        AegisSpacing.lg + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: AegisTokens.sheetHandleW,
              height: AegisTokens.sheetHandleH,
              decoration: BoxDecoration(
                color: AegisColors.border,
                borderRadius: AegisRadius.chip,
              ),
            ),
          ),
          const SizedBox(height: AegisSpacing.base),

          // Warning pill header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AegisSpacing.sm),
                decoration: BoxDecoration(
                  color: AegisColors.dangerLight,
                  borderRadius: BorderRadius.circular(AegisRadius.sm),
                ),
                child: const Icon(
                  Icons.gavel_rounded,
                  color: AegisColors.danger,
                  size: AegisIconSize.md,
                ),
              ),
              const SizedBox(width: AegisSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Clinical Override',
                      style: AegisTypography.titleLarge.copyWith(
                        color: AegisColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Override requires documented reasoning',
                      style: AegisTypography.bodySmall.copyWith(
                        color: AegisColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AegisSpacing.lg),

          // Warning callout
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AegisSpacing.md,
              vertical: AegisSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AegisColors.warningLight,
              borderRadius: BorderRadius.circular(AegisRadius.sm),
              border: Border.all(color: AegisColors.warning.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: AegisIconSize.sm,
                  color: AegisColors.warning,
                ),
                const SizedBox(width: AegisSpacing.sm),
                Expanded(
                  child: Text(
                    'This action will be recorded on the Hyperledger Fabric ledger.',
                    style: AegisTypography.labelSmall.copyWith(
                      color: AegisColors.warningDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AegisSpacing.base),

          // Reason text field
          TextField(
            controller: _controller,
            maxLines: 3,
            style: AegisTypography.bodyMedium.copyWith(color: AegisColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Document clinical reasoning for override...',
              hintStyle: AegisTypography.bodyMedium.copyWith(color: AegisColors.textTertiary),
              filled: true,
              fillColor: AegisColors.background,
              border: OutlineInputBorder(
                borderRadius: AegisRadius.input,
                borderSide: const BorderSide(color: AegisColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AegisRadius.input,
                borderSide: const BorderSide(color: AegisColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AegisRadius.input,
                borderSide: const BorderSide(color: AegisColors.primary, width: AegisBorders.regular),
              ),
              contentPadding: const EdgeInsets.all(AegisSpacing.md),
            ),
          ),
          const SizedBox(height: AegisSpacing.lg),

          // Confirm button — Primary action (Royal Blue) with danger emphasis icon
          SizedBox(
            height: AegisTokens.btnHeight,
            child: ElevatedButton(
              onPressed: () {
                widget.onConfirmed(_controller.text);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AegisColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: AegisRadius.button),
                textStyle: AegisTypography.labelLarge,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.verified_rounded, size: AegisIconSize.sm),
                  SizedBox(width: AegisSpacing.sm),
                  Text('Confirm & Sign Override'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
