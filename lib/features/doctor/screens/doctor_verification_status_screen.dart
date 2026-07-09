import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/state/app_state.dart';
import '../doctor_theme.dart';

class DoctorVerificationStatusScreen extends StatelessWidget {
  const DoctorVerificationStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isPending = !appState.isVerified;

    final stateColor = isPending ? Dr.amber : Dr.green;
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
              style: GoogleFonts.inter(color: Dr.sub, fontSize: 13),
            ),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ── Status Icon ──────────────────────────────────
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: stateColor.withOpacity(0.08),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: stateColor.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Icon(stateIcon, size: 60, color: stateColor),
              ),
              const SizedBox(height: 24),

              Text(
                stateTitle,
                style: Dr.heading(22),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // ── Status card ──────────────────────────────────
              DoctorCard(
                borderColor: stateColor.withOpacity(0.3),
                child: Column(
                  children: [
                    // Progress row
                    Row(
                      children: [
                        _step(label: 'Submitted', done: true, color: Dr.green),
                        _stepLine(active: !isPending),
                        _step(
                          label: 'NPI Check',
                          done: !isPending,
                          color: isPending ? Dr.amber : Dr.green,
                        ),
                        _stepLine(active: !isPending),
                        _step(
                          label: 'Approved',
                          done: !isPending,
                          color: !isPending ? Dr.green : Dr.border,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      stateBody,
                      textAlign: TextAlign.center,
                      style: Dr.meta(13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── CTA ──────────────────────────────────────────
              if (isPending) ...[
                DoctorOutlinedButton(
                  label: 'Simulate Approval (Dev)',
                  icon: Icons.developer_mode_rounded,
                  color: Dr.amber,
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
                  onPressed: () {},
                ),
              ],
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => appState.resetFlow(),
                child: Text(
                  'Return to Role Selection',
                  style: GoogleFonts.inter(
                    color: Dr.sub,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
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
        Text(label, style: GoogleFonts.inter(fontSize: 10, color: Dr.sub)),
      ],
    );
  }

  Widget _stepLine({required bool active}) {
    return Expanded(
      child: Container(
        height: 1.5,
        margin: const EdgeInsets.only(bottom: 16),
        color: active ? Dr.green : Dr.border,
      ),
    );
  }
}
