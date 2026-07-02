import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/state/app_state.dart';
import '../../../shared/widgets/glassmorphic_button.dart';
import '../../../shared/widgets/neon_card.dart';

class PatientLoginScreen extends StatefulWidget {
  const PatientLoginScreen({super.key});

  @override
  State<PatientLoginScreen> createState() => _PatientLoginScreenState();
}

class _PatientLoginScreenState extends State<PatientLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  void _login() {
    final appState = Provider.of<AppState>(context, listen: false);
    // Simulate API login and Cognito token receipt
    appState.setSession(
      role: UserRole.patient,
      token: 'mock-jwt-token-patient-${_emailController.text}',
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
                const Icon(
                  Icons.shield,
                  size: 64,
                  color: Color(0xFF0F52BA),
                ),
                const SizedBox(height: 16),
                const Text(
                  'AegisRx Patient Vault',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Sovereign ID or Email',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Key Phrase / Password',
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),
                const SizedBox(height: 24),
                GlassmorphicButton(
                  onPressed: _login,
                  child: const Text('Unlock Patient Vault'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
