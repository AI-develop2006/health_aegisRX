// ════════════════════════════════════════════════════════════════════════════
// AegisRx — Patient Dashboard Screen
// Design System: AegisRx Clinical Precision
// Business logic: UNCHANGED — all AppState reads, fetches, _toggleStatus,
//                 navigation routes, risk score logic preserved exactly
// ════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:health_lock/shared/models/prescription.dart';
import 'package:provider/provider.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/design_system.dart';

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

class PatientDashboardScreen extends StatefulWidget {
  const PatientDashboardScreen({super.key});

  @override
  State<PatientDashboardScreen> createState() => _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends State<PatientDashboardScreen> {
  final Set<String> _takenMeds = {};

  // ── BUSINESS LOGIC UNCHANGED ─────────────────────────────────────────────
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
  // ── END BUSINESS LOGIC ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final vault = appState.patientVault;

    // ── BUSINESS LOGIC UNCHANGED — medication + risk derivation ──────────────
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
    // ── END BUSINESS LOGIC ────────────────────────────────────────────────────

    final String initials = appState.patientName.isNotEmpty
        ? appState.patientName
              .split(' ')
              .where((w) => w.isNotEmpty)
              .take(2)
              .map((w) => w[0].toUpperCase())
              .join()
        : 'P';

    return Scaffold(
      backgroundColor: AegisColors.background,
      appBar: AppBar(
        backgroundColor: AegisColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        titleSpacing: AegisSpacing.pagePadding,
        title: Row(
          children: [
            // Avatar initials
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AegisColors.primary,
                borderRadius: BorderRadius.circular(AegisRadius.sm),
              ),
              child: Center(
                child: Text(
                  initials,
                  style: AegisTypography.labelMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AegisSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'AegisRx',
                  style: AegisTypography.titleSmall.copyWith(
                    color: AegisColors.primary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'Patient Vault',
                  style: AegisTypography.labelSmall.copyWith(
                    color: AegisColors.textTertiary,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Notifications bell with badge
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(
                  Icons.notifications_outlined,
                  color: AegisColors.textSecondary,
                  size: AegisIconSize.base,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    AegisMotion.fadeSlideRoute(
                      const PatientNotificationsScreen(),
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
                      color: AegisColors.danger,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AegisColors.surface,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: AegisSpacing.sm),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AegisColors.border),
        ),
      ),
      body: Column(
        children: [
          // ── Network Error Banner ──────────────────────────────
          if (appState.networkError)
            Container(
              color: AegisColors.danger,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                vertical: AegisSpacing.sm,
                horizontal: AegisSpacing.pagePadding,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.wifi_off_rounded,
                    color: Colors.white,
                    size: AegisIconSize.sm,
                  ),
                  const SizedBox(width: AegisSpacing.sm),
                  Expanded(
                    child: Text(
                      'AegisRx Node Offline. Operating in sovereign offline-vault fallback mode.',
                      style: AegisTypography.labelSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      await appState.fetchPrescriptions();
                      await appState.fetchVisitHistory();
                    },
                    child: Text(
                      'RETRY',
                      style: AegisTypography.labelSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // ── Session Status Row ────────────────────────────────
          Container(
            color: AegisColors.surface,
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(
              AegisSpacing.pagePadding,
              AegisSpacing.sm,
              AegisSpacing.pagePadding,
              AegisSpacing.md,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ConsultationStatusChip(
                  status: appState.isAttendanceActive ? 'active' : 'inactive',
                ),
                appState.isAttendanceActive
                    ? ElevatedButton.icon(
                        onPressed: () async {
                          await appState.cancelActiveSession();
                        },
                        icon: const Icon(
                          Icons.power_settings_new_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                        label: Text(
                          'Disconnect',
                          style: AegisTypography.labelMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AegisColors.danger,
                          elevation: 0,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AegisSpacing.md,
                            vertical: AegisSpacing.sm,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: AegisRadius.chip,
                          ),
                          textStyle: AegisTypography.labelMedium,
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PatientShareScreen(),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.qr_code_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                        label: Text(
                          'Share Session',
                          style: AegisTypography.labelMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AegisColors.secondary,
                          elevation: 0,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AegisSpacing.md,
                            vertical: AegisSpacing.sm,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: AegisRadius.chip,
                          ),
                          textStyle: AegisTypography.labelMedium,
                        ),
                      ),
              ],
            ),
          ),
          const Divider(height: 1, color: AegisColors.border),

          // ── Main Content ──────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AegisSpacing.pagePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome greeting
                  Text(
                    'Good day, ${appState.patientName}',
                    style: AegisTypography.displaySmall.copyWith(
                      color: AegisColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AegisSpacing.xs),
                  Text(
                    'Today, ${DateTime.now().day} ${_monthName(DateTime.now().month)} ${DateTime.now().year}',
                    style: AegisTypography.bodySmall.copyWith(
                      color: AegisColors.textSecondary,
                    ),
                  ),

                  // Allergy danger banner
                  if (hasPenicillinAllergy) ...[
                    const SizedBox(height: AegisSpacing.base),
                    const DangerBanner(
                      message:
                          'CRITICAL ALERT: Documented severe Penicillin allergy.',
                    ),
                  ],
                  const SizedBox(height: AegisSpacing.base),

                  // ── Status cards row ─────────────────────────
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _StatusCard(
                            icon: Icons.description_rounded,
                            label: 'Prescriptions',
                            value: '${vault.length}',
                            iconColor: AegisColors.primary,
                            iconBg: AegisColors.primarySurface,
                          ),
                        ),
                        const SizedBox(width: AegisSpacing.sm),
                        Expanded(
                          child: _StatusCard(
                            icon: Icons.warning_amber_rounded,
                            label: 'Allergy Alerts',
                            value: '${appState.patientAllergies.length}',
                            iconColor: AegisColors.warning,
                            iconBg: AegisColors.warningLight,
                          ),
                        ),
                        const SizedBox(width: AegisSpacing.sm),
                        Expanded(
                          child: _StatusCard(
                            icon: Icons.medical_services_rounded,
                            label: 'Consultation',
                            value: appState.isAttendanceActive
                                ? 'Live'
                                : 'None',
                            iconColor: appState.isAttendanceActive
                                ? AegisColors.secondary
                                : AegisColors.textTertiary,
                            iconBg: appState.isAttendanceActive
                                ? AegisColors.secondarySurface
                                : AegisColors.surfaceDim,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AegisSpacing.base),

                  // ── Risk Gauge ───────────────────────────────
                  if (riskScore > 30) ...[
                    _DashCard(
                      child: Center(child: RiskGauge(severityScore: riskScore)),
                    ),
                    const SizedBox(height: AegisSpacing.base),
                  ],

                  // ── Today's Medications ──────────────────────
                  _DashCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _CardHeader(
                          title: "Today's Medications",
                          icon: Icons.medication_rounded,
                          iconColor: AegisColors.secondary,
                          iconBg: AegisColors.secondarySurface,
                        ),
                        const SizedBox(height: AegisSpacing.md),
                        const Divider(height: 1, color: AegisColors.border),
                        const SizedBox(height: AegisSpacing.md),
                        todayMeds.isEmpty
                            ? _EmptyState(
                                icon: Icons.medication_liquid_outlined,
                                message: 'No active medications for today.',
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: todayMeds.length,
                                separatorBuilder: (_, child) => const Divider(
                                  height: AegisSpacing.md,
                                  color: AegisColors.border,
                                ),
                                itemBuilder: (context, index) {
                                  final med = todayMeds[index];
                                  final isTaken = med['status'] == 'Taken';
                                  return Row(
                                    children: [
                                      // Status dot
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isTaken
                                              ? AegisColors.secondary
                                              : AegisColors.warning,
                                        ),
                                      ),
                                      const SizedBox(width: AegisSpacing.sm),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              med['name']!,
                                              style: AegisTypography.titleSmall
                                                  .copyWith(
                                                    color:
                                                        AegisColors.textPrimary,
                                                    decoration: isTaken
                                                        ? TextDecoration
                                                              .lineThrough
                                                        : null,
                                                  ),
                                            ),
                                            Text(
                                              med['schedule']!,
                                              style: AegisTypography.bodySmall
                                                  .copyWith(
                                                    color: AegisColors
                                                        .textSecondary,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: AegisSpacing.sm),
                                      GestureDetector(
                                        onTap: () =>
                                            _toggleStatus(med['name']!),
                                        child: AnimatedContainer(
                                          duration: AegisMotion.moderate,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: AegisSpacing.sm,
                                            vertical: AegisSpacing.xs,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isTaken
                                                ? AegisColors.secondary
                                                      .withValues(alpha: 0.1)
                                                : AegisColors.warning
                                                      .withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(
                                              AegisRadius.sm,
                                            ),
                                            border: Border.all(
                                              color: isTaken
                                                  ? AegisColors.secondary
                                                  : AegisColors.warning,
                                              width: AegisBorders.regular,
                                            ),
                                          ),
                                          child: Text(
                                            med['status']!,
                                            style: AegisTypography.labelSmall
                                                .copyWith(
                                                  color: isTaken
                                                      ? AegisColors.secondary
                                                      : AegisColors.warning,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                        const SizedBox(height: AegisSpacing.md),
                        const Divider(height: 1, color: AegisColors.border),
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
                              Icons.arrow_forward_rounded,
                              size: AegisIconSize.sm,
                              color: AegisColors.primary,
                            ),
                            label: Text(
                              'See all medications',
                              style: AegisTypography.labelSmall.copyWith(
                                color: AegisColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AegisSpacing.base),

                  // ── Prescription Status Summary ───────────────
                  _buildPrescriptionSummaryCard(context, vault),
                  const SizedBox(height: AegisSpacing.base),

                  // ── Dose Timeline ─────────────────────────────
                  _DashCard(child: const DoseTimeline()),
                  const SizedBox(height: AegisSpacing.base),

                  // ── Inventory Tracker ─────────────────────────
                  _DashCard(child: InventoryTracker(prescriptions: vault)),
                  const SizedBox(height: AegisSpacing.base),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Prescription Summary Card ─────────────────────────────────────────────
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

    return _DashCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with blockchain badge
          Row(
            children: [
              Expanded(
                child: _CardHeader(
                  title: 'Prescription Status',
                  icon: Icons.description_rounded,
                  iconColor: AegisColors.primary,
                  iconBg: AegisColors.primarySurface,
                ),
              ),
              // Blockchain secured — AI Purple per color rules
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AegisSpacing.sm,
                  vertical: AegisSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AegisColors.tertiarySurface,
                  borderRadius: AegisRadius.chip,
                  border: Border.all(
                    color: AegisColors.tertiary.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.link_rounded,
                      size: AegisIconSize.xs,
                      color: AegisColors.tertiary,
                    ),
                    const SizedBox(width: AegisSpacing.xs),
                    Text(
                      'Hyperledger',
                      style: AegisTypography.labelSmall.copyWith(
                        color: AegisColors.tertiary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AegisSpacing.md),
          const Divider(height: 1, color: AegisColors.border),
          const SizedBox(height: AegisSpacing.md),

          // Stat pills
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _StatPill(
                  label: 'Active',
                  value: '$activeCount',
                  color: AegisColors.secondary,
                  icon: Icons.check_circle_outline_rounded,
                ),
                const SizedBox(width: AegisSpacing.sm),
                _StatPill(
                  label: 'Dispensed',
                  value: '$dispensedCount',
                  color: AegisColors.textTertiary,
                  icon: Icons.local_pharmacy_outlined,
                ),
                const SizedBox(width: AegisSpacing.sm),
                _StatPill(
                  label: 'Medicines',
                  value: '$medicineCount',
                  color: AegisColors.warning,
                  icon: Icons.medication_outlined,
                ),
              ],
            ),
          ),

          if (vault.isEmpty) ...[
            const SizedBox(height: AegisSpacing.lg),
            _EmptyState(
              icon: Icons.description_outlined,
              message: 'No prescriptions yet',
              sub: 'Your doctor will add them during a consultation.',
            ),
          ] else ...[
            const SizedBox(height: AegisSpacing.md),
            const Divider(height: 1, color: AegisColors.border),
            const SizedBox(height: AegisSpacing.sm),

            // Prescription list
            ...vault.map(
              (rx) => Padding(
                padding: const EdgeInsets.only(bottom: AegisSpacing.sm),
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          PatientPrescriptionDetailScreen(prescription: rx),
                    ),
                  ),
                  borderRadius: AegisRadius.card,
                  child: Container(
                    padding: const EdgeInsets.all(AegisSpacing.md),
                    decoration: BoxDecoration(
                      color: AegisColors.background,
                      borderRadius: AegisRadius.card,
                      border: Border.all(color: AegisColors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: rx.isDispensed
                                ? AegisColors.textTertiary
                                : AegisColors.secondary,
                          ),
                        ),
                        const SizedBox(width: AegisSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Dr. ${rx.doctorName}',
                                style: AegisTypography.titleSmall.copyWith(
                                  color: AegisColors.textPrimary,
                                ),
                              ),
                              Text(
                                '${rx.disease} · ${rx.medicines.length} med${rx.medicines.length == 1 ? '' : 's'}',
                                style: AegisTypography.bodySmall.copyWith(
                                  color: AegisColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AegisSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AegisSpacing.sm,
                            vertical: AegisSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: rx.isDispensed
                                ? AegisColors.surfaceDim
                                : AegisColors.secondarySurface,
                            borderRadius: BorderRadius.circular(AegisRadius.xs),
                            border: Border.all(
                              color: rx.isDispensed
                                  ? AegisColors.border
                                  : AegisColors.secondary.withValues(
                                      alpha: 0.5,
                                    ),
                            ),
                          ),
                          child: Text(
                            rx.isDispensed ? 'Dispensed' : 'Active',
                            style: AegisTypography.labelSmall.copyWith(
                              color: rx.isDispensed
                                  ? AegisColors.textTertiary
                                  : AegisColors.secondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: AegisSpacing.xs),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: AegisIconSize.xs,
                          color: AegisColors.textTertiary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PatientHistoryScreen(),
                  ),
                ),
                icon: const Icon(
                  Icons.history_rounded,
                  size: AegisIconSize.sm,
                  color: AegisColors.textSecondary,
                ),
                label: Text(
                  'Full History',
                  style: AegisTypography.labelSmall.copyWith(
                    color: AegisColors.textSecondary,
                    fontWeight: FontWeight.w700,
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

  String _monthName(int month) {
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
    if (month >= 1 && month <= 12) return months[month - 1];
    return '';
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Reusable Dashboard Components
// ═══════════════════════════════════════════════════════════════════════════

/// Base clinical white card with AegisRx shadow + border
class _DashCard extends StatelessWidget {
  final Widget child;
  const _DashCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AegisSpacing.base),
      decoration: BoxDecoration(
        color: AegisColors.surface,
        borderRadius: AegisRadius.card,
        border: Border.all(color: AegisColors.border),
        boxShadow: AegisShadows.sm,
      ),
      child: child,
    );
  }
}

/// Card section header with colored icon badge
class _CardHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;

  const _CardHeader({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(AegisRadius.sm),
          ),
          child: Icon(icon, size: AegisIconSize.sm, color: iconColor),
        ),
        const SizedBox(width: AegisSpacing.sm),
        Expanded(
          child: Text(
            title,
            overflow: TextOverflow.ellipsis,
            style: AegisTypography.titleSmall.copyWith(
              color: AegisColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

/// Top summary status card (3-column row)
class _StatusCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final Color iconBg;

  const _StatusCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    required this.iconBg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AegisSpacing.md,
        horizontal: AegisSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AegisColors.surface,
        borderRadius: AegisRadius.card,
        border: Border.all(color: AegisColors.border),
        boxShadow: AegisShadows.sm,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(AegisRadius.sm),
            ),
            child: Icon(icon, color: iconColor, size: AegisIconSize.sm),
          ),
          const SizedBox(height: AegisSpacing.xs),
          Text(
            value,
            style: AegisTypography.headlineSmall.copyWith(
              color: AegisColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AegisTypography.labelSmall.copyWith(
              color: AegisColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Expandable stat pill for prescription summary
class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatPill({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AegisSpacing.sm,
          horizontal: AegisSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: AegisRadius.card,
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: AegisIconSize.sm, color: color),
            const SizedBox(height: AegisSpacing.xs),
            Text(
              value,
              style: AegisTypography.headlineSmall.copyWith(
                fontWeight: FontWeight.w800,
                color: AegisColors.textPrimary,
              ),
            ),
            Text(
              label,
              style: AegisTypography.labelSmall.copyWith(
                color: AegisColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Centered empty state placeholder
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? sub;

  const _EmptyState({required this.icon, required this.message, this.sub});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AegisSpacing.base),
      child: Center(
        child: Column(
          children: [
            Icon(
              icon,
              size: AegisIconSize.xxl,
              color: AegisColors.textTertiary,
            ),
            const SizedBox(height: AegisSpacing.sm),
            Text(
              message,
              style: AegisTypography.bodyMedium.copyWith(
                color: AegisColors.textSecondary,
              ),
            ),
            if (sub != null) ...[
              const SizedBox(height: AegisSpacing.xs),
              Text(
                sub!,
                textAlign: TextAlign.center,
                style: AegisTypography.bodySmall.copyWith(
                  color: AegisColors.textTertiary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
