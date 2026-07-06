import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/state/app_state.dart';
import '../../../../shared/widgets/neon_card.dart';

class PatientUnlockScreen extends StatefulWidget {
  const PatientUnlockScreen({super.key});

  @override
  State<PatientUnlockScreen> createState() => _PatientUnlockScreenState();
}

class _PatientUnlockScreenState extends State<PatientUnlockScreen> {
  final _pinController = TextEditingController();

  void _unlock() {
    final pin = _pinController.text;
    if (pin.isEmpty) return;

    final appState = Provider.of<AppState>(context, listen: false);
    final success = appState.unlockDevice(pin);

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid passcode. Try "1234" or the custom PIN you set.')),
      );
      _pinController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    // 60-30-10 Color Tokens
    final bg60 = isLight ? const Color(0xFFF5F6FA) : const Color(0xFF0B0F19);
    final accent10 = isLight ? const Color(0xFF4F46E5) : const Color(0xFF818CF8);

    return Scaffold(
      backgroundColor: bg60,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: NeonCard(
            neonColor: accent10,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock,
                  size: 64,
                  color: accent10,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Unlock Device Vault',
                  style: TextStyle(
                    fontFamily: 'Sora',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Secure session present. Enter your PIN to decrypt local medical keys.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 24,
                    letterSpacing: 12,
                  ),
                  decoration: const InputDecoration(
                    counterText: '',
                    labelText: 'Enter Passcode (default is 1234)',
                    prefixIcon: Icon(Icons.password),
                  ),
                  onSubmitted: (_) => _unlock(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _unlock,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent10,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Unlock Vault',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    // Logs out completely
                    Provider.of<AppState>(context, listen: false).resetFlow();
                  },
                  child: Text(
                    'Cancel & Switch Role',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: accent10,
                      fontWeight: FontWeight.w600,
                    ),
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
