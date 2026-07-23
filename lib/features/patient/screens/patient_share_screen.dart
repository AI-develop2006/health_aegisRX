// ════════════════════════════════════════════════════════════════════════════
// AegisRx — Patient Share Screen (Single-Use Scan-Triggered QR Vault Access)
// Design System: AegisRx Clinical Precision
// ════════════════════════════════════════════════════════════════════════════

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/state/app_state.dart';
import '../../../core/theme/design_system.dart';

class PatientShareScreen extends StatefulWidget {
  const PatientShareScreen({super.key});

  @override
  State<PatientShareScreen> createState() => _PatientShareScreenState();
}

class _PatientShareScreenState extends State<PatientShareScreen> {
  late String _tokenNonce;
  String? _lastSeenRequestId;

  @override
  void initState() {
    super.initState();
    _generateNewNonce();
  }

  void _generateNewNonce() {
    final random = Random();
    final nonceVal = '${DateTime.now().microsecondsSinceEpoch}-${random.nextInt(10000)}';
    setState(() {
      _tokenNonce = nonceVal.replaceAll('-', '').substring(0, 10);
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final patientId = appState.patientMobileOrId;
    final patientName = appState.patientName;
    final int expiry = DateTime.now().add(const Duration(minutes: 10)).millisecondsSinceEpoch ~/ 1000;
    
    // Check if a new doctor scan request arrived -> auto-rotate token for the next scan
    if (appState.activePendingRequestId != null && appState.activePendingRequestId != _lastSeenRequestId) {
      _lastSeenRequestId = appState.activePendingRequestId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _generateNewNonce();
        }
      });
    }

    // Dynamic single-use session payload (stable during presentation, rotates upon scan completion)
    final qrPayload = 'aegisrx://patient/$patientId/$patientName?token=$_tokenNonce&exp=$expiry';

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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AegisColors.primary),
            onPressed: () {
              _generateNewNonce();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'QR Code token refreshed for next scan.',
                    style: AegisTypography.bodySmall.copyWith(color: Colors.white),
                  ),
                  backgroundColor: AegisColors.secondary,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            tooltip: 'Generate New QR Token',
          ),
        ],
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
              'Present the QR code below to your clinical doctor to authorize single-session read access to your vault.',
              style: AegisTypography.bodyMedium.copyWith(
                color: AegisColors.textSecondary,
                height: 1.6,
              ),
            ),
            const SizedBox(height: AegisSpacing.lg),

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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.verified_user_rounded,
                          size: AegisIconSize.sm, color: AegisColors.secondary),
                      const SizedBox(width: AegisSpacing.xs),
                      Text(
                        'Single-Use Consent QR',
                        style: AegisTypography.labelSmall.copyWith(
                          color: AegisColors.secondary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AegisSpacing.xs),
                  Text(
                    'Remains stable during scan, rotates after scan completion.',
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

                  // Status bar
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AegisSpacing.base,
                      vertical: AegisSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AegisColors.secondarySurface,
                      borderRadius: AegisRadius.chip,
                      border: Border.all(color: AegisColors.secondary.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.qr_code_scanner_rounded,
                            size: AegisIconSize.xs, color: AegisColors.secondary),
                        const SizedBox(width: AegisSpacing.xs),
                        Text(
                          'Ready for Doctor Scan',
                          style: AegisTypography.monoSmall.copyWith(
                            color: AegisColors.secondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AegisSpacing.sm),

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
                          'Patient ID: $patientId',
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

            // ── Security Note ───────────────────────────────────
            Container(
              padding: const EdgeInsets.all(AegisSpacing.md),
              decoration: BoxDecoration(
                color: AegisColors.surfaceDim,
                borderRadius: AegisRadius.card,
                border: Border.all(color: AegisColors.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.shield_outlined,
                      color: AegisColors.textSecondary, size: AegisIconSize.sm),
                  const SizedBox(width: AegisSpacing.sm),
                  Expanded(
                    child: Text(
                      'This QR code remains stable while being scanned by your doctor, and automatically rotates to a new single-use token once the scan session is completed.',
                      style: AegisTypography.bodySmall.copyWith(
                        color: AegisColors.textSecondary,
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
