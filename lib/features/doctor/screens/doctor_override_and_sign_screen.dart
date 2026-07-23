// ════════════════════════════════════════════════════════════════════════════
// AegisRx — Doctor Override and Sign Screen
// Design System: AegisRx Clinical Precision
// Business logic: UNCHANGED — _generateMockHash(), _signAndCommit(), createPrescription(),
//                 onchain_tx_hash verification, signature flow preserved exactly
// ════════════════════════════════════════════════════════════════════════════

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/state/app_state.dart';
import '../../../core/theme/design_system.dart';
import '../doctor_theme.dart';

class DoctorOverrideAndSignScreen extends StatefulWidget {
  final String patientId;
  final String patientName;
  final String chiefComplaint;
  final String diagnosis;
  final List<Map<String, dynamic>> medications;
  final String riskBand;
  final int riskScore;
  final List<String> riskReasons;
  final String action;

  const DoctorOverrideAndSignScreen({
    super.key,
    required this.patientId,
    required this.patientName,
    required this.chiefComplaint,
    required this.diagnosis,
    required this.medications,
    required this.riskBand,
    required this.riskScore,
    required this.riskReasons,
    required this.action,
  });

  @override
  State<DoctorOverrideAndSignScreen> createState() =>
      _DoctorOverrideAndSignScreenState();
}

