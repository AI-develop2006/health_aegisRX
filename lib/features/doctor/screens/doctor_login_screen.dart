import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/state/app_state.dart';
import '../doctor_theme.dart';
import 'doctor_onboarding_screen.dart';

class DoctorLoginScreen extends StatefulWidget {
  const DoctorLoginScreen({super.key});

  @override
  State<DoctorLoginScreen> createState() => _DoctorLoginScreenState();
}

class _DoctorLoginScreenState extends State<DoctorLoginScreen> {
  final _npiController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _npiController.dispose();
    super.dispose();
  }

  void _login() async {
    final npi = _npiController.text.trim();
    if (npi.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your National Provider Identifier (NPI)')),
      );
      return;
    }
    setState(() => _isLoading = true);
    final appState = Provider.of<AppState>(context, listen: false);
    final error = await appState.loginDoctor(npi);
    if (mounted) setState(() => _isLoading = false);
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  void _showServerConfigDialog() {
    final appState = Provider.of<AppState>(context, listen: false);
    final urlController = TextEditingController(text: appState.backendUrl);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Server Connection Config'),
        content: TextField(
          controller: urlController,
          decoration: const InputDecoration(
            labelText: 'Backend URL Gateway',
            hintText: 'e.g. http://10.0.2.2:4000',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              appState.setBackendUrl(urlController.text.trim());
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Server gateway set to: ${urlController.text.trim()}')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClinicalScaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ── Logo block ─────────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Dr.green.withOpacity(0.08),
                  shape: BoxShape.circle,
                  border: Border.all(color: Dr.green.withOpacity(0.3), width: 1.5),
                ),
                child: const Icon(
                  Icons.local_hospital_rounded,
                  size: 48,
                  color: Dr.green,
                ),
              ),
              const SizedBox(height: 20),
              Text('AegisRx', style: Dr.heading(28)),
              const SizedBox(height: 4),
              Text('Practitioner Portal', style: Dr.meta(14)),
              const SizedBox(height: 32),

              // ── Login card ─────────────────────────────────
              DoctorCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.badge_outlined, size: 16, color: Dr.sub),
                        const SizedBox(width: 8),
                        Text('Clinician Authentication', style: Dr.meta(12)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _npiController,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 15,
                        color: Dr.text,
                      ),
                      decoration: InputDecoration(
                        labelText: 'National Provider Identifier (NPI)',
                        labelStyle: Dr.meta(13),
                        hintText: 'e.g. 1234567890',
                        hintStyle: Dr.meta(13),
                        prefixIcon: const Icon(Icons.badge_rounded, color: Dr.sub, size: 20),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Dr.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Dr.green, width: 1.5),
                        ),
                        filled: true,
                        fillColor: Dr.bg,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 20),
                    DoctorPrimaryButton(
                      label: 'Access Clinician Suite',
                      icon: Icons.login_rounded,
                      onPressed: _login,
                      isLoading: _isLoading,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Secondary actions ──────────────────────────
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DoctorOnboardingScreen(),
                  ),
                ),
                child: Text(
                  'Request a doctor account →',
                  style: GoogleFonts.inter(
                    color: Dr.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _showServerConfigDialog,
                icon: const Icon(Icons.settings_ethernet_rounded, size: 16, color: Dr.green),
                label: Text('Server Connection Config', style: GoogleFonts.inter(color: Dr.green, fontSize: 13)),
              ),
              TextButton(
                onPressed: () =>
                    Provider.of<AppState>(context, listen: false).resetFlow(),
                child: Text(
                  'Back to role selection',
                  style: GoogleFonts.inter(color: Dr.sub, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
