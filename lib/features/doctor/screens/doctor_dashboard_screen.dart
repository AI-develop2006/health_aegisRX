import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/state/app_state.dart';
import '../../../core/theme/design_system.dart';
import '../doctor_theme.dart';
import 'doctor_patient_search_screen.dart';
import 'doctor_patient_history_screen.dart';

class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppState>(context, listen: false).fetchDoctorConsultations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final docLicense = appState.doctorLicense ?? 'NPI-1002288';
    final docHospital =
        appState.doctorHospital ?? 'Metropolitan Hospital Centre';
    final docSpecialty = appState.doctorSpecialty ?? 'Cardiology';
    final rawName = appState.doctorName ?? 'Alexander Vance';
    final docName = rawName.startsWith('Dr.') ? rawName : 'Dr. $rawName';

    return ClinicalScaffold(
      appBar: clinicalAppBar(
        title: 'Practitioner Console',
        showBack: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Dr.sub),
            tooltip: 'Sign Out',
            onPressed: () => appState.clearSession(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Doctor Profile Card ───────────────────────────
            DoctorCard(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Dr.green.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Dr.green.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.local_hospital_rounded,
                      size: 28,
                      color: Dr.green,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          docName,
                          style: Dr.heading(16),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '$docSpecialty · $docHospital',
                          style: Dr.meta(12),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          docLicense,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 11,
                            color: Dr.sub,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const DoctorStatusBadge(
                    label: 'Verified',
                    color: Dr.green,
                    icon: Icons.verified_rounded,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Active Session Card ───────────────────────────
            sectionHeader('Active Consultation'),
            if (appState.activePatientId != null) ...[
              DoctorCard(
                borderColor: AegisColors.secondary.withValues(alpha: 0.4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AegisColors.secondarySurface,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.wifi_tethering_rounded,
                            color: AegisColors.secondary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                appState.activePatientName ?? 'Patient',
                                style: AegisTypography.titleSmall.copyWith(
                                  color: AegisColors.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'ID: ${appState.activePatientId} · Live',
                                style: AegisTypography.bodySmall.copyWith(
                                  color: AegisColors.secondary,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AegisSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              await appState.cancelActiveSession();
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AegisColors.danger),
                              padding: const EdgeInsets.symmetric(
                                vertical: AegisSpacing.sm,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: AegisRadius.button,
                              ),
                            ),
                            child: Text(
                              'Disconnect',
                              style: AegisTypography.labelSmall.copyWith(
                                color: AegisColors.danger,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AegisSpacing.sm),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        DoctorPatientHistoryScreen(
                                          patientId: appState.activePatientId!,
                                          patientName:
                                              appState.activePatientName!,
                                        ),
                                  ),
                                ).then((_) {
                                  if (context.mounted) {
                                    Provider.of<AppState>(
                                      context,
                                      listen: false,
                                    ).resumePolling(
                                      screen: 'DoctorDashboardScreen',
                                      reason:
                                          'Doctor returned to dashboard from active consultation',
                                    );
                                  }
                                }),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AegisColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                vertical: AegisSpacing.sm,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: AegisRadius.button,
                              ),
                            ),
                            icon: const Icon(
                              Icons.folder_open_rounded,
                              size: AegisIconSize.xs,
                              color: Colors.white,
                            ),
                            label: Text(
                              'Open Vault',
                              style: AegisTypography.labelSmall.copyWith(
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ] else ...[
              DoctorCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.wifi_tethering_off_rounded,
                      color: Dr.sub,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text('No active patient session.', style: Dr.meta(13)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),

            // ── Past Consultations ──────────────────────────
            sectionHeader("Past Consultations"),
            if (appState.doctorConsultations.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'No past consultations recorded on the ledger.',
                    style: Dr.meta(13).copyWith(fontStyle: FontStyle.italic),
                  ),
                ),
              )
            else
              ...appState.doctorConsultations.map((rx) {
                final String name = rx['patientName'] ?? 'Patient';
                final String date = rx['date'] ?? '';
                final String time = rx['time'] ?? '10:00';
                final String mobile = rx['patient_mobile'] ?? 'N/A';
                final String disease = rx['disease'] ?? 'Consultation';
                final String patientId =
                    rx['patient_id'] ?? rx['patientName'] ?? '';
                final bool isDispensed = rx['isDispensed'] ?? false;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _appointmentTile(
                    context: context,
                    name: name,
                    time: time,
                    reason: '$disease · Mobile: $mobile · $date',
                    patientId: patientId,
                    status: isDispensed ? 'Completed' : 'Issued',
                    statusColor: isDispensed ? Dr.green : Dr.amber,
                  ),
                );
              }),
            const SizedBox(height: 28),

            // ── Primary CTA ───────────────────────────────────
            DoctorPrimaryButton(
              label: 'Search Patient / Scan QR',
              icon: Icons.qr_code_scanner_rounded,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DoctorPatientSearchScreen(),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _appointmentTile({
    required BuildContext context,
    required String name,
    required String time,
    required String reason,
    required String patientId,
    required String status,
    required Color statusColor,
  }) {
    return GestureDetector(
      onTap: () =>
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DoctorPatientHistoryScreen(
                patientId: patientId,
                patientName: name,
              ),
            ),
          ).then((_) {
            // AppState could have been disposed/popped during signout/error Widget
            // check mounted to make sure context is valid
            if (context.mounted) {
              Provider.of<AppState>(context, listen: false).resumePolling(
                screen: 'DoctorDashboardScreen',
                reason: 'Doctor returned to dashboard from appointment tile',
              );
            }
          }),
      child: DoctorCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Time block
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Dr.green.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Dr.green.withOpacity(0.3), width: 1),
              ),
              child: Text(
                time,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Dr.green,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: Dr.heading(14),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    reason,
                    style: Dr.meta(12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            DoctorStatusBadge(label: status, color: statusColor),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded, color: Dr.border, size: 20),
          ],
        ),
      ),
    );
  }
}
