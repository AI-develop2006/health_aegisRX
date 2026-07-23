// ════════════════════════════════════════════════════════════════════════════
// AegisRx — Patient Share Screen (QR Vault Access)
// Design System: AegisRx Clinical Precision
// Business logic: UNCHANGED — QR payload, appState reads, SnackBar logic preserved
// ════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/state/app_state.dart';
import '../../../core/theme/design_system.dart';

class PatientShareScreen extends StatelessWidget {
  const PatientShareScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    // UNCHANGED — same payload construction
    final patientId   = appState.patientMobileOrId;
    final patientName = appState.patientName;
    final qrPayload   = 'aegisrx://patient/$patientId/$patientName';

    return Scaffold(
      backgroundColor: AegisColors.background,
      appBar: AppBar(
        backgroundColor: AegisColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: AegisIconSize.sm, color: AegisColors.textSecondary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Share Vault Access',
          style: AegisTypography.headlineMedium.copyWith(
              color: AegisColors.textPrimary),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AegisColors.border),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AegisSpacing.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Section heading ────────────────────────────────
            Text(
              'Share your information',
              style: AegisTypography.displaySmall.copyWith(
                  color: AegisColors.textPrimary),
            ),
            const SizedBox(height: AegisSpacing.sm),
            Text(
              'Present the QR code below to your clinical doctor or pharmacist to authorize temporary session read access to your vault.',
              style: AegisTypography.bodyMedium.copyWith(
                color: AegisColors.textSecondary,
                height: 1.6,
              ),
            ),
            const SizedBox(height: AegisSpacing.lg),

            // ── Share with Doctor button (primary blue CTA) ────
            SizedBox(
              width: double.infinity,
              height: AegisTokens.btnHeight,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Doctor sharing integration is coming soon.',
                        style: AegisTypography.bodySmall
                            .copyWith(color: Colors.white),
                      ),
                      backgroundColor: AegisColors.primary,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                },
                icon: const Icon(Icons.send_rounded,
                    size: AegisIconSize.sm, color: Colors.white),
                label: Text(
                  'Share with my doctor',
                  style: AegisTypography.labelLarge.copyWith(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AegisColors.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: AegisRadius.button),
                  textStyle: AegisTypography.labelLarge,
                ),
              ),
            ),
            const SizedBox(height: AegisSpacing.lg),
            const Divider(color: AegisColors.border),
            const SizedBox(height: AegisSpacing.base),

            // ── QR Code Card ───────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AegisSpacing.xl),
              decoration: BoxDecoration(
                color: AegisColors.surface,
                borderRadius: AegisRadius.card,
                border: Border.all(color: AegisColors.border),
                boxShadow: AegisShadows.md,
              ),
              child: Column(
                children: [
                  Text(
                    'Scan to Connect',
                    style: AegisTypography.headlineSmall.copyWith(
                        color: AegisColors.textPrimary),
                  ),
                  const SizedBox(height: AegisSpacing.xs),
                  Text(
                    'Show this QR to your doctor or pharmacist.',
                    textAlign: TextAlign.center,
                    style: AegisTypography.bodySmall.copyWith(
                        color: AegisColors.textSecondary),
                  ),
                  const SizedBox(height: AegisSpacing.lg),

                  // QR code — blue primary color
                  Container(
                    padding: const EdgeInsets.all(AegisSpacing.base),
                    decoration: BoxDecoration(
                      color: AegisColors.surface,
                      borderRadius: AegisRadius.card,
                      border: Border.all(
                          color: AegisColors.primary.withValues(alpha: 0.3),
                          width: 2),
                      boxShadow: AegisShadows.primaryGlow,
                    ),
                    child: QrImageView(
                      data: qrPayload,
                      version: QrVersions.auto,
                      size: 180.0,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: AegisColors.primary,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: AegisColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: AegisSpacing.base),

                  // Patient ID tag — blue surface
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AegisSpacing.base,
                      vertical: AegisSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: AegisColors.primarySurface,
                      borderRadius: AegisRadius.chip,
                      border: Border.all(
                          color: AegisColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.badge_outlined,
                            size: AegisIconSize.sm, color: AegisColors.primary),
                        const SizedBox(width: AegisSpacing.xs),
                        Text(
                          'ID: $patientId',
                          style: AegisTypography.monoMedium.copyWith(
                            color: AegisColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AegisSpacing.base),

            // ── Warning note ───────────────────────────────────
            Container(
              padding: const EdgeInsets.all(AegisSpacing.md),
              decoration: BoxDecoration(
                color: AegisColors.warningLight,
                borderRadius: AegisRadius.card,
                border: Border.all(
                    color: AegisColors.warning.withValues(alpha: 0.4)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: AegisColors.warning, size: AegisIconSize.sm),
                  const SizedBox(width: AegisSpacing.sm),
                  Expanded(
                    child: Text(
                      'This QR code grants temporary read-only access. Only share with authorized medical personnel.',
                      style: AegisTypography.bodySmall.copyWith(
                        color: AegisColors.warningDark,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AegisSpacing.xxl),
          ],
        ),
      ),
    );
  }
}
