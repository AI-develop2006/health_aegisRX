import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:health_lock/core/constants/app_colors.dart';
import 'package:health_lock/core/theme/app_theme.dart';
import 'package:health_lock/shared/widgets/custom_button.dart';
import 'package:health_lock/features/patient/widgets/qr_drawer.dart';
import 'package:health_lock/main.dart'; // To access SimulationState
import 'package:health_lock/features/patient/screens/patient_settings.dart';

class PatientVault extends StatefulWidget {
  final VoidCallback? onNotificationTap;
  const PatientVault({super.key, this.onNotificationTap});

  @override
  State<PatientVault> createState() => _PatientVaultState();
}

class _PatientVaultState extends State<PatientVault> {
  String _formatToIndianTime(String timeStr) {
    if (timeStr.isEmpty) return '';
    try {
      final parts = timeStr.split(':');
      if (parts.isNotEmpty) {
        int hour = int.parse(parts[0]);
        int minute = parts.length > 1 ? int.parse(parts[1]) : 0;
        String period = 'AM';
        if (hour >= 12) {
          period = 'PM';
          if (hour > 12) {
            hour -= 12;
          }
        }
        if (hour == 0) {
          hour = 12;
        }
        final hrStr = hour.toString().padLeft(2, '0');
        final minStr = minute.toString().padLeft(2, '0');
        return '$hrStr:$minStr $period';
      }
    } catch (_) {}
    return timeStr;
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<SimulationState>(context);
    final vault = state.patientVault;
    final isAttendanceActive = state.isAttendanceActive;

    // Doctor login link embedded in QR — timestamp is fixed at session-start to avoid QR drift
    final int qrTs =
        state.sessionStartMs ?? DateTime.now().millisecondsSinceEpoch;
    final String doctorPortalUrl =
        '${state.backendUrl}/doctor-login?patient=${Uri.encodeComponent(state.patientName)}&t=$qrTs';

    return Column(
      children: [
        // App header
        Container(
          color: AppColors.cardSurface,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.tintBlue,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.patientBlue.withValues(alpha: 0.2),
                      ),
                    ),
                    child: const Icon(
                      Icons.local_hospital_rounded,
                      color: AppColors.patientBlue,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'HealthLock',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryText,
                          letterSpacing: 0.3,
                        ),
                      ),
                      Text(
                        '${state.patientName}\'s Wallet',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.patientBlue,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  if (state.isLoading)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.patientBlue,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Badge(
                      isLabelVisible: state.activePendingRequestId != null,
                      backgroundColor: AppColors.statusCritical,
                      label: const Text(
                        '1',
                        style: TextStyle(color: Colors.white, fontSize: 8),
                      ),
                      child: Icon(
                        state.activePendingRequestId != null
                            ? Icons.notifications_active_rounded
                            : Icons.notifications_outlined,
                        color: state.activePendingRequestId != null
                            ? AppColors.patientBlue
                            : AppColors.mutedText,
                        size: 20,
                      ),
                    ),
                    onPressed: widget.onNotificationTap,
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.settings_outlined,
                      color: AppColors.mutedText,
                      size: 20,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PatientSettingsPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Medical Identity Card — Solid Blue Gradient
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.patientBlue,
                        AppColors.patientBlueDark,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.patientBlue.withValues(alpha: 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 26,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.15,
                            ),
                            child: Text(
                              state.patientName.length >= 2
                                  ? state.patientName
                                        .substring(0, 2)
                                        .toUpperCase()
                                  : 'PT',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                state.patientName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                state.patientEmailOrId,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: AppColors.verifiedEmerald,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Identity Verified',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white.withValues(
                                        alpha: 0.9,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // DOCTOR CONSULTATION SECTION
                const Text(
                  'DOCTOR CONSULTATION',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    color: AppColors.mutedText,
                  ),
                ),
                const SizedBox(height: 10),
                GlassCard(
                  borderRadius: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isAttendanceActive
                                        ? AppColors.tintTeal
                                        : AppColors.tintSlate,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    isAttendanceActive
                                        ? Icons.lock_open_rounded
                                        : Icons.lock_rounded,
                                    color: isAttendanceActive
                                        ? AppColors.doctorTeal
                                        : AppColors.statusLocked,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isAttendanceActive
                                            ? 'Consultation Active'
                                            : 'Consultation Inactive',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primaryText,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        isAttendanceActive
                                            ? 'Scan QR with doctor\'s device to begin'
                                            : 'Start a new consultation session',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.mutedText,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: isAttendanceActive
                                  ? AppColors.tintTeal
                                  : AppColors.tintSlate,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isAttendanceActive
                                    ? AppColors.doctorTeal.withValues(
                                        alpha: 0.2,
                                      )
                                    : AppColors.borderWhite,
                              ),
                            ),
                            child: Text(
                              isAttendanceActive ? 'ACTIVE' : 'LOCKED',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: isAttendanceActive
                                    ? AppColors.doctorTeal
                                    : AppColors.statusLocked,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (!isAttendanceActive) ...[
                        const SizedBox(height: 16),
                        CustomButton(
                          text: 'START DOCTOR CONSULTATION',
                          icon: Icons.qr_code_2_rounded,
                          backgroundColor: AppColors.doctorTeal,
                          textColor: Colors.white,
                          onPressed: () {
                            state.setAttendance(true);
                          },
                        ),
                      ] else ...[
                        const SizedBox(height: 16),
                        Center(
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.doctorTeal.withValues(
                                        alpha: 0.15,
                                      ),
                                      blurRadius: 20,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: QrImageView(
                                  data: doctorPortalUrl,
                                  version: QrVersions.auto,
                                  size: 140,
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Scan this QR with the Doctor\'s device',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryText,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Opens: $doctorPortalUrl',
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: AppColors.mutedText,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        CustomButton(
                          text: 'END CONSULTATION SESSION',
                          icon: Icons.cancel_outlined,
                          backgroundColor: AppColors.statusCritical,
                          textColor: Colors.white,
                          onPressed: () {
                            state.endSession();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Consultation ended. Doctor access revoked.',
                                ),
                                backgroundColor: AppColors.statusCritical,
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // MY PRESCRIPTIONS
                const Text(
                  'MY PRESCRIPTIONS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    color: AppColors.mutedText,
                  ),
                ),
                const SizedBox(height: 10),
                if (vault.isEmpty)
                  const GlassCard(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.medication_outlined,
                              size: 32,
                              color: AppColors.mutedText,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'No prescriptions yet.',
                              style: TextStyle(
                                color: AppColors.mutedText,
                                fontSize: 13,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Start a consultation to receive prescriptions.',
                              style: TextStyle(
                                color: AppColors.mutedText,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: vault.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final rx = vault[index];

                      return GlassCard(
                        borderRadius: 14,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Stack(
                          children: [
                            Row(
                              children: [
                                // Colored accent bar (Left edge indicator)
                                Container(
                                  width: 4,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(2),
                                    color: rx.isDispensed
                                        ? AppColors.verifiedEmerald
                                        : AppColors.doctorTeal,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: rx.isDispensed
                                        ? AppColors.tintSlate
                                        : AppColors.tintTeal,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    rx.isDispensed
                                        ? Icons.inventory_2_outlined
                                        : Icons.medication_rounded,
                                    color: rx.isDispensed
                                        ? AppColors.mutedText
                                        : AppColors.doctorTeal,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Disease Title
                                      Text(
                                        rx.disease,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: rx.isDispensed
                                              ? AppColors.mutedText
                                              : AppColors.primaryText,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),

                                      // Doctor + Clinic Details Row
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.person_outline_rounded,
                                            size: 13,
                                            color: AppColors.mutedText,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            rx.doctorName,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.primaryText,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          const Icon(
                                            Icons.local_hospital_outlined,
                                            size: 13,
                                            color: AppColors.mutedText,
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              rx.hospitalName,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: AppColors.mutedText,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),

                                      // Medications count
                                      Text(
                                        'Medications: ${rx.medicines.length} item(s)',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.mutedText,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 14),

                                // QR Scanner button — opens popup, or Dispensed badge
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (!rx.isDispensed)
                                      Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          onTap: () {
                                            showQrPopup(context, rx);
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: AppColors.tintTeal,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                color: AppColors.doctorTeal
                                                    .withValues(alpha: 0.2),
                                              ),
                                            ),
                                            child: const Icon(
                                              Icons.qr_code_scanner_rounded,
                                              color: AppColors.doctorTeal,
                                              size: 22,
                                            ),
                                          ),
                                        ),
                                      )
                                    else
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.tintEmerald,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          border: Border.all(
                                            color: AppColors.verifiedEmerald
                                                .withValues(alpha: 0.2),
                                          ),
                                        ),
                                        child: const Text(
                                          'DISPENSED',
                                          style: TextStyle(
                                            fontSize: 8,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.verifiedEmerald,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Text(
                                rx.date,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.mutedText,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 4,
                              child: Text(
                                _formatToIndianTime(rx.time),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.mutedText,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                const SizedBox(height: 28),

                // CHAIN LEDGER ACTIVITY
                const Text(
                  'CHAIN LEDGER ACTIVITY',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    color: AppColors.mutedText,
                  ),
                ),
                const SizedBox(height: 10),
                if (!state.isOfflineGuest && state.visitHistory.isEmpty)
                  const GlassCard(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 20.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.link_rounded,
                              size: 28,
                              color: AppColors.mutedText,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'No blockchain records yet.',
                              style: TextStyle(
                                color: AppColors.mutedText,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else if (state.isOfflineGuest)
                  GlassCard(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Text(
                          'Log in to view your secure ledger history.',
                          style: const TextStyle(
                            color: AppColors.mutedText,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: state.visitHistory.length,
                    separatorBuilder: (context, i) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final block = state.visitHistory[index];
                      final data = block['data'] as Map<String, dynamic>? ?? {};
                      final ts = block['timestamp'];
                      String timeStr = '';
                      if (ts is int) {
                        final dt = DateTime.fromMillisecondsSinceEpoch(
                          ts,
                        ).toLocal();
                        timeStr =
                            '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                      }
                      return GlassCard(
                        borderRadius: 12,
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: AppColors.tintEmerald,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.link_rounded,
                                color: AppColors.verifiedEmerald,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          data['disease'] ?? 'Visit',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primaryText,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        '#${block['index'] ?? ''}',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontFamily: 'monospace',
                                          color: AppColors.verifiedEmerald,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Dr. ${data['doctor_name'] ?? ''} — ${data['hospital'] ?? ''}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.mutedText,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (timeStr.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      timeStr,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: AppColors.mutedText,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
