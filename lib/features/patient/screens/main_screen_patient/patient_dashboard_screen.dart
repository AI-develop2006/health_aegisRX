import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:health_lock/shared/models/prescription.dart';
import 'package:provider/provider.dart';
import '../../../../core/state/app_state.dart';

import '../../widgets/dose_timeline.dart';
import '../../widgets/consultation_status_chip.dart';
import '../../widgets/danger_banner.dart';
import '../../widgets/risk_gauge.dart';
import '../../widgets/inventory_tracker.dart';
import 'patient_history_screen.dart';
import '../patient_share_screen.dart';
import '../patient_medication_list_screen.dart';
import '../patient_prescription_detail_screen.dart';
import '../patient_notifications_screen.dart';

// ── 60-30-10 Design Tokens ─────────────────────────────────────
class _P {
  // 60% Dominant — Cream Canvas
  static const bg = Color(0xFFF7F4EB);
  static const card = Color(0xFFFFFFFF);

  // 30% Secondary — Bronze & Copper
  static const text = Color(0xFF4A3325); // Deep Matte Bronze
  static const sub = Color(0xFFD4A387); // Soft Rose Gold
  static const border = Color(0xFFB88E74); // Brushed Copper

  // 10% Accent — State Indicators
  static const teal = Color(0xFF2E8B90); // Deep Medical Teal (Done/Safe)
  static const amber = Color(0xFFD97736); // Warm Amber (Warning)
  static const red = Color(0xFFB33A3A); // Burgundy Red (Critical)
}

class PatientDashboardScreen extends StatefulWidget {
  const PatientDashboardScreen({super.key});

