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
  @override
  Widget build(BuildContext context) {
    final state = Provider.of<SimulationState>(context);
    final vault = state.patientVault;
    final isAttendanceActive = state.isAttendanceActive;
    final selectedPrescription = state.selectedPrescriptionQR;

    // Doctor login link embedded in QR
    final String doctorPortalUrl =
        '${state.backendUrl}/doctor-login?patient=${Uri.encodeComponent(state.patientName)}';

    return Column(
      children: [
        // App header
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.clinicalBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.local_hospital_rounded,
                      color: AppColors.clinicalBlue,
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
                          color: AppColors.clinicalBlue,
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
                          AppColors.clinicalBlue,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Badge(
                      isLabelVisible: state.activePendingRequestId != null,
                      backgroundColor: AppColors.crimsonLockout,
                      label: const Text(
                        '1',
                        style: TextStyle(color: Colors.white, fontSize: 8),
                      ),
                      child: Icon(
                        state.activePendingRequestId != null
                            ? Icons.notifications_active_rounded
                            : Icons.notifications_outlined,
                        color: state.activePendingRequestId != null
                            ? AppColors.clinicalBlue
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
                // Medical Identity Card
                GlassCard(
                  borderRadius: 20,
                  backgroundColor: const Color.fromARGB(255, 46, 108, 243),
                  border: Border.all(color: Colors.transparent),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: const Color.fromARGB(
                          255,
                          255,
                          255,
                          255,
                        ),
                        child: Text(
                          state.patientName.length >= 2
                              ? state.patientName.substring(0, 2).toUpperCase()
                              : 'PT',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
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
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: AppColors.emeraldAccent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'Identity Verified',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white,
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
                          Row(
                            children: [
                              Icon(
                                isAttendanceActive
                                    ? Icons.lock_open_rounded
                                    : Icons.lock_rounded,
                                color: isAttendanceActive
                                    ? AppColors.emeraldAccent
                                    : AppColors.mutedText,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                  ),
                                  Text(
                                    isAttendanceActive
                                        ? 'Scan QR with doctor\'s device to begin'
                                        : 'Start a new consultation session',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.mutedText,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isAttendanceActive
                                  ? AppColors.emeraldAccent.withValues(
                                      alpha: 0.1,
                                    )
                                  : AppColors.darkRimGray,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isAttendanceActive ? 'ACTIVE' : 'LOCKED',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: isAttendanceActive
                                    ? AppColors.emeraldAccent
                                    : AppColors.mutedText,
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
                          backgroundColor: AppColors.clinicalBlue.withValues(
                            alpha: 0.08,
                          ),
                          borderColor: AppColors.clinicalBlue,
                          textColor: AppColors.clinicalBlue,
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
                                  color: AppColors.darkRimGray,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppColors.borderWhite,
                                  ),
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
                          backgroundColor: AppColors.crimsonLockout.withValues(
                            alpha: 0.06,
                          ),
                          borderColor: AppColors.crimsonLockout,
                          textColor: AppColors.crimsonLockout,
                          onPressed: () {
                            state.endSession();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Consultation ended. Doctor access revoked.',
                                ),
                                backgroundColor: AppColors.crimsonLockout,
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
                      final isSelected = selectedPrescription?.id == rx.id;

                      return InkWell(
                        onTap: () {
                          state.selectPrescription(rx);
                        },
                        child: Container(
                          decoration: isSelected
                              ? BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: AppColors.clinicalBlue.withValues(
                                      alpha: 0.4,
                                    ),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.clinicalBlue.withValues(
                                        alpha: 0.06,
                                      ),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                )
                              : null,
                          child: GlassCard(
                            borderRadius: 14,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: rx.isDispensed
                                        ? AppColors.darkRimGray
                                        : AppColors.clinicalBlue.withValues(
                                            alpha: 0.08,
                                          ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    rx.isDispensed
                                        ? Icons.inventory_2_outlined
                                        : Icons.medication_rounded,
                                    color: rx.isDispensed
                                        ? AppColors.mutedText
                                        : AppColors.clinicalBlue,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Disease Title + Date/Time Row
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
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
                                          ),
                                          const SizedBox(width: 8),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.access_time_rounded,
                                                size: 11,
                                                color: AppColors.mutedText,
                                              ),
                                              const SizedBox(width: 3),
                                              Text(
                                                '${rx.date} ${rx.time}',
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  color: AppColors.mutedText,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
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

                                // QR Scanner button or Dispensed badge at the right end
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (!rx.isDispensed)
                                      IconButton(
                                        icon: const Icon(
                                          Icons.qr_code_scanner_rounded,
                                          color: AppColors.clinicalBlue,
                                          size: 24,
                                        ),
                                        onPressed: () {
                                          state.selectPrescription(rx);
                                        },
                                      )
                                    else
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.emeraldAccent
                                              .withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: const Text(
                                          'DISPENSED',
                                          style: TextStyle(
                                            fontSize: 8,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.emeraldAccent,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                if (selectedPrescription != null &&
                    !selectedPrescription.isDispensed) ...[
                  const SizedBox(height: 24),
                  QrDrawer(prescription: selectedPrescription),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
