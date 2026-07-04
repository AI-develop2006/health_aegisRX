import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/state/app_state.dart';
import '../../../shared/widgets/neon_card.dart';

class PharmacyTerminalAuthScreen extends StatefulWidget {
  const PharmacyTerminalAuthScreen({super.key});

  @override
  State<PharmacyTerminalAuthScreen> createState() => _PharmacyTerminalAuthScreenState();
}

class _PharmacyTerminalAuthScreenState extends State<PharmacyTerminalAuthScreen> {
  bool _keyConnected = false;

  void _verify() {
    if (!_keyConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please connect your hardware YubiKey device before verifying.')),
      );
      return;
    }

    final appState = Provider.of<AppState>(context, listen: false);
    appState.verifyPharmacyTerminal();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Terminal Authentication', style: TextStyle(fontFamily: 'Sora')),
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
            neonColor: appState.isTerminalVerified ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  appState.isTerminalVerified ? Icons.computer : Icons.no_encryption_gmailerrorred,
                  size: 80,
                  color: appState.isTerminalVerified ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                ),
                const SizedBox(height: 24),
                Text(
                  appState.isTerminalVerified ? 'Terminal Authenticated' : 'Untrusted Terminal Access',
                  style: const TextStyle(
                    fontFamily: 'Sora',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  appState.isTerminalVerified
                      ? 'Secure workstation environment confirmed. Token-redemption API gateway endpoints are now enabled.'
                      : 'Hardware security validation failed. Workstation certificate is untrusted. Token APIs and scanning are disabled.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Workstation ID:',
                      style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'STATION-PH-7729',
                      style: TextStyle(
                        fontFamily: 'JetBrains Mono',
                        color: isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Hardware YubiKey:',
                      style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _keyConnected ? 'Key Detected' : 'Not Connected',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.bold,
                        color: _keyConnected ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (!appState.isTerminalVerified) ...[
                  Row(
                    children: [
                      Checkbox(
                        value: _keyConnected,
                        onChanged: (val) {
                          setState(() {
                            _keyConnected = val ?? false;
                          });
                        },
                      ),
                      const Expanded(
                        child: Text(
                          'Simulate hardware key connection',
                          style: TextStyle(fontFamily: 'Inter'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _verify,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Verify Terminal',
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
