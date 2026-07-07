import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Risk Banner ───────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: rc.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: rc.withOpacity(0.4), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: rc.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          riskLevel == 'SAFE'
                              ? Icons.check_circle_rounded
                              : riskLevel == 'WARNING'
                                  ? Icons.warning_amber_rounded
                                  : Icons.dangerous_rounded,
                          color: rc,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Clinical Safety Result',
                                style: Dr.meta(12)),
                            Text(rl,
                                style: GoogleFonts.sora(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: rc)),
                          ],
                        ),
                      ),
                      DoctorStatusBadge(
                          label: recommended
                              .replaceAll('_', ' '),
                          color: rc),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Clinical Explanation ──────────────────────────
            sectionHeader('Clinical Explanation'),
            DoctorCard(
              child: Text(explanation,
                  style: Dr.body(13).copyWith(height: 1.6)),
            ),
            const SizedBox(height: 20),

            // ── Flagged Reasons ───────────────────────────────
            if (reasons.isNotEmpty) ...[
              sectionHeader('Safety Findings (${reasons.length})'),
              ...reasons.asMap().entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: DoctorCard(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: rc.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${entry.key + 1}',
                            style: GoogleFonts.jetBrainsMono(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: rc),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(entry.value.toString(),
                              style: Dr.body(13).copyWith(height: 1.5)),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 20),
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
                final ic = severity == 'MAJOR' ? Dr.red : Dr.amber;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: DoctorCard(
                    borderColor: ic.withOpacity(0.3),
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.compare_arrows_rounded,
                            color: ic, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(drugs,
                                  style: Dr.body(13).copyWith(
                                      fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis),
                              Text(
                                  i['description']?.toString() ?? '',
                                  style: Dr.meta(12)),
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
              const SizedBox(height: 20),
            ],

            // ── Allergy Risks ─────────────────────────────────
            if (allergies.isNotEmpty) ...[
              sectionHeader('Allergy Conflicts'),
              ...allergies.map((a) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: DoctorCard(
                      borderColor: Dr.red.withOpacity(0.3),
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          const Icon(Icons.personal_injury_outlined,
                              color: Dr.red, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                                a['description']?.toString() ??
                                    a.toString(),
                                style: Dr.body(13)),
                          ),
                        ],
                      ),
                    ),
                  )),
              const SizedBox(height: 20),
            ],

            // ── Alternatives ──────────────────────────────────
            if (alternatives.isNotEmpty) ...[
              sectionHeader('Suggested Alternatives'),
              DoctorCard(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: alternatives
                      .map((alt) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Dr.green.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: Dr.green.withOpacity(0.3)),
                            ),
                            child: Text(alt.toString(),
                                style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Dr.green)),
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ── CTA ───────────────────────────────────────────
            DoctorPrimaryButton(
              label: 'Proceed to Override Decision',
              icon: Icons.edit_note_rounded,
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
