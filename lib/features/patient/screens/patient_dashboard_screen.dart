import 'package:flutter/material.dart';
import '../widgets/risk_gauge.dart';
import '../widgets/danger_banner.dart';
import '../widgets/dose_timeline.dart';
import '../widgets/inventory_tracker.dart';
import '../widgets/consultation_status_chip.dart';
import 'patient_settings_screen.dart';
import 'patient_history_screen.dart';
import 'patient_qr_share_screen.dart';
import '../../../shared/widgets/neon_card.dart';

class PatientDashboardScreen extends StatelessWidget {
  const PatientDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AegisRx Patient Vault'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PatientSettingsScreen()),
              );
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const ConsultationStatusChip(status: 'active'),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PatientQrShareScreen()),
                    );
                  },
                  icon: const Icon(Icons.qr_code),
                  label: const Text('Share Session'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const DangerBanner(
              message: 'ALLERGY WARNING: Patient has marked allergy to Penicillin. Confirm with Doctor before prescription.',
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Expanded(
                  child: NeonCard(
                    neonColor: Color(0xFF0F52BA),
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
                Expanded(
                  child: NeonCard(
                    neonColor: const Color(0xFF00A86B),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Prescriptions',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 12),
                        const Text('• RX-9921 (Active)'),
                        const Text('• RX-4253 (Active)'),
                        const Text('• RX-3104 (Dispensed)'),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const PatientHistoryScreen()),
                            );
                          },
                          child: const Text('View All History'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const NeonCard(
              neonColor: Colors.blueGrey,
              child: DoseTimeline(),
            ),
            const SizedBox(height: 24),
            const NeonCard(
              neonColor: Color(0xFF0F52BA),
              child: InventoryTracker(),
            ),
          ],
        ),
      ),
    );
  }
}
