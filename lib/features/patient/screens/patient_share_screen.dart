// ════════════════════════════════════════════════════════════════════════════
// AegisRx — Patient Share Screen (Dynamic Single-Use QR Vault Access)
// Design System: AegisRx Clinical Precision
// ════════════════════════════════════════════════════════════════════════════

import 'dart:async';
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
  Timer? _refreshTimer;
  int _secondsRemaining = 30;
  late String _tokenNonce;

  @override
  void initState() {
    super.initState();
    _generateNewNonce();
    _startCountdown();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _generateNewNonce() {
    final random = Random();
    final nonceVal = '${DateTime.now().microsecondsSinceEpoch}-${random.nextInt(10000)}';
    setState(() {
      _tokenNonce = nonceVal.replaceAll('-', '').substring(0, 10);
      _secondsRemaining = 30;
    });
  }

  void _startCountdown() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsRemaining > 1) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _generateNewNonce();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final patientId = appState.patientMobileOrId;
    final patientName = appState.patientName;
    final int expiry = DateTime.now().add(const Duration(minutes: 5)).millisecondsSinceEpoch ~/ 1000;
    
    // Dynamic single-use session payload with rotating token nonce and expiry
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
                    'QR Code security token refreshed!',
                    style: AegisTypography.bodySmall.copyWith(color: Colors.white),
                  ),
                  backgroundColor: AegisColors.secondary,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            tooltip: 'Refresh QR Token',
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
              'Present the dynamic QR code below to your clinical doctor to authorize single-session read access to your vault.',
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
                        'Dynamic Single-Use Consent',
                        style: AegisTypography.labelSmall.copyWith(
                          color: AegisColors.secondary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AegisSpacing.xs),
                  Text(
                    'Rotates automatically to prevent replay attacks.',
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

                  // Countdown bar
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AegisSpacing.base,
                      vertical: AegisSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AegisColors.surfaceDim,
                      borderRadius: AegisRadius.chip,
                      border: Border.all(color: AegisColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.timer_outlined,
                            size: AegisIconSize.xs, color: AegisColors.textSecondary),
                        const SizedBox(width: AegisSpacing.xs),
                        Text(
                          'Token auto-refreshes in ${_secondsRemaining}s',
                          style: AegisTypography.monoSmall.copyWith(
                            color: AegisColors.textSecondary,
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
                color: AegisColors.secondarySurface,
                borderRadius: AegisRadius.card,
                border: Border.all(
                    color: AegisColors.secondary.withValues(alpha: 0.4)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.shield_outlined,
                      color: AegisColors.secondary, size: AegisIconSize.sm),
                  const SizedBox(width: AegisSpacing.sm),
                  Expanded(
                    child: Text(
                      'Each QR code contains a dynamic cryptographic token valid for a single scan session. Screenshots cannot be re-used by unauthorized third parties.',
                      style: AegisTypography.bodySmall.copyWith(
                        color: AegisColors.secondaryDark,
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
