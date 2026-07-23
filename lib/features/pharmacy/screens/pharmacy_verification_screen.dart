// ════════════════════════════════════════════════════════════════════════════
// AegisRx — Pharmacy Cryptographic Verification Screen
// Design System: AegisRx Clinical Precision
// Business logic: UNCHANGED — _performVerification(), verifyScan(), chain_verified,
//                 prescription data extraction, navigation to PharmacyDispenseScreen
// ════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/state/app_state.dart';
import '../../../core/theme/design_system.dart';
import 'pharmacy_dispense_screen.dart';

class PharmacyVerificationScreen extends StatefulWidget {
  final String rawPayload;
  final String signature;

  const PharmacyVerificationScreen({
    super.key,
    required this.rawPayload,
    required this.signature,
  });

  @override
  State<PharmacyVerificationScreen> createState() =>
      _PharmacyVerificationScreenState();
}

class _PharmacyVerificationScreenState
    extends State<PharmacyVerificationScreen> {
  bool _isLoading = true;
  bool _verified = false;
  String _verdict = 'UNKNOWN';
  String? _errorMsg;
  Map<String, dynamic>? _prescriptionData;
  bool _chainVerified = false;

  // ── BUSINESS LOGIC UNCHANGED ─────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _performVerification();
    });
  }

  void _performVerification() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final res = await appState.verifyScan(widget.rawPayload, widget.signature);

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _verified = res['verified'] == true;
      _verdict = res['verdict'] ?? 'UNKNOWN';
      _errorMsg = res['error'];
      _prescriptionData = res['prescription'];
      _chainVerified = res['chain_verified'] == true;
    });
  }
  // ── END BUSINESS LOGIC ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (_isLoading) {
      content = Padding(
        padding: const EdgeInsets.symmetric(vertical: 60.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AegisColors.secondary),
              const SizedBox(height: AegisSpacing.base),
              Text(
                'Cryptographically verifying signature & ledger state...',
                style: AegisTypography.bodyMedium.copyWith(color: AegisColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    } else if (!_verified) {
      content = Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AegisSpacing.base),
            decoration: BoxDecoration(
              color: AegisColors.dangerLight, // Critical Red
              borderRadius: AegisRadius.card,
              border: Border.all(color: AegisColors.danger.withValues(alpha: 0.4), width: 1.5),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: AegisColors.danger,
                  size: AegisIconSize.md,
                ),
                const SizedBox(width: AegisSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Verification Failed: $_verdict',
                        style: AegisTypography.titleSmall.copyWith(
                          color: AegisColors.danger,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _errorMsg ??
                            'Prescription verification failed. Signature is invalid or single-use token already burned.',
                        style: AegisTypography.bodySmall.copyWith(color: AegisColors.dangerDark),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AegisSpacing.lg),
          SizedBox(
            width: double.infinity,
            height: AegisTokens.btnHeight,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AegisColors.border),
                shape: RoundedRectangleBorder(borderRadius: AegisRadius.button),
              ),
              child: Text(
                'Back to Scanner',
                style: AegisTypography.labelLarge.copyWith(color: AegisColors.textSecondary),
              ),
            ),
          ),
        ],
      );
    } else {
      final rx = _prescriptionData!;
      final medsList = rx['medicines'] as List? ?? [];

      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Signature Verification Card ───────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AegisSpacing.base),
            decoration: BoxDecoration(
              color: AegisColors.secondarySurface, // Medical Teal surface
              borderRadius: AegisRadius.card,
              border: Border.all(color: AegisColors.secondary.withValues(alpha: 0.4), width: 1.5),
              boxShadow: AegisShadows.sm,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.verified_user_rounded,
                  color: AegisColors.secondary,
                  size: AegisIconSize.md,
                ),
                const SizedBox(width: AegisSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Signature Verified',
                        style: AegisTypography.titleSmall.copyWith(
                          color: AegisColors.secondary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Hash Match Succeeded. Doctor signature verified against NPI root key. Ledger Sync: ${_chainVerified ? "VERIFIED ON-CHAIN" : "LOCAL BLOCK"}',
                        style: AegisTypography.bodySmall.copyWith(color: AegisColors.textPrimary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AegisSpacing.lg),

          Text(
            'Prescription Details',
            style: AegisTypography.titleSmall.copyWith(color: AegisColors.textPrimary),
          ),
          const SizedBox(height: AegisSpacing.sm),

          // ── Prescription Summary Card ─────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AegisSpacing.base),
            decoration: BoxDecoration(
              color: AegisColors.surface,
              borderRadius: AegisRadius.card,
              border: Border.all(color: AegisColors.border),
              boxShadow: AegisShadows.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Prescription ID',
                      style: AegisTypography.labelSmall.copyWith(color: AegisColors.textTertiary),
                    ),
                    SelectableText(
                      '${rx['id']}',
                      style: AegisTypography.monoMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AegisColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AegisSpacing.md),
                _infoRow('Patient', rx['patientName'] ?? '—'),
                _infoRow('Diagnosis', rx['disease'] ?? '—'),
                _infoRow('Clinician', '${rx['doctorName']} (NPI: ${rx['doctorSignId']})'),
                _infoRow('Hospital', rx['hospitalName'] ?? '—'),
                _infoRow('Date & Time', '${rx['date']} • ${rx['time']}'),
                const Divider(height: AegisSpacing.lg, color: AegisColors.border),
                Text(
                  'Prescribed Medications (${medsList.length})',
                  style: AegisTypography.labelSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AegisColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AegisSpacing.sm),

                // Large Readable Medicine Cards
                ...medsList.map((m) {
                  final List<String> timings = [];
                  if (m['morning'] == true) timings.add('Morning');
                  if (m['afternoon'] == true) timings.add('Afternoon');
                  if (m['evening'] == true) timings.add('Evening');
                  if (m['night'] == true) timings.add('Night');
                  final timingStr = timings.isEmpty
                      ? m['interval']
                      : timings.join(', ');
                  final foodStr = m['beforeFood'] == true
                      ? 'Before Food'
                      : (m['afterFood'] == true ? 'After Food' : 'As advised');
                  final custom =
                      m['customInstruction'] != null &&
                          m['customInstruction'].toString().isNotEmpty
                      ? m['customInstruction']
                      : null;

                  return Container(
                    margin: const EdgeInsets.only(bottom: AegisSpacing.sm),
                    padding: const EdgeInsets.all(AegisSpacing.md),
                    decoration: BoxDecoration(
                      color: AegisColors.background,
                      borderRadius: BorderRadius.circular(AegisRadius.sm),
                      border: Border.all(color: AegisColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AegisSpacing.xs),
                              decoration: BoxDecoration(
                                color: AegisColors.secondarySurface,
                                borderRadius: BorderRadius.circular(AegisRadius.xs),
                              ),
                              child: const Icon(
                                Icons.medication_rounded,
                                color: AegisColors.secondary,
                                size: AegisIconSize.xs,
                              ),
                            ),
                            const SizedBox(width: AegisSpacing.sm),
                            Expanded(
                              child: Text(
                                '${m['name']}',
                                style: AegisTypography.titleSmall.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AegisColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AegisSpacing.xs),
                        Wrap(
                          spacing: AegisSpacing.xs,
                          runSpacing: AegisSpacing.xs,
                          children: [
                            _pillBadge(timingStr, AegisColors.secondary),
                            _pillBadge(foodStr, AegisColors.primary),
                          ],
                        ),
                        if (custom != null) ...[
                          const SizedBox(height: AegisSpacing.xs),
                          Text(
                            'Instructions: $custom',
                            style: AegisTypography.bodySmall.copyWith(
                              color: AegisColors.textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),

          // ── Clinical Override Card (Amber Warning) ────────────
          if (rx['overrideReason'] != null &&
              rx['overrideReason'].toString().trim().isNotEmpty) ...[
            const SizedBox(height: AegisSpacing.lg),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AegisSpacing.base),
              decoration: BoxDecoration(
                color: AegisColors.warningLight, // Warning Amber
                borderRadius: AegisRadius.card,
                border: Border.all(color: AegisColors.warning.withValues(alpha: 0.4), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: AegisColors.warning,
                        size: AegisIconSize.sm,
                      ),
                      const SizedBox(width: AegisSpacing.xs),
                      Text(
                        'CLINICAL OVERRIDE DETECTED',
                        style: AegisTypography.labelSmall.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AegisColors.warning,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AegisSpacing.xs),
                  Text(
                    'This prescription triggered AI safety warnings. The prescribing clinician submitted the following override justification:',
                    style: AegisTypography.bodySmall.copyWith(color: AegisColors.textPrimary),
                  ),
                  const SizedBox(height: AegisSpacing.xs),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AegisSpacing.sm),
                    decoration: BoxDecoration(
                      color: AegisColors.surface,
                      borderRadius: BorderRadius.circular(AegisRadius.sm),
                      border: Border.all(color: AegisColors.warning.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      '"${rx['overrideReason']}"',
                      style: AegisTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        fontStyle: FontStyle.italic,
                        color: AegisColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AegisSpacing.xl),

          // ── Primary Action CTA Button (Royal Blue) ────────────
          SizedBox(
            width: double.infinity,
            height: AegisTokens.btnHeight,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PharmacyDispenseScreen(
                      prescriptionId: rx['id'],
                      prescriptionName: rx['patientName'],
                      medicines: medsList,
                    ),
                  ),
                );
              },
              icon: const Icon(
                Icons.inventory_2_rounded,
                color: Colors.white,
                size: AegisIconSize.sm,
              ),
              label: Text(
                'Proceed to Dispensation Desk',
                style: AegisTypography.labelLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AegisColors.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: AegisRadius.button,
                ),
              ),
            ),
          ),
          const SizedBox(height: AegisSpacing.xxl),
        ],
      );
    }

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
          'Cryptographic Verification',
          style: AegisTypography.headlineMedium.copyWith(color: AegisColors.textPrimary),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AegisColors.border),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AegisSpacing.pagePadding),
        child: content,
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AegisTypography.bodySmall.copyWith(color: AegisColors.textSecondary)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AegisTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: AegisColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pillBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AegisSpacing.sm, vertical: AegisSpacing.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AegisRadius.xs),
        border: Border.all(color: color.withValues(alpha: 0.3), width: AegisBorders.thin),
      ),
      child: Text(
        label,
        style: AegisTypography.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