class _DoctorOverrideAndSignScreenState
    extends State<DoctorOverrideAndSignScreen> {
  final _rationaleController = TextEditingController();
  String _overrideCategory = 'Clinical judgment';
  bool _isAcknowledged = false;
  bool _isSigning = false;

  // ── BUSINESS LOGIC UNCHANGED ─────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppState>(context, listen: false).pausePolling(
        screen: 'DoctorOverrideAndSignScreen',
        reason: 'Doctor overriding and signing prescription',
      );
    });
  }

  @override
  void dispose() {
    _rationaleController.dispose();
    super.dispose();
  }

  String _generateMockHash() {
    final random = Random();
    const chars = '0123456789abcdef';
    String hash = '0x';
    for (int i = 0; i < 40; i++) {
      hash += chars[random.nextInt(chars.length)];
    }
    return hash;
  }

  void _signAndCommit() {
    final bool requiresOverride =
        widget.action == 'REQUIRE_OVERRIDE' || widget.action == 'BLOCK_UNLESS_OVERRIDE';

    if (requiresOverride) {
      if (_rationaleController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please specify the clinical rationale.', style: AegisTypography.bodySmall.copyWith(color: Colors.white)),
            backgroundColor: AegisColors.warning,
          ),
        );
        return;
      }
      if (!_isAcknowledged) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please check the Physician Acknowledgement box.', style: AegisTypography.bodySmall.copyWith(color: Colors.white)),
            backgroundColor: AegisColors.warning,
          ),
        );
        return;
      }
    }

    setState(() => _isSigning = true);

    final appState = Provider.of<AppState>(context, listen: false);
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final List<Map<String, dynamic>> medicinesPayload =
        widget.medications.map((med) {
      return {
        'name': '${med['name']} ${med['strength']}'.trim(),
        'interval': med['frequency'] ?? 'Once daily',
        'morning': med['morning'] == true,
        'afternoon': med['afternoon'] == true,
        'evening': med['evening'] == true,
        'night': med['night'] == true,
        'beforeFood': med['beforeFood'] == true,
        'afterFood': med['afterFood'] == true,
        'customInstruction': med['instructions'] ?? '',
      };
    }).toList();

    final randomRxId = 'RX-${1000 + Random().nextInt(9000)}';
    final rxData = {
      'id': randomRxId,
      'doctorName': appState.doctorName != null
          ? (appState.doctorName!.startsWith('Dr.')
              ? appState.doctorName!
              : 'Dr. ${appState.doctorName!}')
          : 'Dr. Alexander Vance',
      'hospitalName':
          appState.doctorHospital ?? 'Metropolitan Hospital Centre',
      'patientName': widget.patientName,
      'patient_id': widget.patientId,
      'disease': widget.diagnosis,
      'date': dateStr,
      'time': timeStr,
      'medicines': medicinesPayload,
      'doctorSignId': appState.doctorLicense ?? '889218',
      'riskBand': widget.riskBand,
      'overrideReason':
          requiresOverride ? _rationaleController.text.trim() : null,
    };

    appState.createPrescription(rxData).then((res) {
      if (!mounted) return;
      setState(() => _isSigning = false);

      if (res['error'] != null || res['detail'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${res['error'] ?? res['detail'] ?? 'Prescription failed'}', style: AegisTypography.bodySmall.copyWith(color: Colors.white)),
            backgroundColor: AegisColors.danger,
          ),
        );
        return;
      }

      final txHash = res['onchain_tx_hash'] ?? (appState.useMockFrontend ? _generateMockHash() : null);
      if (txHash == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('On-chain signature failed: EVM node transaction reverted. Mocks disabled.', style: AegisTypography.bodySmall.copyWith(color: Colors.white)),
            backgroundColor: AegisColors.danger,
          ),
        );
        return;
      }
      final signature = res['signature'] ?? 'Unknown signature';

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            backgroundColor: AegisColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: AegisRadius.card,
              side: const BorderSide(color: AegisColors.border),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AegisSpacing.xs),
                  decoration: BoxDecoration(
                    color: AegisColors.secondarySurface,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.verified_user_rounded,
                      color: AegisColors.secondary, size: AegisIconSize.sm),
                ),
                const SizedBox(width: AegisSpacing.sm),
                Expanded(
                  child: Text('Prescription Committed',
                      style: AegisTypography.headlineSmall.copyWith(color: AegisColors.textPrimary),
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Prescription has been encrypted, signed, and recorded on the blockchain ledger.',
                    style: AegisTypography.bodySmall.copyWith(color: AegisColors.textSecondary),
                  ),
                  const SizedBox(height: AegisSpacing.md),
                  Text('Ledger Transaction Hash',
                      style: AegisTypography.labelSmall.copyWith(color: AegisColors.textPrimary, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AegisSpacing.sm),
                    decoration: BoxDecoration(
                      color: AegisColors.tertiarySurface, // AI / Blockchain Purple
                      borderRadius: BorderRadius.circular(AegisRadius.sm),
                      border: Border.all(color: AegisColors.tertiary.withValues(alpha: 0.3)),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SelectableText(
                        txHash,
                        style: AegisTypography.monoSmall.copyWith(
                            color: AegisColors.tertiary, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(height: AegisSpacing.sm),
                  Text('Cryptographic Signature', style: AegisTypography.labelSmall.copyWith(color: AegisColors.textPrimary, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AegisSpacing.sm),
                    decoration: BoxDecoration(
                      color: AegisColors.background,
                      borderRadius: BorderRadius.circular(AegisRadius.sm),
                      border: Border.all(color: AegisColors.border),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SelectableText(
                        signature,
                        style: AegisTypography.monoSmall.copyWith(color: AegisColors.textTertiary),
                      ),
                    ),
                  ),
                  const SizedBox(height: AegisSpacing.sm),
                  const DoctorStatusBadge(
                    label: 'Active — Burn on Dispense',
                    color: AegisColors.secondary,
                    icon: Icons.local_fire_department_rounded,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  appState.endDoctorPatientSession();
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                child: Text('Back to Dashboard',
                    style: AegisTypography.labelMedium.copyWith(
                        color: AegisColors.primary, fontWeight: FontWeight.w700)),
              ),
            ],
          );
        },
      );
    });
  }
  // ── END BUSINESS LOGIC ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bool requiresOverride =
        widget.action == 'REQUIRE_OVERRIDE' || widget.action == 'BLOCK_UNLESS_OVERRIDE';

    Color getBannerColor() {
      switch (widget.action.toUpperCase()) {
        case 'REQUIRE_OVERRIDE':
          return AegisColors.warning; // Orange for Warning
        case 'BLOCK_UNLESS_OVERRIDE':
          return AegisColors.danger;  // Red for Critical block
        default:
          return AegisColors.danger;
      }
    }
    final bannerColor = getBannerColor();
    final bannerBg = widget.action == 'REQUIRE_OVERRIDE' ? AegisColors.warningLight : AegisColors.dangerLight;

    return ClinicalScaffold(
      appBar: clinicalAppBar(title: 'Clinical Verification & Sign'),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AegisSpacing.pagePadding,
              AegisSpacing.base,
              AegisSpacing.pagePadding,
              100,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Risk Alert Banner (shown only if required) ──
                if (requiresOverride) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AegisSpacing.base),
                    decoration: BoxDecoration(
                      color: bannerBg,
                      borderRadius: AegisRadius.card,
                      border: Border.all(
                          color: bannerColor.withValues(alpha: 0.4), width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.dangerous_rounded,
                                color: bannerColor, size: AegisIconSize.sm),
                            const SizedBox(width: AegisSpacing.sm),
                            Expanded(
                              child: Text(
                                'AI Risk: ${widget.riskBand} · Score ${widget.riskScore}/100',
                                style: AegisTypography.titleSmall.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: bannerColor),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AegisSpacing.sm),
                        ...widget.riskReasons.map((reason) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text('· ',
                                      style: TextStyle(
                                          color: bannerColor,
                                          fontWeight: FontWeight.bold)),
                                  Expanded(
                                    child: Text(
                                      reason,
                                      style: AegisTypography.bodySmall.copyWith(color: bannerColor),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                      ],
                    ),
                  ),
                  const SizedBox(height: AegisSpacing.lg),
                ] else ...[
                  // ── Safe Banner ─────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AegisSpacing.base,
                      vertical: AegisSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: AegisColors.secondarySurface,
                      borderRadius: AegisRadius.card,
                      border: Border.all(
                          color: AegisColors.secondary.withValues(alpha: 0.4), width: 1),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            color: AegisColors.secondary, size: AegisIconSize.sm),
                        const SizedBox(width: AegisSpacing.sm),
                        Expanded(
                          child: Text(
                            'AI Safety Audit Passed — Safe to Dispense.',
                            style: AegisTypography.bodySmall.copyWith(color: AegisColors.secondary, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AegisSpacing.lg),
                ],

                // ── Patient & Diagnosis Summary ───────────────
                sectionHeader('Prescription Summary'),
                DoctorCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(widget.patientName,
                                style: AegisTypography.titleSmall.copyWith(color: AegisColors.textPrimary),
                                overflow: TextOverflow.ellipsis),
                          ),
                          Text(widget.patientId,
                              style: AegisTypography.monoSmall.copyWith(color: AegisColors.textTertiary)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('Complaint: ${widget.chiefComplaint}',
                          style: AegisTypography.bodySmall.copyWith(color: AegisColors.textSecondary)),
                      Text('Diagnosis: ${widget.diagnosis}',
                          style: AegisTypography.bodySmall.copyWith(color: AegisColors.textSecondary)),
                    ],
                  ),
                ),
                const SizedBox(height: AegisSpacing.lg),

                // ── Medication List ───────────────────────────
                sectionHeader('Medications (${widget.medications.length})'),
                ...widget.medications.asMap().entries.map((entry) {
                  final med = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AegisSpacing.sm),
                    child: DoctorCard(
                      padding: const EdgeInsets.all(AegisSpacing.md),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AegisSpacing.sm),
                            decoration: BoxDecoration(
                              color: AegisColors.secondarySurface,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.medication_rounded,
                                color: AegisColors.secondary, size: AegisIconSize.sm),
                          ),
                          const SizedBox(width: AegisSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(med['name'] ?? '',
                                    style: AegisTypography.titleSmall.copyWith(color: AegisColors.textPrimary),
                                    overflow: TextOverflow.ellipsis),
                                Text(
                                  '${med['strength']} · ${med['route']} · ${med['frequency']} · ${med['duration']}',
                                  style: AegisTypography.bodySmall.copyWith(color: AegisColors.textSecondary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: AegisSpacing.lg),

                // ── Override Form (only if high risk) ─────────
                if (requiresOverride) ...[
                  sectionHeader('Clinical Override Justification'),
                  DoctorCard(
                    borderColor: AegisColors.danger.withValues(alpha: 0.4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<String>(
                          value: _overrideCategory,
                          decoration: InputDecoration(
                            labelText: 'Override Category *',
                            labelStyle: AegisTypography.bodySmall.copyWith(color: AegisColors.textSecondary),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: AegisRadius.input,
                              borderSide: const BorderSide(color: AegisColors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: AegisRadius.input,
                              borderSide: const BorderSide(
                                  color: AegisColors.primary, width: 1.5),
                            ),
                            filled: true,
                            fillColor: AegisColors.background,
                          ),
                          dropdownColor: AegisColors.surface,
                          items: [
                            'Clinical judgment',
                            'Emergency',
                            'No alternative available',
                            'Prior tolerance documented',
                            'Other',
                          ]
                              .map((c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(c, style: AegisTypography.bodyMedium.copyWith(color: AegisColors.textPrimary))))
                              .toList(),
                          onChanged: (val) =>
                              setState(() => _overrideCategory =
                                  val ?? 'Clinical judgment'),
                        ),
                        const SizedBox(height: AegisSpacing.md),
                        TextField(
                          controller: _rationaleController,
                          maxLines: 3,
                          style: AegisTypography.bodyMedium.copyWith(color: AegisColors.textPrimary),
                          decoration: InputDecoration(
                            labelText: 'Override Rationale *',
                            labelStyle: AegisTypography.bodySmall.copyWith(color: AegisColors.textSecondary),
                            hintText:
                                'e.g. Patient has tolerated drug previously without issues, monitor vitals.',
                            hintStyle: AegisTypography.bodySmall.copyWith(color: AegisColors.textTertiary),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: AegisRadius.input,
                              borderSide: const BorderSide(color: AegisColors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: AegisRadius.input,
                              borderSide: const BorderSide(
                                  color: AegisColors.primary, width: 1.5),
                            ),
                            filled: true,
                            fillColor: AegisColors.background,
                          ),
                        ),
                        const SizedBox(height: AegisSpacing.md),
                        Container(
                          decoration: BoxDecoration(
                            color: AegisColors.dangerLight,
                            borderRadius: BorderRadius.circular(AegisRadius.sm),
                            border: Border.all(
                                color: AegisColors.danger.withValues(alpha: 0.3)),
                          ),
                          child: CheckboxListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: AegisSpacing.sm),
                            title: Text(
                              'I acknowledge the identified risks and assume full clinical responsibility as the treating physician.',
                              style: AegisTypography.bodySmall.copyWith(color: AegisColors.dangerDark, height: 1.4, fontWeight: FontWeight.w600),
                            ),
                            value: _isAcknowledged,
                            activeColor: AegisColors.danger,
                            checkColor: Colors.white,
                            onChanged: (val) => setState(
                                () => _isAcknowledged = val ?? false),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Fixed bottom action bar ─────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(
                AegisSpacing.pagePadding,
                AegisSpacing.sm,
                AegisSpacing.pagePadding,
                AegisSpacing.lg,
              ),
              decoration: const BoxDecoration(
                color: AegisColors.surface,
                border: Border(top: BorderSide(color: AegisColors.border)),
                boxShadow: AegisShadows.md,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: DoctorOutlinedButton(
                      label: 'Back to Editor',
                      color: AegisColors.textSecondary,
                      onPressed:
                          _isSigning ? null : () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: AegisSpacing.md),
                  Expanded(
                    child: DoctorPrimaryButton(
                      label: 'Sign & Commit Rx',
                      icon: Icons.draw_rounded,
                      backgroundColor: AegisColors.primary, // Royal Blue Primary Action
                      isLoading: _isSigning,
                      onPressed: _signAndCommit,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
