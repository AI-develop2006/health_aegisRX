// ════════════════════════════════════════════════════════════════════════════
// AegisRx — Doctor License Verification Screen
// Design System: AegisRx Clinical Precision
// Business logic: UNCHANGED — appState.isVerified, requestDoctorVerification(),
//                 resetFlow() preserved
// ════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/state/app_state.dart';
import '../../../core/theme/design_system.dart';
import '../doctor_theme.dart';

class DoctorVerificationStatusScreen extends StatelessWidget {
  const DoctorVerificationStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isPending = !appState.isVerified;

    final stateColor = isPending ? AegisColors.warning : AegisColors.secondary;
    final stateBg = isPending ? AegisColors.warningLight : AegisColors.secondarySurface;
    final stateIcon = isPending
        ? Icons.pending_actions_rounded
        : Icons.verified_rounded;
    final stateTitle = isPending ? 'Verification Pending' : 'License Verified';
    final stateBody = isPending
        ? 'Your license verification is in progress. We are confirming credentials with NPI records. You can view clinical guides but cannot write prescriptions yet.'
        : 'Your practitioner status has been successfully approved. You now have full access to the AI Safety audits and secure prescription signing console.';

    return ClinicalScaffold(
      appBar: clinicalAppBar(
        title: 'License Verification',
        actions: [
          TextButton(
            onPressed: () => appState.resetFlow(),
            child: Text(
              'Sign Out',
              style: AegisTypography.labelSmall.copyWith(color: AegisColors.textSecondary),
            ),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AegisSpacing.pagePadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ── Status Icon ──────────────────────────────────
              Container(
                padding: const EdgeInsets.all(AegisSpacing.lg),
                decoration: BoxDecoration(
                  color: stateBg,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: stateColor.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: Icon(stateIcon, size: 60, color: stateColor),
              ),
              const SizedBox(height: AegisSpacing.lg),

              Text(
                stateTitle,
                style: AegisTypography.headlineMedium.copyWith(color: AegisColors.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AegisSpacing.sm),

              // ── Status card ──────────────────────────────────
              DoctorCard(
                borderColor: stateColor.withValues(alpha: 0.4),
                child: Column(
                  children: [
                    // Progress row
                    Row(
                      children: [
                        _step(label: 'Submitted', done: true, color: AegisColors.secondary),
                        _stepLine(active: !isPending),
                        _step(
                          label: 'NPI Check',
                          done: !isPending,
                          color: isPending ? AegisColors.warning : AegisColors.secondary,
                        ),
                        _stepLine(active: !isPending),
                        _step(
                          label: 'Approved',
                          done: !isPending,
                          color: !isPending ? AegisColors.secondary : AegisColors.border,
                        ),
                      ],
                    ),
                    const SizedBox(height: AegisSpacing.base),
                    Text(
                      stateBody,
                      textAlign: TextAlign.center,
                      style: AegisTypography.bodyMedium.copyWith(color: AegisColors.textSecondary, height: 1.6),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AegisSpacing.lg),

              // ── CTA ──────────────────────────────────────────
              if (isPending) ...[
                DoctorOutlinedButton(
                  label: 'Simulate Approval (Dev)',
                  icon: Icons.developer_mode_rounded,
                  color: AegisColors.warning,
                  onPressed: () => appState.requestDoctorVerification(
                    name: 'Dr. John Doe',
                    license: 'NPI-MOCK-9988',
                    hospital: 'General Hospital',
                    specialty: 'Cardiology',
                    approved: true,
                  ),
                ),
              ] else ...[
                DoctorPrimaryButton(
                  label: 'Access Clinician Console',
                  icon: Icons.dashboard_rounded,
                  backgroundColor: AegisColors.primary,
                  onPressed: () {},
                ),
              ],
              const SizedBox(height: AegisSpacing.sm),
              TextButton(
                onPressed: () => appState.resetFlow(),
                child: Text(
                  'Return to Role Selection',
                  style: AegisTypography.labelSmall.copyWith(
                    color: AegisColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _step({
    required String label,
    required bool done,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: done ? color : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 1.5),
          ),
          child: done
              ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
              : null,
        ),
        const SizedBox(height: 4),
        Text(label, style: AegisTypography.labelSmall.copyWith(fontSize: 10, color: AegisColors.textSecondary)),
      ],
    );
  }

  Widget _stepLine({required bool active}) {
    return Expanded(
      child: Container(
        height: 1.5,
        margin: const EdgeInsets.only(bottom: 16),
        color: active ? AegisColors.secondary : AegisColors.border,
      ),
    );
  }
}
