import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/state/app_state.dart';
import '../../../shared/widgets/neon_card.dart';
import '../../../shared/widgets/glassmorphic_button.dart';

class PatientSecureSignInScreen extends StatelessWidget {
  const PatientSecureSignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final appState = Provider.of<AppState>(context, listen: false);

    // 60-30-10 Color Tokens
    final bg60 = isLight ? const Color(0xFFF5F6FA) : const Color(0xFF0B0F19);
    final accent10 = isLight ? const Color(0xFF4F46E5) : const Color(0xFF818CF8);

    return Scaffold(
      backgroundColor: bg60,
      appBar: AppBar(
        title: const Text('Secure Verification', style: TextStyle(fontFamily: 'Sora')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            appState.setPatientAuthState(PatientAuthState.login);
          },
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: NeonCard(
            neonColor: accent10,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: accent10.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.security_rounded,
                    size: 64,
                    color: accent10,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  "Confirm it's really you",
                  style: TextStyle(
                    fontFamily: 'Sora',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Use your device security credential to establish a secure local vault session.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: GlassmorphicButton(
                    baseColor: accent10,
                    onPressed: () {
                      appState.setPatientAuthState(PatientAuthState.unlockSetup);
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.fingerprint, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Sign in securely',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
