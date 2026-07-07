import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/state/app_state.dart';
import '../../../../shared/widgets/neon_card.dart';

class PatientUnlockSetupScreen extends StatefulWidget {
  const PatientUnlockSetupScreen({super.key});

  @override
  State<PatientUnlockSetupScreen> createState() => _PatientUnlockSetupScreenState();
}

class _PatientUnlockSetupScreenState extends State<PatientUnlockSetupScreen> {
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  bool _useBiometrics = false;

  void _savePin() {
    final pin = _pinController.text;
    final confirm = _confirmPinController.text;

    if (pin.length < 4 || pin.length > 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN must be between 4 and 6 digits.')),
      );
      return;
    }

    if (pin != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PINs do not match.')),
      );
      return;
    }

    final appState = Provider.of<AppState>(context, listen: false);
    
    final tokenToUse = appState.token ?? (appState.useMockFrontend ? 'mock-jwt-token-patient-alex' : '');
    appState.setSession(
      role: UserRole.patient,
      token: tokenToUse,
    );
    
    appState.setPin(pin);
  }

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
        title: const Text('Setup Security', style: TextStyle(fontFamily: 'Sora')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            appState.setPatientAuthState(PatientAuthState.secureSignIn);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: NeonCard(
          neonColor: accent10,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Secure this device',
                style: TextStyle(
                  fontFamily: 'Sora',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Create a PIN so you can quickly unlock AegisRx on this device.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _pinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                style: const TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 20,
                  letterSpacing: 8,
                ),
                decoration: const InputDecoration(
                  counterText: '',
                  labelText: 'Enter PIN (4-6 digits) *',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmPinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                style: const TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 20,
                  letterSpacing: 8,
                ),
                decoration: const InputDecoration(
                  counterText: '',
                  labelText: 'Confirm PIN *',
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 24),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Use Face ID / Fingerprint',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Enable biometric unlock for faster access.',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 12),
                ),
                value: _useBiometrics,
                onChanged: (val) {
                  setState(() {
                    _useBiometrics = val;
                  });
                },
                activeColor: accent10,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _savePin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent10,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Save and continue',
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
          ),
        ),
      ),
    );
  }
}
