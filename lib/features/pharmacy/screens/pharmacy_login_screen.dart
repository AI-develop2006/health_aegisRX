import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/state/app_state.dart';
import '../../../shared/widgets/glassmorphic_button.dart';
import '../../../shared/widgets/neon_card.dart';

class PharmacyLoginScreen extends StatefulWidget {
  const PharmacyLoginScreen({super.key});

  @override
  State<PharmacyLoginScreen> createState() => _PharmacyLoginScreenState();
}

class _PharmacyLoginScreenState extends State<PharmacyLoginScreen> {
  final _licenseController = TextEditingController();

  void _login() {
    final appState = Provider.of<AppState>(context, listen: false);
    appState.setSession(
      role: UserRole.pharmacy,
      token: 'mock-jwt-token-pharmacy-${_licenseController.text}',
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
                const Icon(Icons.medication, size: 64, color: Color(0xFF0F52BA)),
                const SizedBox(height: 16),
                const Text(
                  'AegisRx Pharmacy Portal',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _licenseController,
                  decoration: const InputDecoration(
                    labelText: 'Pharmacy License Number',
                    prefixIcon: Icon(Icons.assignment),
                  ),
                ),
                const SizedBox(height: 24),
                GlassmorphicButton(
                  onPressed: _login,
                  child: const Text('Access Dispensation Desk'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
