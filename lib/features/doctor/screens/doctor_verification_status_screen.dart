import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/state/app_state.dart';
import '../../../shared/widgets/neon_card.dart';

class DoctorVerificationStatusScreen extends StatelessWidget {
  const DoctorVerificationStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    // Simulate verification status based on mock data
    final isPending = !appState.isVerified;

    return Scaffold(
      appBar: AppBar(
        title: const Text('License Verification Status', style: TextStyle(fontFamily: 'Sora')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            appState.resetFlow();
          },
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: NeonCard(
            neonColor: isPending ? const Color(0xFFF59E0B) : const Color(0xFF10B981), // Amber Yellow or Emerald Green
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isPending ? Icons.pending_actions : Icons.check_circle_outline,
                  size: 80,
                  color: isPending ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                ),
                const SizedBox(height: 24),
                Text(
                  isPending ? 'Verification Pending' : 'License Verified',
                  style: const TextStyle(
                    fontFamily: 'Sora',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    isPending
                        ? 'Your license verification check is currently in progress. We are confirming credentials with NPI records. You can view clinical guides but cannot write prescriptions yet.'
                        : 'Your practitioner status has been successfully approved! You now have full access to the AI Safety audits and secure prescription signing console.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                if (isPending) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () {
                        // Simulate verification override for testing
                        appState.requestDoctorVerification(
                          name: 'Dr. John Doe',
                          license: 'NPI-MOCK-9988',
                          hospital: 'General Hospital',
                          specialty: 'Cardiology',
                          approved: true,
                        );
                      },
                      child: const Text(
                        'Simulate Approval Verification',
                        style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ] else ...[
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        // Simply redraw / force refresh
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Access Clinician Console',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    appState.resetFlow();
                  },
                  child: const Text(
                    'Return to Role Selection',
                    style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
