import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/risk_gauge.dart';
import '../../widgets/danger_banner.dart';
import '../../widgets/dose_timeline.dart';
import '../../widgets/inventory_tracker.dart';
import '../../widgets/consultation_status_chip.dart';
import 'patient_history_screen.dart';
import '../patient_share_screen.dart';
import '../patient_medication_list_screen.dart';
import '../../../../shared/widgets/neon_card.dart';

class PatientDashboardScreen extends StatefulWidget {
  const PatientDashboardScreen({super.key});

  @override
  State<PatientDashboardScreen> createState() => _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends State<PatientDashboardScreen> {
  final List<Map<String, String>> _todayMeds = [
    { "name": "Metformin 500 mg", "schedule": "Morning and evening", "status": "Due" },
    { "name": "Atorvastatin 10 mg", "schedule": "Night", "status": "Due" }
  ];

  void _toggleStatus(int index) {
    setState(() {
      final current = _todayMeds[index]['status'];
      _todayMeds[index]['status'] = current == 'Due' ? 'Taken' : 'Due';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    // 60-30-10 Color Tokens
    final bg60 = isLight ? const Color(0xFFF5F6FA) : const Color(0xFF0B0F19); // 60% Dominant Background
    final accent10 = isLight ? const Color(0xFF4F46E5) : const Color(0xFF818CF8); // 10% Primary Accent

    return Scaffold(
      backgroundColor: bg60,
      appBar: AppBar(
        backgroundColor: bg60,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'AegisRx ',
                style: GoogleFonts.fraunces(
                  color: isLight ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
              TextSpan(
                text: 'Patient Vault',
                style: GoogleFonts.inter(
                  color: isLight ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                  fontWeight: FontWeight.w500,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // 1. Top status and session sharing area
          Container(
            color: bg60,
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20.0, 4.0, 20.0, 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const ConsultationStatusChip(status: 'active'),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PatientShareScreen()),
                    );
                  },
                  icon: const Icon(Icons.qr_code, size: 18, color: Colors.white),
                  label: Text(
                    'Share Session',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent10, // 10% Accent Color for key action
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 2. Main content scroll area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Personalized Welcome Header (PATIENT.MD specifications)
                  Text(
                    'Good morning, Alex',
                    style: GoogleFonts.sora(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: isLight ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Today, 03 July 2026',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: isLight ? Colors.black54 : Colors.white60,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Today's Medications card
                  NeonCard(
                    neonColor: const Color(0xFF818CF8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Today's medications",
                              style: TextStyle(
                                fontFamily: 'Sora',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Icon(Icons.today_rounded, color: const Color(0xFF818CF8).withOpacity(0.8)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _todayMeds.length,
                          itemBuilder: (context, index) {
                            final med = _todayMeds[index];
                            final isTaken = med['status'] == 'Taken';
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                med['name']!,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  decoration: isTaken ? TextDecoration.lineThrough : null,
                                ),
                              ),
                              subtitle: Text(
                                med['schedule']!,
                                style: const TextStyle(fontSize: 13, color: Colors.white70),
                              ),
                              trailing: InkWell(
                                onTap: () => _toggleStatus(index),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isTaken
                                        ? const Color(0xFF10B981).withOpacity(0.2)
                                        : Colors.amber.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isTaken ? const Color(0xFF10B981) : Colors.amber,
                                    ),
                                  ),
                                  child: Text(
                                    med['status']!,
                                    style: TextStyle(
                                      color: isTaken ? const Color(0xFF10B981) : Colors.amber,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 24, color: Colors.white24),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const PatientMedicationListScreen()),
                              );
                            },
                            icon: const Icon(Icons.arrow_forward, size: 16, color: Color(0xFF818CF8)),
                            label: const Text(
                              'See all medications',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                color: Color(0xFF818CF8),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  const DangerBanner(
                    message: 'ALLERGY WARNING: Patient has marked allergy to Penicillin. Confirm with Doctor before prescription.',
                  ),
                  const SizedBox(height: 24),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Safety Index score (Fraunces typography)
                      const Expanded(
                        child: NeonCard(
                          neonColor: Color(0xFFC5A059), // Seal Gold Outline
                          child: Column(
                            children: [
                              Text(
                                'Safety Index',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              SizedBox(height: 16),
                              RiskGauge(severityScore: 3),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Prescriptions (JetBrains Mono codes)
                      Expanded(
                        child: NeonCard(
                          neonColor: const Color(0xFF818CF8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Prescriptions',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 12),
                              _buildRxRow('RX-9921', 'Active', const Color(0xFF10B981)),
                              _buildRxRow('RX-4253', 'Active', const Color(0xFF10B981)),
                              _buildRxRow('RX-3104', 'Burned', Colors.redAccent),
                              const SizedBox(height: 12),
                              TextButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const PatientHistoryScreen()),
                                  );
                                },
                                icon: const Icon(Icons.history, size: 16, color: Color(0xFFC5A059)), // Seal Gold history icon
                                label: Text(
                                  'History',
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFFC5A059),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const NeonCard(
                    neonColor: Color(0xFF1E293B),
                    child: DoseTimeline(),
                  ),
                  const SizedBox(height: 24),
                  const NeonCard(
                    neonColor: Color(0xFF818CF8),
                    child: InventoryTracker(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRxRow(String code, String status, Color statusColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          const Text('• ', style: TextStyle(color: Colors.white54)),
          Text(
            code,
            style: GoogleFonts.jetBrainsMono(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: const Color(0xFF818CF8),
            ),
          ),
          Text(
            ' ($status)',
            style: TextStyle(
              color: statusColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
