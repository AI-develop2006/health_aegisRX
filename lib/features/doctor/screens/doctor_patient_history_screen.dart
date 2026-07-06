import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/widgets/neon_card.dart';
import 'doctor_prescription_editor_screen.dart';

class DoctorPatientHistoryScreen extends StatelessWidget {
  final String patientId;
  final String patientName;

  const DoctorPatientHistoryScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    // Retrieve details depending on mock patient selected
    final bool isElena = patientId == 'elena_vance';
    final age = isElena ? 28 : 34;
    final gender = isElena ? 'Female' : 'Female';
    final allergies = isElena ? ['Penicillin', 'Peanuts'] : ['Sulfa drugs'];
    final conditions = isElena ? ['Type-2 Diabetes', 'Asthma'] : ['Essential Hypertension'];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          'Patient Medical File',
          style: GoogleFonts.sora(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Patient demographics card
            NeonCard(
              neonColor: theme.colorScheme.primary,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        patientName,
                        style: GoogleFonts.sora(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'ID: $patientId',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 12,
                          color: isLight ? Colors.black54 : Colors.white54,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Age: $age • Gender: $gender',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white12),
                  const SizedBox(height: 12),

                  // Allergies List
                  const Text(
                    'Drug & Food Allergies',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: allergies
                        .map(
                          (allergy) => Chip(
                            backgroundColor: Colors.redAccent.withOpacity(0.12),
                            side: const BorderSide(color: Colors.redAccent, width: 0.5),
                            label: Text(
                              allergy,
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 16),

                  // Chronic conditions list
                  const Text(
                    'Chronic Conditions',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: conditions
                        .map(
                          (cond) => Chip(
                            backgroundColor: theme.colorScheme.secondary.withOpacity(0.12),
                            side: BorderSide(color: theme.colorScheme.secondary, width: 0.5),
                            label: Text(
                              cond,
                              style: TextStyle(
                                color: theme.colorScheme.secondary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Clinical Encounter Logs
            Text(
              'Encounter Logs',
              style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            NeonCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '25 June 2026 - Routine Checkup',
                    style: GoogleFonts.jetBrainsMono(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Patient reported mild fatigue and dry mouth. Blood glucose values indicate slightly elevated HbA1c. Recommended continuing low carbohydrate diet and regular medication compliance.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: isLight ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Historical Prescriptions
            Text(
              'Historical Prescriptions',
              style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildHistoryRxCard(
              context: context,
              date: '20 June 2026',
              medText: 'Metformin 500 mg twice daily for 3 months',
              riskBand: 'LOW',
              riskColor: const Color(0xFF10B981),
            ),
            const SizedBox(height: 12),
            _buildHistoryRxCard(
              context: context,
              date: '15 May 2026',
              medText: 'Amoxicillin 500 mg three times daily for 7 days',
              riskBand: 'HIGH',
              riskColor: Colors.orangeAccent,
              overrideNote: 'Patient has chronic sinus infection resistant to first-line agents. Monitored closely for side effects.',
            ),
            const SizedBox(height: 36),

            // Action CTA
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DoctorPrescriptionEditorScreen(
                        patientId: patientId,
                        patientName: patientName,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.note_add_rounded, color: Colors.white),
                label: const Text(
                  'Write New Prescription',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryRxCard({
    required BuildContext context,
    required String date,
    required String medText,
    required String riskBand,
    required Color riskColor,
    String? overrideNote,
  }) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return NeonCard(
      borderWidth: 0.5,
      neonColor: riskColor.withOpacity(0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                date,
                style: GoogleFonts.jetBrainsMono(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: riskColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: riskColor, width: 0.5),
                ),
                child: Text(
                  riskBand,
                  style: TextStyle(
                    color: riskColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            medText,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          if (overrideNote != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orangeAccent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orangeAccent.withOpacity(0.3), width: 0.5),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.shield_outlined, color: Colors.orangeAccent, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Justification: $overrideNote',
                      style: GoogleFonts.inter(
                        color: isLight ? const Color(0xFF7C2D12) : const Color(0xFFFFEDD5),
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
