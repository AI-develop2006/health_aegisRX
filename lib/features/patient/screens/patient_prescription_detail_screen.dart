import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:health_lock/features/patient/widgets/qr_drawer.dart';
import 'package:health_lock/shared/models/prescription.dart';

// ── Design Tokens (60-30-10) ───────────────────────────────────
class _P {
  static const bg = Color(0xFFF7F4EB);
  static const card = Color(0xFFFFFFFF);
  static const text = Color(0xFF4A3325);
  static const sub = Color(0xFFD4A387);
  static const border = Color(0xFFB88E74);
  static const teal = Color(0xFF2E8B90);
  static const red = Color(0xFFB33A3A);
  static const amber = Color(0xFFD97736);
}

class PatientPrescriptionDetailScreen extends StatelessWidget {
  final Prescription prescription;

  const PatientPrescriptionDetailScreen({
    super.key,
    required this.prescription,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = prescription.isDispensed ? _P.red : _P.teal;
    final statusText = prescription.isDispensed ? 'DISPENSED' : 'ACTIVE';

    return Scaffold(
      backgroundColor: _P.bg,
      appBar: AppBar(
        backgroundColor: _P.bg,
        elevation: 0,
        title: Text(
          'Prescription Details',
          style: GoogleFonts.sora(
            fontWeight: FontWeight.bold,
            color: _P.text,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _P.text),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. Status & ID Banner ──────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _P.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: statusColor, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: statusColor, width: 1.5),
                        ),
                        child: Text(
                          statusText,
                          style: GoogleFonts.inter(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      Text(
                        '${prescription.date}  ${prescription.time}',
                        style: GoogleFonts.inter(color: _P.sub, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'PRESCRIPTION CODE',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: _P.sub,
                      letterSpacing: 1.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    prescription.id,
                    style: GoogleFonts.jetBrainsMono(
                      color: _P.text,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── 2. Consultation Information ────────────────────
            Text(
              'Consultation Info',
              style: GoogleFonts.sora(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: _P.text,
              ),
            ),
            const SizedBox(height: 12),
            _flatCard(
              child: Column(
                children: [
                  _metaRow(
                    Icons.local_hospital_rounded,
                    'Hospital',
                    prescription.hospitalName,
                  ),
                  Divider(color: _P.border.withOpacity(0.3), height: 24),
                  _metaRow(
                    Icons.person_pin_rounded,
                    'Doctor',
                    prescription.doctorName,
                  ),
                  Divider(color: _P.border.withOpacity(0.3), height: 24),
                  _metaRow(
                    Icons.assignment_turned_in_rounded,
                    'Diagnosis',
                    prescription.disease,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            if (prescription.overrideReason != null &&
                prescription.overrideReason!.trim().isNotEmpty) ...[
              _overrideWarningCard(
                prescription.overrideReason!,
                prescription.riskBand ?? 'WARNING',
              ),
              const SizedBox(height: 24),
            ],

            // ── 3. Medicines ───────────────────────────────────
            Text(
              'Prescribed Medications',
              style: GoogleFonts.sora(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: _P.text,
              ),
            ),
            const SizedBox(height: 12),
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
                  padding: const EdgeInsets.only(bottom: 16.0),
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
                                style: GoogleFonts.sora(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: _P.text,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.medication_liquid_rounded,
                              color: _P.border,
                              size: 22,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Dose timing chips
                        if (timings.isNotEmpty)
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: timings
                                .map((t) => _doseBadge(t))
                                .toList(),
                          ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(
                              Icons.restaurant_menu_rounded,
                              size: 15,
                              color: _P.sub,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              med.beforeFood
                                  ? 'Before Food'
                                  : (med.afterFood
                                        ? 'After Food'
                                        : 'As advised'),
                              style: GoogleFonts.inter(
                                color: _P.sub,
                                fontSize: 13,
                              ),
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.schedule_rounded,
                              size: 15,
                              color: _P.sub,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              med.interval.isNotEmpty ? med.interval : 'Daily',
                              style: GoogleFonts.inter(
                                color: _P.sub,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        if (med.customInstruction.isNotEmpty) ...[
                          Divider(
                            color: _P.border.withOpacity(0.3),
                            height: 24,
                          ),
                          Text(
                            'Instructions: ${med.customInstruction}',
                            style: GoogleFonts.inter(
                              color: _P.sub,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // ── 3.5. Audit & Lifecycle Timeline ────────────────
            Text(
              'Audit & Lifecycle Timeline',
              style: GoogleFonts.sora(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: _P.text,
              ),
            ),
            const SizedBox(height: 12),
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
                    subtitle: 'Registered secure hash to Polygon Ledger',
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
            const SizedBox(height: 24),

            // ── 4. Integrity Proof ─────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _P.bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _P.border.withOpacity(0.4), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lock_rounded, size: 14, color: _P.teal),
                      const SizedBox(width: 8),
                      Text(
                        'CRYPTOGRAPHIC INTEGRITY PROOF',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _P.teal,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SelectableText(
                    prescription.signature,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      color: _P.sub,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ── 5. Checkout Action ─────────────────────────────
            if (!prescription.isDispensed)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => showQrPopup(context, prescription),
                  icon: const Icon(
                    Icons.qr_code_2_rounded,
                    color: Colors.white,
                  ),
                  label: Text(
                    'Checkout QR for Pharmacist',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _P.teal,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _flatCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _P.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _P.border, width: 1.0),
      ),
      child: child,
    );
  }

  Widget _metaRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: _P.sub, size: 20),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: _P.sub,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: _P.text,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _doseBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _P.teal.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _P.teal.withOpacity(0.4), width: 1),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: _P.teal,
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
    final dotColor = isCompleted ? _P.teal : _P.sub;
    final lineColor = isCompleted
        ? _P.teal.withOpacity(0.3)
        : _P.border.withOpacity(0.2);

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
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.sora(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isCompleted ? _P.text : _P.sub,
                    ),
                  ),
                  Text(
                    timestamp,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: isCompleted ? _P.teal : _P.sub,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: GoogleFonts.inter(fontSize: 12, color: _P.sub),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _overrideWarningCard(String reason, String riskBand) {
    final isCritical = riskBand == 'CRITICAL';
    final cardColor = isCritical ? _P.red : _P.amber;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardColor.withOpacity(0.4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_rounded, color: cardColor, size: 20),
              const SizedBox(width: 10),
              Text(
                'Clinical Safety Override',
                style: GoogleFonts.sora(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: cardColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'The prescribing clinician has authorized this prescription with the following justification:',
            style: GoogleFonts.inter(
              color: _P.text.withOpacity(0.8),
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cardColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              reason,
              style: GoogleFonts.inter(
                color: _P.text,
                fontSize: 13,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
