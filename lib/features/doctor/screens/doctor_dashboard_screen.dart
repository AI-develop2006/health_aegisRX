import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/state/app_state.dart';
import '../../../shared/widgets/neon_card.dart';
import '../../../shared/widgets/glassmorphic_button.dart';
import 'doctor_patient_search_screen.dart';
import 'doctor_patient_history_screen.dart';

class DoctorDashboardScreen extends StatelessWidget {
  const DoctorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    // Doctor details fallback
    final docLicense = appState.doctorLicense ?? 'NPI-1002288';
    final docHospital = appState.doctorHospital ?? 'Metropolitan Hospital Centre';
    final docSpecialty = appState.doctorSpecialty ?? 'Cardiology';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Practitioner Console',
          style: GoogleFonts.sora(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () {
              appState.clearSession();
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Doctor Profile Header Card
            NeonCard(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.local_hospital_rounded,
                      size: 32,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dr. Alexander Vance',
                          style: GoogleFonts.sora(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$docSpecialty • $docHospital',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: isLight ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                          ),
                        ),
                        Text(
                          'License: $docLicense',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 11,
                            color: isLight ? Colors.black54 : Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Active Consultation Session Section
            Text(
              'Active Consultation',
              style: GoogleFonts.sora(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (appState.activePatientId != null) ...[
              NeonCard(
                neonColor: const Color(0xFF10B981), // Emerald Green
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.wifi_tethering_rounded, color: Color(0xFF10B981)),
                  ),
                  title: Text(
                    appState.activePatientName ?? 'Priya Sharma',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Text('ID: ${appState.activePatientId} • Live Connection Established'),
                  trailing: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DoctorPatientHistoryScreen(
                            patientId: appState.activePatientId!,
                            patientName: appState.activePatientName!,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                    ),
                    child: const Text('Open Vault', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ),
            ] else ...[
              NeonCard(
                neonColor: Colors.blueGrey,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.wifi_tethering_off_rounded, color: Colors.blueGrey),
                      const SizedBox(width: 12),
                      Text(
                        'No active patient session connected.',
                        style: GoogleFonts.inter(
                          color: isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 28),

            // Today's Appointments Section
            Text(
              "Today's Appointments",
              style: GoogleFonts.sora(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildAppointmentTile(
                  context: context,
                  name: 'Priya Sharma',
                  time: '09:30 AM',
                  reason: 'Hypertension Follow-up',
                  patientId: 'priya_123',
                ),
                const SizedBox(height: 12),
                _buildAppointmentTile(
                  context: context,
                  name: 'Elena Vance',
                  time: '11:00 AM',
                  reason: 'Post-op Cardiac Checkup',
                  patientId: 'elena_vance',
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Primary CTA
            SizedBox(
              width: double.infinity,
              child: GlassmorphicButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const DoctorPatientSearchScreen()),
                  );
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_rounded),
                    SizedBox(width: 8),
                    Text(
                      'Search Patient / Scan QR',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentTile({
    required BuildContext context,
    required String name,
    required String time,
    required String reason,
    required String patientId,
  }) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DoctorPatientHistoryScreen(
              patientId: patientId,
              patientName: name,
            ),
          ),
        );
      },
      child: NeonCard(
        borderWidth: 0.5,
        neonColor: theme.colorScheme.primary.withOpacity(0.3),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                time,
                style: GoogleFonts.jetBrainsMono(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    reason,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: isLight ? Colors.grey : Colors.white38),
          ],
        ),
      ),
    );
  }
}
