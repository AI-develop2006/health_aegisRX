import 'package:flutter/foundation.dart';
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
  bool _isLoading = false;

  void _login() async {
    final license = _licenseController.text.trim();
    if (license.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your pharmacy license number.'),
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    final appState = Provider.of<AppState>(context, listen: false);
    final error = await appState.loginPharmacy(license);
    if (mounted) setState(() => _isLoading = false);
    if (error != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
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
                  Icons.medication,
                  size: 64,
                  color: Color(0xFF0F52BA),
                ),
                const SizedBox(height: 16),
                const Text(
                  'AegisRx Pharmacy Portal',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Select Registered Pharmacy',
                    prefixIcon: Icon(Icons.local_pharmacy_rounded),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'PHARM-AMOY-01',
                      child: Text(
                        'Aegis Pharmacy (Amoy-01)',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'PHARM-AMOY-02',
                      child: Text(
                        'Sovereign Care (Amoy-02)',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'PHARM-APOLLO-09',
                      child: Text(
                        'Apollo Pharma (Apollo-09)',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'PHARM-CV-HEALTH',
                      child: Text(
                        'CV Health Desk (CV-Health)',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'PHARM-RX-SECURE',
                      child: Text(
                        'SafeRx Dispensary (Rx-Secure)',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      _licenseController.text = val;
                    }
                  },
                ),
                const SizedBox(height: 24),
                GlassmorphicButton(
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Access Dispensation Desk'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    Provider.of<AppState>(context, listen: false).resetFlow();
                  },
                  child: const Text(
                    'Back to role selection',
                    style: TextStyle(fontFamily: 'Inter'),
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
