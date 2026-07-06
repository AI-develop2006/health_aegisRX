import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/state/app_state.dart';
import '../../../../shared/widgets/neon_card.dart';

class PatientAuthChoiceScreen extends StatelessWidget {
  const PatientAuthChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final appState = Provider.of<AppState>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Access Vault', style: TextStyle(fontFamily: 'Sora')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            appState.resetFlow();
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              const Text(
                'Sign in or create your patient account',
                style: TextStyle(
                  fontFamily: 'Sora',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Decentralized encryption keys secure your medical data.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  color: isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 48),
              Expanded(
                child: ListView(
                  children: [
                    _buildChoiceCard(
                      context: context,
                      title: 'I am a new patient',
                      description: 'Create a local patient health vault and generate unique cryptographic key pairs.',
                      icon: Icons.person_add_rounded,
                      color: const Color(0xFF4F46E5), // Indigo
                      onTap: () {
                        appState.setPatientAuthState(PatientAuthState.signup);
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildChoiceCard(
                      context: context,
                      title: 'I already have an account',
                      description: 'Enter your credentials to decrypt and unlock your existing medical vault records.',
                      icon: Icons.vpn_key_rounded,
                      color: const Color(0xFF0D9488), // Teal
                      onTap: () {
                        appState.setPatientAuthState(PatientAuthState.login);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceCard({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return GestureDetector(
      onTap: onTap,
      child: NeonCard(
        neonColor: color,
        borderWidth: 1.5,
        padding: const EdgeInsets.all(20.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 28,
                color: color,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Sora',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: isLight ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isLight ? Colors.grey : Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }
}
