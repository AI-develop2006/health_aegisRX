import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/state/app_state.dart';
import '../../../shared/widgets/glassmorphic_button.dart';
import '../../../shared/widgets/neon_card.dart';
import 'doctor_onboarding_screen.dart';

class DoctorLoginScreen extends StatefulWidget {
  const DoctorLoginScreen({super.key});

  @override
  State<DoctorLoginScreen> createState() => _DoctorLoginScreenState();
}

class _DoctorLoginScreenState extends State<DoctorLoginScreen> {
  final _npiController = TextEditingController();

  void _login() {
    final appState = Provider.of<AppState>(context, listen: false);
    appState.setSession(
      role: UserRole.doctor,
      token: 'mock-jwt-token-doctor-${_npiController.text}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: NeonCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.local_hospital, size: 64, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 16),
                const Text(
                  'AegisRx Practitioner Portal',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _npiController,
                  decoration: const InputDecoration(
                    labelText: 'National Provider Identifier (NPI)',
                    prefixIcon: Icon(Icons.badge),
                  ),
                ),
                const SizedBox(height: 24),
                GlassmorphicButton(
                  onPressed: _login,
                  child: const Text('Access Clinician Suite'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const DoctorOnboardingScreen()),
                    );
                  },
                  child: const Text(
                    'Request a doctor account',
                    style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Provider.of<AppState>(context, listen: false).resetFlow();
                  },
                  child: const Text(
                    'Back to role selection',
                    style: TextStyle(fontFamily: 'Inter'),
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
