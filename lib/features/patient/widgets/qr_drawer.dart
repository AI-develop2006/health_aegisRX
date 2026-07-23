// ─────────────────────────────────────────────────────────────
// AegisRx Patient Widget — QrDrawer / showQrPopup
// Migrated to AegisRx Design System
// ─────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:health_lock/core/theme/design_system.dart';
import 'package:health_lock/shared/models/prescription.dart';
import '../../../core/state/app_state.dart';

/// Shows the QR code for a prescription as a popup modal dialog
void showQrPopup(BuildContext context, Prescription prescription) {
  final state = Provider.of<AppState>(context, listen: false);

  final String medsJson = jsonEncode(
      prescription.medicines.map((m) => m.toJson()).toList());

  final int expiry = DateTime.now()
          .add(const Duration(minutes: 10))
          .millisecondsSinceEpoch ~/
      1000;
  final String nonce =
      '${UniqueKey().hashCode}-${DateTime.now().microsecondsSinceEpoch}';
  const String scope = 'DISPENSE';

  final String rawPayload =
      '${prescription.id}|${prescription.doctorName}|${prescription.hospitalName}|${prescription.patientName}|${prescription.disease}|${prescription.date}|${prescription.time}|$medsJson|${prescription.doctorSignId}|$expiry|$nonce|$scope';
  final String qrCodeData = '$rawPayload##${prescription.signature}';

  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'QR Code Popup',
    barrierColor: Colors.black.withValues(alpha: 0.45),
    transitionDuration: AegisMotion.moderate,
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return ScaleTransition(
        scale: CurvedAnimation(parent: animation, curve: AegisMotion.emphasized),
        child: FadeTransition(opacity: animation, child: child),
      );
    },
    pageBuilder: (context, animation, secondaryAnimation) {
      return Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: AegisSpacing.xl),
            constraints: const BoxConstraints(maxWidth: 360),
            decoration: BoxDecoration(
              color: AegisColors.surface,
              borderRadius: AegisRadius.card,
              border: Border.all(color: AegisColors.border, width: AegisBorders.thin),
              boxShadow: AegisShadows.xl,
            ),
            child: Padding(
              padding: const EdgeInsets.all(AegisSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AegisSpacing.sm - 2),
                            decoration: BoxDecoration(
                              color: AegisColors.tertiarySurface,
                              borderRadius: BorderRadius.circular(AegisRadius.sm),
                            ),
                            child: const Icon(
                              Icons.qr_code_2_rounded,
                              color: AegisColors.tertiary,
                              size: AegisIconSize.md,
                            ),
                          ),
                          const SizedBox(width: AegisSpacing.sm),
                          Text(
                            'PHARMACY CHECKOUT QR',
                            style: AegisTypography.labelCaps.copyWith(
                              color: AegisColors.tertiary,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: const EdgeInsets.all(AegisSpacing.sm - 2),
                          decoration: BoxDecoration(
                            color: AegisColors.surfaceDim,
                            shape: BoxShape.circle,
                            border: Border.all(color: AegisColors.border),
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: AegisColors.textSecondary,
                            size: AegisIconSize.sm,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AegisSpacing.base),
                  const Divider(height: 1, color: AegisColors.border),
                  const SizedBox(height: AegisSpacing.lg),

                  // QR Code container
                  Container(
                    padding: const EdgeInsets.all(AegisSpacing.md),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AegisRadius.card,
                      border: Border.all(color: AegisColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: AegisColors.tertiary.withValues(alpha: 0.06),
                          blurRadius: 16,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: QrImageView(
                      data: qrCodeData,
                      version: QrVersions.auto,
                      size: 180,
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: AegisSpacing.base),

                  // Prescription info
                  Text(
                    prescription.disease,
                    style: AegisTypography.titleLarge.copyWith(
                      color: AegisColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AegisSpacing.xs),
                  Text(
                    'Dr. ${prescription.doctorName} • ${prescription.hospitalName}',
                    style: AegisTypography.bodySmall.copyWith(
                      color: AegisColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AegisSpacing.base),

                  // Instruction chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AegisSpacing.md,
                      vertical: AegisSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: AegisColors.tertiarySurface,
                      borderRadius: BorderRadius.circular(AegisRadius.sm),
                      border: Border.all(
                          color: AegisColors.tertiary.withValues(alpha: 0.20)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.qr_code_scanner_rounded,
                            size: AegisIconSize.xs, color: AegisColors.tertiary),
                        const SizedBox(width: AegisSpacing.sm),
                        Flexible(
                          child: Text(
                            'Scan at pharmacy to dispense medications',
                            style: AegisTypography.labelSmall.copyWith(
                              color: AegisColors.tertiary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AegisSpacing.sm),
                  Text(
                    '${state.backendUrl}/pharmacy-portal?rxId=${prescription.id}',
                    style: AegisTypography.monoSmall.copyWith(
                      color: AegisColors.textTertiary,
                      fontSize: 9,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

/// Legacy inline QR Drawer — kept for backward compatibility but now triggers popup
class QrDrawer extends StatelessWidget {
  final Prescription prescription;

  const QrDrawer({super.key, required this.prescription});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showQrPopup(context, prescription);
      final state = Provider.of<AppState>(context, listen: false);
      state.selectPrescription(null);
    });
    return const SizedBox.shrink();
  }
}
