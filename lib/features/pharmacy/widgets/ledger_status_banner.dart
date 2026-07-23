// ─────────────────────────────────────────────────────────────
// AegisRx Pharmacy Widget — LedgerStatusBanner
// Migrated to AegisRx Design System
// Blockchain / Hyperledger Fabric transaction confirmation
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:health_lock/core/theme/design_system.dart';

class LedgerStatusBanner extends StatelessWidget {
  final String txHash;

  const LedgerStatusBanner({super.key, required this.txHash});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AegisSpacing.md),
      decoration: BoxDecoration(
        color: AegisTokens.blockchainBadgeBg,
        borderRadius: AegisRadius.card,
        border: Border.all(
          color: AegisTokens.blockchainBadgeFg.withValues(alpha: 0.25),
          width: AegisBorders.thin,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: AegisTokens.blockchainBadgeFg,
            size: AegisIconSize.md,
          ),
          const SizedBox(width: AegisSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LEDGER COMMITTED',
                  style: AegisTypography.labelCaps.copyWith(
                    color: AegisTokens.blockchainBadgeFg,
                  ),
                ),
                const SizedBox(height: AegisSpacing.xs),
                Text(
                  txHash,
                  style: AegisTypography.monoSmall.copyWith(
                    color: AegisColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ),
          ),
          const SizedBox(width: AegisSpacing.sm),
          // Copy hash button
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: txHash));
            },
            child: const Icon(
              Icons.copy_rounded,
              size: AegisIconSize.sm,
              color: AegisTokens.blockchainBadgeFg,
            ),
          ),
        ],
      ),
    );
  }
}
