// ════════════════════════════════════════════════════════════════════════════
// AegisRx — Pharmacy Terminal Authentication Screen
// Design System: AegisRx Clinical Precision
// Business logic: UNCHANGED — _keyConnected, _verify(), verifyPharmacyTerminal(),
//                 resetFlow() preserved
// ════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/state/app_state.dart';
import '../../../core/theme/design_system.dart';

class PharmacyTerminalAuthScreen extends StatefulWidget {
  const PharmacyTerminalAuthScreen({super.key});

  @override
  State<PharmacyTerminalAuthScreen> createState() => _PharmacyTerminalAuthScreenState();
}

class _PharmacyTerminalAuthScreenState extends State<PharmacyTerminalAuthScreen> {
  bool _keyConnected = false;

  // ── BUSINESS LOGIC UNCHANGED ─────────────────────────────────────────────
  void _verify() {
    if (!_keyConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please connect your hardware YubiKey device before verifying.',
              style: AegisTypography.bodySmall.copyWith(color: Colors.white)),
          backgroundColor: AegisColors.danger,
        ),
      );
      return;
    }

    final appState = Provider.of<AppState>(context, listen: false);
    appState.verifyPharmacyTerminal();
  }
  // ── END BUSINESS LOGIC ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isVerified = appState.isTerminalVerified;
    final statusColor = isVerified ? AegisColors.secondary : AegisColors.danger;
    final statusBg = isVerified ? AegisColors.secondarySurface : AegisColors.dangerLight;

    return Scaffold(
      backgroundColor: AegisColors.background,
      appBar: AppBar(
        backgroundColor: AegisColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text('Terminal Authentication', style: AegisTypography.headlineMedium.copyWith(color: AegisColors.textPrimary)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: AegisIconSize.sm, color: AegisColors.textSecondary),
          onPressed: () {
            appState.resetFlow();
          },
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AegisColors.border),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AegisSpacing.pagePadding),
          child: Container(
            padding: const EdgeInsets.all(AegisSpacing.lg),
            decoration: BoxDecoration(
              color: AegisColors.surface,
              borderRadius: AegisRadius.card,
              border: Border.all(color: statusColor.withValues(alpha: 0.4), width: 1.5),
              boxShadow: AegisShadows.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(AegisSpacing.lg),
                  decoration: BoxDecoration(
                    color: statusBg,
                    shape: BoxShape.circle,
                    border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 1.5),
                  ),
                  child: Icon(
                    isVerified ? Icons.computer_rounded : Icons.no_encryption_gmailerrorred_rounded,
                    size: 60,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: AegisSpacing.lg),
                Text(
                  isVerified ? 'Terminal Authenticated' : 'Untrusted Terminal Access',
                  style: AegisTypography.headlineMedium.copyWith(
                    color: AegisColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AegisSpacing.sm),
                Text(
                  isVerified
                      ? 'Secure workstation environment confirmed. Token-redemption API gateway endpoints are now enabled.'
                      : 'Hardware security validation failed. Workstation certificate is untrusted. Token APIs and scanning are disabled.',
                  textAlign: TextAlign.center,
                  style: AegisTypography.bodyMedium.copyWith(
                    color: AegisColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: AegisSpacing.lg),
                const Divider(color: AegisColors.border),
                const SizedBox(height: AegisSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Workstation ID:',
                      style: AegisTypography.labelSmall.copyWith(
                        color: AegisColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'STATION-PH-7729',
                      style: AegisTypography.monoSmall.copyWith(
                        color: AegisColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AegisSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Hardware YubiKey:',
                      style: AegisTypography.labelSmall.copyWith(
                        color: AegisColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      _keyConnected ? 'Key Detected' : 'Not Connected',
                      style: AegisTypography.labelSmall.copyWith(
                        fontWeight: FontWeight.w800,
                        color: _keyConnected ? AegisColors.secondary : AegisColors.danger,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AegisSpacing.lg),
                if (!isVerified) ...[
                  Container(
                    decoration: BoxDecoration(
                      color: AegisColors.background,
                      borderRadius: BorderRadius.circular(AegisRadius.sm),
                      border: Border.all(color: AegisColors.border),
                    ),
                    child: CheckboxListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: AegisSpacing.sm),
                      value: _keyConnected,
                      activeColor: AegisColors.primary,
                      title: Text(
                        'Simulate hardware key connection',
                        style: AegisTypography.bodySmall.copyWith(color: AegisColors.textPrimary, fontWeight: FontWeight.w600),
                      ),
                      onChanged: (val) {
                        setState(() {
                          _keyConnected = val ?? false;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: AegisSpacing.base),
                  SizedBox(
                    width: double.infinity,
                    height: AegisTokens.btnHeight,
                    child: ElevatedButton(
                      onPressed: _verify,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AegisColors.primary, // Royal Blue Primary Action
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: AegisRadius.button,
                        ),
                      ),
                      child: Text(
                        'Verify Terminal',
                        style: AegisTypography.labelLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AegisSpacing.md),
                TextButton(
                  onPressed: () {
                    appState.resetFlow();
                  },
                  child: Text(
                    'Return to Role Selection',
                    style: AegisTypography.labelSmall.copyWith(
                      color: AegisColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
