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
        const SnackBar(content: Text('Please enter your pharmacy license number.')),
      );
      return;
    }
    setState(() => _isLoading = true);
    final appState = Provider.of<AppState>(context, listen: false);
    final error = await appState.loginPharmacy(license);
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
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Access Dispensation Desk'),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: _showServerConfigDialog,
                  icon: const Icon(Icons.settings_ethernet_rounded, size: 16),
                  label: const Text('Server Connection Config', style: TextStyle(fontSize: 12)),
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
