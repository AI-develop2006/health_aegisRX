import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/state/app_state.dart';
import '../../../shared/widgets/glassmorphic_button.dart';
import '../../../shared/widgets/neon_card.dart';

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
            neonColor: const Color(0xFF0F52BA),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.local_hospital, size: 64, color: Color(0xFF0F52BA)),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
