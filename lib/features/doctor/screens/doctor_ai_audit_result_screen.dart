// ════════════════════════════════════════════════════════════════════════════
// AegisRx — Doctor AI Audit Result Screen
// Design System: AegisRx Clinical Precision
// Business logic: UNCHANGED — auditResult map parsing, riskColor, riskLabel,
//                 reasons, drug interactions, allergy risks, alternatives preserved
// ════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import '../../../core/theme/design_system.dart';
import '../doctor_theme.dart';

/// Shown when navigating to view a completed AI audit result.
/// Takes a PrescriptionSafetyAnalysis-style map and renders it clearly.
class DoctorAiAuditResultScreen extends StatelessWidget {
  final Map<String, dynamic>? auditResult;

  const DoctorAiAuditResultScreen({super.key, this.auditResult});

  @override
  Widget build(BuildContext context) {
    final result = auditResult ?? {};
    final riskLevel = result['risk_level'] ?? result['riskLevel'] ?? 'SAFE';
    final recommended =
        result['recommended_action'] ?? result['recommendedAction'] ?? 'SAFE_TO_DISPENSE';
    final explanation = result['clinical_explanation'] ??
        result['clinicalExplanation'] ??
        'No clinical explanation provided.';
    final List<dynamic> reasons = result['reasons'] as List<dynamic>? ?? [];
    final List<dynamic> interactions =
        result['detected_drug_interactions'] as List<dynamic>? ??
            result['detectedDrugInteractions'] as List<dynamic>? ??
            [];
    final List<dynamic> allergies =
        result['detected_allergy_risks'] as List<dynamic>? ??
            result['detectedAllergyRisks'] as List<dynamic>? ??
            [];
    final List<dynamic> alternatives =
        result['suggested_alternative_medicines'] as List<dynamic>? ??
            result['suggestedAlternatives'] as List<dynamic>? ??
            [];

    final rc = riskColor(riskLevel);
    final rl = riskLabel(riskLevel);

    return ClinicalScaffold(
      appBar: clinicalAppBar(title: 'AI Safety Audit Report'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AegisSpacing.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Risk Banner ───────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AegisSpacing.base),
              decoration: BoxDecoration(
                color: rc.withValues(alpha: 0.08),
                borderRadius: AegisRadius.card,
                border: Border.all(color: rc.withValues(alpha: 0.4), width: 1.5),
                boxShadow: AegisShadows.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AegisSpacing.xs),
                        decoration: BoxDecoration(
                          color: rc.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          riskLevel == 'SAFE'
                              ? Icons.check_circle_rounded
                              : riskLevel == 'WARNING'
                                  ? Icons.warning_amber_rounded
                                  : Icons.dangerous_rounded,
                          color: rc,
                          size: AegisIconSize.md,
                        ),
                      ),
                      const SizedBox(width: AegisSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Clinical Safety Result',
                                style: AegisTypography.bodySmall.copyWith(color: AegisColors.textSecondary)),
                            Text(rl,
                                style: AegisTypography.headlineSmall.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: rc)),
                          ],
                        ),
                      ),
                      DoctorStatusBadge(
                          label: recommended.replaceAll('_', ' '),
                          color: rc),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AegisSpacing.lg),

            // ── Clinical Explanation ──────────────────────────
            sectionHeader('Clinical Explanation'),
            DoctorCard(
              child: Text(explanation,
                  style: AegisTypography.bodyMedium.copyWith(color: AegisColors.textPrimary, height: 1.6)),
            ),
            const SizedBox(height: AegisSpacing.lg),

            // ── Flagged Reasons ───────────────────────────────
            if (reasons.isNotEmpty) ...[
              sectionHeader('Safety Findings (${reasons.length})'),
              ...reasons.asMap().entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AegisSpacing.sm),
                  child: DoctorCard(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AegisSpacing.base, vertical: AegisSpacing.sm),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: rc.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${entry.key + 1}',
                            style: AegisTypography.monoSmall.copyWith(
                                fontWeight: FontWeight.w800,
                                color: rc),
                          ),
                        ),
                        const SizedBox(width: AegisSpacing.sm),
                        Expanded(
                          child: Text(entry.value.toString(),
                              style: AegisTypography.bodyMedium.copyWith(color: AegisColors.textPrimary, height: 1.5)),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: AegisSpacing.lg),
            ],

            // ── Drug Interactions ─────────────────────────────
            if (interactions.isNotEmpty) ...[
              sectionHeader('Drug-Drug Interactions'),
              ...interactions.map((i) {
                final drugs = (i['drugs'] as List<dynamic>?)
                        ?.map((d) => d.toString())
                        .join(' + ') ??
                    'Unknown';
                final severity =
                    i['severity']?.toString() ?? 'MODERATE';
                final ic = severity == 'MAJOR' ? AegisColors.danger : AegisColors.warning;
                return Padding(
                  padding: const EdgeInsets.only(bottom: AegisSpacing.sm),
                  child: DoctorCard(
                    borderColor: ic.withValues(alpha: 0.4),
                    padding: const EdgeInsets.all(AegisSpacing.md),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.compare_arrows_rounded,
                            color: ic, size: AegisIconSize.sm),
                        const SizedBox(width: AegisSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(drugs,
                                  style: AegisTypography.titleSmall.copyWith(color: AegisColors.textPrimary),
                                  overflow: TextOverflow.ellipsis),
                              Text(
                                  i['description']?.toString() ?? '',
                                  style: AegisTypography.bodySmall.copyWith(color: AegisColors.textSecondary)),
                            ],
                          ),
                        ),
                        DoctorStatusBadge(
                            label: severity, color: ic),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: AegisSpacing.lg),
            ],

            // ── Allergy Risks ─────────────────────────────────
            if (allergies.isNotEmpty) ...[
              sectionHeader('Allergy Conflicts'),
              ...allergies.map((a) => Padding(
                    padding: const EdgeInsets.only(bottom: AegisSpacing.sm),
                    child: DoctorCard(
                      borderColor: AegisColors.danger.withValues(alpha: 0.4),
                      padding: const EdgeInsets.all(AegisSpacing.md),
                      child: Row(
                        children: [
                          const Icon(Icons.personal_injury_outlined,
                              color: AegisColors.danger, size: AegisIconSize.sm),
                          const SizedBox(width: AegisSpacing.sm),
                          Expanded(
                            child: Text(
                                a['description']?.toString() ??
                                    a.toString(),
                                style: AegisTypography.bodyMedium.copyWith(color: AegisColors.textPrimary)),
                          ),
                        ],
                      ),
                    ),
                  )),
              const SizedBox(height: AegisSpacing.lg),
            ],

            // ── Alternatives ──────────────────────────────────
            if (alternatives.isNotEmpty) ...[
              sectionHeader('Suggested Alternatives'),
              DoctorCard(
                child: Wrap(
                  spacing: AegisSpacing.xs,
                  runSpacing: AegisSpacing.xs,
                  children: alternatives
                      .map((alt) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AegisSpacing.md, vertical: AegisSpacing.xs),
                            decoration: BoxDecoration(
                              color: AegisColors.secondarySurface,
                              borderRadius: BorderRadius.circular(AegisRadius.sm),
                              border: Border.all(
                                  color: AegisColors.secondary.withValues(alpha: 0.4)),
                            ),
                            child: Text(alt.toString(),
                                style: AegisTypography.labelSmall.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AegisColors.secondary)),
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: AegisSpacing.lg),
            ],

            // ── CTA (Royal Blue Primary Action) ───────────────
            DoctorPrimaryButton(
              label: 'Proceed to Override Decision',
              icon: Icons.edit_note_rounded,
              backgroundColor: AegisColors.primary,
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(height: AegisSpacing.xxl),
          ],
        ),
      ),
    );
  }
}