  @override
  State<PatientDashboardScreen> createState() => _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends State<PatientDashboardScreen> {
  final Set<String> _takenMeds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Provider.of<AppState>(context, listen: false);
      appState.fetchPatientProfile();
      appState.fetchPrescriptions();
      appState.fetchVisitHistory();
      appState.fetchActivityLogs();
    });
  }

  void _toggleStatus(String name) {
    setState(() {
      if (_takenMeds.contains(name)) {
        _takenMeds.remove(name);
      } else {
        _takenMeds.add(name);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final vault = appState.patientVault;

    // Derive today's medicines from active (undispensed) prescriptions
    final activePrescriptions = vault.where((rx) => !rx.isDispensed).toList();
    final List<Map<String, String>> todayMeds = [];
    for (var rx in activePrescriptions) {
      for (var med in rx.medicines) {
        final List<String> timings = [];
        if (med.morning) timings.add('Morning');
        if (med.afternoon) timings.add('Afternoon');
        if (med.evening) timings.add('Evening');
        if (med.night) timings.add('Night');
        final timingStr = timings.isEmpty ? med.interval : timings.join(', ');
        final foodStr = med.beforeFood
            ? ' (Before Food)'
            : (med.afterFood ? ' (After Food)' : '');
        final isTaken = _takenMeds.contains(med.name);
        todayMeds.add({
          'name': med.name,
          'schedule': '$timingStr$foodStr ${med.customInstruction}'.trim(),
          'status': isTaken ? 'Taken' : 'Due',
        });
      }
    }

    int riskScore = 8;
    bool hasPenicillinAllergy = appState.patientAllergies.any(
      (a) => a.toLowerCase().contains('penicillin'),
    );
    bool takingPenicillin = false;
    for (var rx in activePrescriptions) {
      for (var med in rx.medicines) {
        if (med.name.toLowerCase().contains('penicillin')) {
          takingPenicillin = true;
          break;
        }
      }
    }
    if (hasPenicillinAllergy && takingPenicillin) {
      riskScore = 95;
    } else if (activePrescriptions.isNotEmpty) {
      riskScore = 15;
    }

    return Scaffold(
      backgroundColor: _P.bg,
      appBar: AppBar(
        backgroundColor: _P.bg,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'AegisRx ',
                style: GoogleFonts.sora(
                  color: _P.text,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
              TextSpan(
                text: 'Patient Vault',
                style: GoogleFonts.inter(
                  color: _P.sub,
                  fontWeight: FontWeight.w500,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: _P.text),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PatientNotificationsScreen(),
                    ),
                  );
                },
              ),
              if (appState.activePendingRequestId != null)
                Positioned(
                  right: 12,
                  top: 12,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _P.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          if (appState.networkError)
            Container(
              color: _P.red,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                children: [
                  const Icon(
                    Icons.wifi_off_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'AegisRx Node Offline. Operating in sovereign offline-vault fallback mode.',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () async {
                      await appState.fetchPrescriptions();
                      await appState.fetchVisitHistory();
                    },
                    child: Text(
                      'RETRY',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // ── Session Row ───────────────────────────────────────
          Container(
            color: _P.bg,
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20.0, 4.0, 20.0, 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ConsultationStatusChip(
                  status: appState.isAttendanceActive ? 'active' : 'inactive',
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PatientShareScreen(),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.qr_code,
                    size: 18,
                    color: Colors.white,
                  ),
                  label: Text(
                    'Share Session',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _P.teal,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // ── Main Scrollable Content ───────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Header
                  Text(
                    'Good day, ${appState.patientName}',
                    style: GoogleFonts.sora(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: _P.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Today, ${DateTime.now().day} ${_getMonthName(DateTime.now().month)} ${DateTime.now().year}',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: _P.sub,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (hasPenicillinAllergy) ...[
                    const SizedBox(height: 16),
                    const DangerBanner(
                      message:
                          'CRITICAL ALERT: Documented severe Penicillin allergy.',
                    ),
                  ],
                  const SizedBox(height: 24),

                  // ── Status Row — 3 flat cards ─────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatusCard(
                          icon: Icons.description_rounded,
                          label: 'Prescriptions',
                          value: '${vault.length}',
                          iconColor: _P.teal,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatusCard(
                          icon: Icons.warning_amber_rounded,
                          label: 'Allergy Alerts',
                          value: '${appState.patientAllergies.length}',
                          iconColor: _P.amber,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatusCard(
                          icon: Icons.medical_services_rounded,
                          label: 'Consultation',
                          value: appState.isAttendanceActive ? 'Live' : 'None',
                          iconColor: appState.isAttendanceActive
                              ? _P.teal
                              : _P.sub,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (riskScore > 30) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: _buildFlatCard(
                            child: Center(
                              child: RiskGauge(severityScore: riskScore),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],

                  // ── Today's Medications card ─────────────────
                  _buildFlatCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Today's medications",
                              style: GoogleFonts.sora(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _P.text,
                              ),
                            ),
                            Icon(
                              Icons.today_rounded,
                              color: _P.border,
                              size: 22,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        todayMeds.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16.0,
                                ),
                                child: Center(
                                  child: Text(
                                    'No active medications for today.',
                                    style: GoogleFonts.inter(
                                      color: _P.sub,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: todayMeds.length,
                                separatorBuilder: (_, __) => Divider(
                                  color: _P.border.withOpacity(0.3),
                                  height: 16,
                                ),
                                itemBuilder: (context, index) {
                                  final med = todayMeds[index];
                                  final isTaken = med['status'] == 'Taken';
                                  return Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              med['name']!,
                                              style: GoogleFonts.inter(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                                color: _P.text,
                                                decoration: isTaken
                                                    ? TextDecoration.lineThrough
                                                    : null,
                                              ),
                                            ),
                                            Text(
                                              med['schedule']!,
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                color: _P.sub,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () =>
                                            _toggleStatus(med['name']!),
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isTaken
                                                ? _P.teal.withOpacity(0.1)
                                                : _P.amber.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: isTaken
                                                  ? _P.teal
                                                  : _P.amber,
                                              width: 1.5,
                                            ),
                                          ),
                                          child: Text(
                                            med['status']!,
                                            style: GoogleFonts.inter(
                                              color: isTaken
                                                  ? _P.teal
                                                  : _P.amber,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                        const SizedBox(height: 16),
                        Divider(color: _P.border.withOpacity(0.3)),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const PatientMedicationListScreen(),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.arrow_forward,
                              size: 16,
                              color: _P.teal,
                            ),
                            label: Text(
                              'See all medications',
                              style: GoogleFonts.inter(
                                color: _P.teal,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Prescription Status Summary ───────────────
                  _buildPrescriptionSummaryCard(context, vault),
                  const SizedBox(height: 24),

                  // ── Intake Timeline card ──────────────────────
                  _buildFlatCard(child: const DoseTimeline()),
                  const SizedBox(height: 24),

                  // ── Inventory Tracker card ───────────────────
                  _buildFlatCard(child: InventoryTracker(prescriptions: vault)),
                  const SizedBox(height: 24),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Flat Card builder ──────────────────────────────────────────
  Widget _buildFlatCard({required Widget child}) {
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

  // ── Status Summary card (top row) ─────────────────────────────
  Widget _buildStatusCard({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: _P.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _P.border, width: 1.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.sora(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: _P.text,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: _P.sub,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    if (month >= 1 && month <= 12) {
      return months[month - 1];
    }
    return '';
  }

  // ── Prescription Status Summary Card ──────────────────────────

  Widget _buildPrescriptionSummaryCard(
    BuildContext context,
    List<Prescription> vault,
  ) {
    final int activeCount = vault.where((rx) => !rx.isDispensed).length;
    final int dispensedCount = vault.where((rx) => rx.isDispensed).length;
    final int medicineCount = vault.fold(
      0,
      (sum, rx) => sum + rx.medicines.length,
    );

    return _buildFlatCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Text(
                  'Prescription Status',
                  style: GoogleFonts.sora(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _P.text,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              // Verified badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _P.teal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _P.teal.withOpacity(0.5), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.verified_rounded,
                      size: 13,
                      color: _P.teal,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Blockchain Secured',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _P.teal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Stat Row ────────────────────────────────────────
          Row(
            children: [
              _statPill(
                label: 'Active',
                value: '$activeCount',
                color: _P.teal,
                icon: Icons.check_circle_outline_rounded,
              ),
              const SizedBox(width: 10),
              _statPill(
                label: 'Dispensed',
                value: '$dispensedCount',
                color: _P.border,
                icon: Icons.local_pharmacy_outlined,
              ),
              const SizedBox(width: 10),
              _statPill(
                label: 'Medicines',
                value: '$medicineCount',
                color: _P.amber,
                icon: Icons.medication_outlined,
              ),
            ],
          ),

          if (vault.isEmpty) ...[
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  const Icon(
                    Icons.description_outlined,
                    size: 40,
                    color: _P.border,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No prescriptions yet',
                    style: GoogleFonts.inter(color: _P.sub, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your doctor will add them during a consultation.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(color: _P.sub, fontSize: 12),
                  ),
                ],
              ),
            ),
          ] else ...[
            Divider(color: _P.border.withOpacity(0.3), height: 28),

            // ── Prescription List ───────────────────────────
            ...vault.map(
              (rx) => Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          PatientPrescriptionDetailScreen(prescription: rx),
                    ),
                  ),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _P.bg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _P.border.withOpacity(0.4),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Status indicator dot
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: rx.isDispensed ? _P.border : _P.teal,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Dr. ${rx.doctorName}',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: _P.text,
                                ),
                              ),
                              Text(
                                '${rx.disease} · ${rx.medicines.length} med${rx.medicines.length == 1 ? '' : 's'}',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: _P.sub,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Status badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: rx.isDispensed
                                ? _P.border.withOpacity(0.1)
                                : _P.teal.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: rx.isDispensed
                                  ? _P.border.withOpacity(0.5)
                                  : _P.teal.withOpacity(0.6),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            rx.isDispensed ? 'Dispensed' : 'Active',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: rx.isDispensed ? _P.border : _P.teal,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 12,
                          color: _P.border,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── View History link ───────────────────────────
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PatientHistoryScreen(),
                  ),
                ),
                icon: const Icon(Icons.history, size: 16, color: _P.border),
                label: Text(
                  'Full History',
                  style: GoogleFonts.inter(
                    color: _P.border,
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
            ),
          ],
        ],
      ),
    );
  }


  // ── Stat pill widget ──────────────────────────────────────────
  Widget _statPill({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.sora(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: _P.text,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: _P.sub,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
