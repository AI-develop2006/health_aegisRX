// ════════════════════════════════════════════════════════════════════════════
// AegisRx — Patient Prescription Detail Screen
// Design System: AegisRx Clinical Precision
// Business logic: UNCHANGED — showQrPopup(), signature display, timeline steps,
//                 override warnings preserved exactly
// ════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:health_lock/features/patient/widgets/qr_drawer.dart';
import 'package:health_lock/shared/models/prescription.dart';
import '../../../core/theme/design_system.dart';

class PatientPrescriptionDetailScreen extends StatelessWidget {
  final Prescription prescription;

  const PatientPrescriptionDetailScreen({
    super.key,
    required this.prescription,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDispensed = prescription.isDispensed;
    final statusColor = isDispensed ? AegisColors.textTertiary : AegisColors.secondary;
    final statusBg = isDispensed ? AegisColors.surfaceDim : AegisColors.secondarySurface;
    final statusText = isDispensed ? 'DISPENSED' : 'ACTIVE';

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
          'Prescription Details',
          style: AegisTypography.headlineMedium
              .copyWith(color: AegisColors.textPrimary),
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
            // ── 1. Status & ID Banner ──────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AegisSpacing.base),
              decoration: BoxDecoration(
                color: AegisColors.surface,
                borderRadius: AegisRadius.card,
                border: Border.all(color: statusColor.withValues(alpha: 0.5), width: 1.5),
                boxShadow: AegisShadows.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AegisSpacing.md,
                          vertical: AegisSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: AegisRadius.chip,
                          border: Border.all(color: statusColor.withValues(alpha: 0.4), width: 1.5),
                        ),
                        child: Text(
                          statusText,
                          style: AegisTypography.labelSmall.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      Text(
                        '${prescription.date}  ${prescription.time}',
                        style: AegisTypography.bodySmall
                            .copyWith(color: AegisColors.textTertiary),
                      ),
                    ],
                  ),
                  const SizedBox(height: AegisSpacing.md),
                  Text(
                    'PRESCRIPTION CODE',
                    style: AegisTypography.labelSmall.copyWith(
                      color: AegisColors.textTertiary,
                      letterSpacing: 1.0,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AegisSpacing.xs),
                  SelectableText(
                    prescription.id,
                    style: AegisTypography.monoXL.copyWith(
                      color: AegisColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AegisSpacing.lg),

            // ── 2. Consultation Information ────────────────────
            Text(
              'Consultation Info',
              style: AegisTypography.titleSmall.copyWith(
                color: AegisColors.textPrimary,
              ),
            ),
            const SizedBox(height: AegisSpacing.sm),
            _flatCard(
              child: Column(
                children: [
                  _metaRow(
                    Icons.local_hospital_rounded,
                    'Hospital',
                    prescription.hospitalName,
                  ),
                  const Divider(color: AegisColors.border, height: AegisSpacing.lg),
                  _metaRow(
                    Icons.person_pin_rounded,
                    'Doctor',
                    prescription.doctorName,
                  ),
                  const Divider(color: AegisColors.border, height: AegisSpacing.lg),
                  _metaRow(
                    Icons.assignment_turned_in_rounded,
                    'Diagnosis',
                    prescription.disease,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AegisSpacing.lg),

            if (prescription.overrideReason != null &&
                prescription.overrideReason!.trim().isNotEmpty) ...[
              _overrideWarningCard(
                prescription.overrideReason!,
                prescription.riskBand ?? 'WARNING',
              ),
              const SizedBox(height: AegisSpacing.lg),
            ],

            // ── 3. Medicines ───────────────────────────────────
            Text(
              'Prescribed Medications',
              style: AegisTypography.titleSmall.copyWith(
                color: AegisColors.textPrimary,
              ),
            ),
            const SizedBox(height: AegisSpacing.sm),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: prescription.medicines.length,
              itemBuilder: (context, index) {
                final med = prescription.medicines[index];
                final List<String> timings = [];
                if (med.morning) timings.add('Morning');
                if (med.afternoon) timings.add('Afternoon');
                if (med.evening) timings.add('Evening');
                if (med.night) timings.add('Night');

                return Padding(
                  padding: const EdgeInsets.only(bottom: AegisSpacing.md),
                  child: _flatCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                med.name,
                                style: AegisTypography.headlineSmall.copyWith(
                                  color: AegisColors.textPrimary,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(AegisSpacing.xs),
                              decoration: BoxDecoration(
                                color: AegisColors.secondarySurface,
                                borderRadius: BorderRadius.circular(AegisRadius.sm),
                              ),
                              child: const Icon(
                                Icons.medication_liquid_rounded,
                                color: AegisColors.secondary,
                                size: AegisIconSize.sm,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AegisSpacing.md),
                        if (timings.isNotEmpty)
                          Wrap(
                            spacing: AegisSpacing.xs,
                            runSpacing: AegisSpacing.xs,
                            children: timings
                                .map((t) => _doseBadge(t))
                                .toList(),
                          ),
                        const SizedBox(height: AegisSpacing.md),
                        Row(
                          children: [
                            const Icon(
                              Icons.restaurant_menu_rounded,
                              size: AegisIconSize.xs,
                              color: AegisColors.textSecondary,
                            ),
                            const SizedBox(width: AegisSpacing.xs),
                            Text(
                              med.beforeFood
                                  ? 'Before Food'
                                  : (med.afterFood
                                        ? 'After Food'
                                        : 'As advised'),
                              style: AegisTypography.bodySmall.copyWith(
                                color: AegisColors.textSecondary,
                              ),
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.schedule_rounded,
                              size: AegisIconSize.xs,
                              color: AegisColors.textSecondary,
                            ),
                            const SizedBox(width: AegisSpacing.xs),
                            Text(
                              med.interval.isNotEmpty ? med.interval : 'Daily',
                              style: AegisTypography.bodySmall.copyWith(
                                color: AegisColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        if (med.customInstruction.isNotEmpty) ...[
                          const Divider(
                            color: AegisColors.border,
                            height: AegisSpacing.lg,
                          ),
                          Text(
                            'Instructions: ${med.customInstruction}',
                            style: AegisTypography.bodySmall.copyWith(
                              color: AegisColors.textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: AegisSpacing.lg),

            // ── 3.5. Audit & Lifecycle Timeline ────────────────
            Text(
              'Audit & Lifecycle Timeline',
              style: AegisTypography.titleSmall.copyWith(
                color: AegisColors.textPrimary,
              ),
            ),
            const SizedBox(height: AegisSpacing.sm),
            _flatCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _timelineStep(
                    title: 'Prescription Issued',
                    subtitle: 'Signed by Dr. ${prescription.doctorName}',
                    timestamp: '${prescription.date} ${prescription.time}',
                    isCompleted: true,
                    isLast: false,
                  ),
                  _timelineStep(
                    title: 'On-Chain Hash Confirmed',
                    subtitle: 'Registered secure hash to Ledger',
                    timestamp: 'Confirmed',
                    isCompleted: true,
                    isLast: false,
                  ),
                  if (prescription.isDispensed)
                    _timelineStep(
                      title: 'Medication Dispensed',
                      subtitle: 'Collected from Licensed Partner Pharmacy',
                      timestamp: 'Dispensed',
                      isCompleted: true,
                      isLast: true,
                    )
                  else
                    _timelineStep(
                      title: 'Dispensation Pending',
                      subtitle: 'Awaiting pharmacist scan & verification',
                      timestamp: 'Pending',
                      isCompleted: false,
                      isLast: true,
                    ),
                ],
              ),
            ),
            const SizedBox(height: AegisSpacing.lg),

            // ── 4. Integrity Proof (AI Purple per design rules) ──────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AegisSpacing.base),
              decoration: BoxDecoration(
                color: AegisColors.tertiarySurface,
                borderRadius: AegisRadius.card,
                border: Border.all(color: AegisColors.tertiary.withValues(alpha: 0.3), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.link_rounded, size: AegisIconSize.xs, color: AegisColors.tertiary),
                      const SizedBox(width: AegisSpacing.xs),
                      Text(
                        'CRYPTOGRAPHIC INTEGRITY PROOF',
                        style: AegisTypography.labelSmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AegisColors.tertiary,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AegisSpacing.sm),
                  SelectableText(
                    prescription.signature,
                    style: AegisTypography.monoSmall.copyWith(
                      color: AegisColors.tertiary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AegisSpacing.xl),

            // ── 5. Checkout Action ─────────────────────────────
            if (!prescription.isDispensed)
              SizedBox(
                width: double.infinity,
                height: AegisTokens.btnHeight,
                child: ElevatedButton.icon(
                  onPressed: () => showQrPopup(context, prescription),
                  icon: const Icon(
                    Icons.qr_code_2_rounded,
                    color: Colors.white,
                    size: AegisIconSize.sm,
                  ),
                  label: Text(
                    'Checkout QR for Pharmacist',
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
        ),
      ),
    );
  }

  Widget _flatCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AegisSpacing.base),
      decoration: BoxDecoration(
        color: AegisColors.surface,
        borderRadius: AegisRadius.card,
        border: Border.all(color: AegisColors.border, width: 1.0),
        boxShadow: AegisShadows.sm,
      ),
      child: child,
    );
  }

  Widget _metaRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AegisSpacing.xs),
          decoration: BoxDecoration(
            color: AegisColors.primarySurface,
            borderRadius: BorderRadius.circular(AegisRadius.sm),
          ),
          child: Icon(icon, color: AegisColors.primary, size: AegisIconSize.sm),
        ),
        const SizedBox(width: AegisSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AegisTypography.labelSmall.copyWith(
                  color: AegisColors.textTertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AegisTypography.titleSmall.copyWith(
                  color: AegisColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _doseBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AegisSpacing.sm,
        vertical: AegisSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AegisColors.secondarySurface,
        borderRadius: BorderRadius.circular(AegisRadius.xs),
        border: Border.all(color: AegisColors.secondary.withValues(alpha: 0.4), width: 1),
      ),
      child: Text(
        label,
        style: AegisTypography.labelSmall.copyWith(
          fontWeight: FontWeight.w700,
          color: AegisColors.secondary,
        ),
      ),
    );
  }

  Widget _timelineStep({
    required String title,
    required String subtitle,
    required String timestamp,
    required bool isCompleted,
    required bool isLast,
  }) {
    final dotColor = isCompleted ? AegisColors.secondary : AegisColors.textTertiary;
    final lineColor = isCompleted
        ? AegisColors.secondary.withValues(alpha: 0.3)
        : AegisColors.border;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: isCompleted ? dotColor : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(color: dotColor, width: 2),
              ),
              child: isCompleted
                  ? const Icon(Icons.check, size: 10, color: Colors.white)
                  : null,
            ),
            if (!isLast) Container(width: 2, height: 38, color: lineColor),
          ],
        ),
        const SizedBox(width: AegisSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: AegisTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isCompleted ? AegisColors.textPrimary : AegisColors.textTertiary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AegisSpacing.sm),
                  Text(
                    timestamp,
                    style: AegisTypography.monoSmall.copyWith(
                      color: isCompleted ? AegisColors.secondary : AegisColors.textTertiary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: AegisTypography.bodySmall.copyWith(color: AegisColors.textSecondary),
              ),
              const SizedBox(height: AegisSpacing.md),
            ],
          ),
        ),
      ],
    );
  }

  Widget _overrideWarningCard(String reason, String riskBand) {
    final isCritical = riskBand == 'CRITICAL';
    final cardColor = isCritical ? AegisColors.danger : AegisColors.warning;
    final cardBg = isCritical ? AegisColors.dangerLight : AegisColors.warningLight;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AegisSpacing.base),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: AegisRadius.card,
        border: Border.all(color: cardColor.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_rounded, color: cardColor, size: AegisIconSize.sm),
              const SizedBox(width: AegisSpacing.sm),
              Text(
                'Clinical Safety Override',
                style: AegisTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cardColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: AegisSpacing.sm),
          Text(
            'The prescribing clinician has authorized this prescription with the following justification:',
            style: AegisTypography.bodySmall.copyWith(
              color: AegisColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AegisSpacing.xs),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AegisSpacing.sm),
            decoration: BoxDecoration(
              color: AegisColors.surface,
              borderRadius: BorderRadius.circular(AegisRadius.sm),
              border: Border.all(color: cardColor.withValues(alpha: 0.2)),
            ),
            child: Text(
              reason,
              style: AegisTypography.bodyMedium.copyWith(
                color: AegisColors.textPrimary,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
