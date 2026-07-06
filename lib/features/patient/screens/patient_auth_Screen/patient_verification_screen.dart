import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/state/app_state.dart';
import '../../../../shared/widgets/neon_card.dart';

class PatientVerificationScreen extends StatefulWidget {
  final String identifier;
  const PatientVerificationScreen({super.key, required this.identifier});

  @override
  State<PatientVerificationScreen> createState() => _PatientVerificationScreenState();
}

class _PatientVerificationScreenState extends State<PatientVerificationScreen> {
  final _codeController = TextEditingController();

  void _verify() {
    if (_codeController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 6-digit code.')),
      );
      return;
    }

    final appState = Provider.of<AppState>(context, listen: false);

    // Success dialog and redirect back to Patient Login screen
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Verification Success', style: TextStyle(fontFamily: 'Sora')),
        content: const Text('Account verified successfully. You can now sign in using your credentials.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              appState.setPatientAuthState(PatientAuthState.login);
            },
            child: const Text('Proceed to Login'),
          ),
        ],
      ),
    );
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
        title: const Text('Account Verification', style: TextStyle(fontFamily: 'Sora')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            appState.setPatientAuthState(PatientAuthState.signup);
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
                'Verify your contact.',
                style: TextStyle(
                  fontFamily: 'Sora',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'A 6-digit confirmation code was sent to: ${widget.identifier.isNotEmpty ? widget.identifier : 'your registered contact'}',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                style: const TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 24,
                  letterSpacing: 8,
                ),
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  counterText: '',
                  labelText: '6-Digit Verification Code',
                  prefixIcon: Icon(Icons.lock_open),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _verify,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent10,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Verify',
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
              Align(
                alignment: Alignment.center,
                child: TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Code resent (mock)')),
                    );
                  },
                  child: Text(
                    "Didn't get a code? Resend",
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: accent10,
                      fontWeight: FontWeight.bold,
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
