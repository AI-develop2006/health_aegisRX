import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/state/app_state.dart';
import '../../../shared/widgets/neon_card.dart';

class DoctorOnboardingScreen extends StatefulWidget {
  const DoctorOnboardingScreen({super.key});

  @override
  State<DoctorOnboardingScreen> createState() => _DoctorOnboardingScreenState();
}

class _DoctorOnboardingScreenState extends State<DoctorOnboardingScreen> {
  final _nameController = TextEditingController();
  final _licenseController = TextEditingController();
  final _hospitalController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  void _submit() {
    if (_nameController.text.isEmpty ||
        _licenseController.text.isEmpty ||
        _hospitalController.text.isEmpty ||
        _specialtyController.text.isEmpty ||
        _emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all required fields.')),
      );
      return;
    }

    final appState = Provider.of<AppState>(context, listen: false);
    appState.requestDoctorVerification(
      name: _nameController.text,
      license: _licenseController.text,
      hospital: _hospitalController.text,
      specialty: _specialtyController.text,
      approved: false,
    );

    // Auto logs them in and transitions
    appState.setSession(
      role: UserRole.doctor,
      token: 'mock-jwt-token-doctor-${_licenseController.text}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Registration', style: TextStyle(fontFamily: 'Sora')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Provider.of<AppState>(context, listen: false).resetFlow();
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: NeonCard(
          neonColor: const Color(0xFF0D9488), // Clinical Teal
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Request a doctor account.',
                style: TextStyle(
                  fontFamily: 'Sora',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter medical license details for secure verification.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name *',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _licenseController,
                decoration: const InputDecoration(
                  labelText: 'Medical License Number / NPI *',
                  prefixIcon: Icon(Icons.badge),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _hospitalController,
                decoration: const InputDecoration(
                  labelText: 'Hospital / Clinic Name *',
                  prefixIcon: Icon(Icons.local_hospital),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _specialtyController,
                decoration: const InputDecoration(
                  labelText: 'Specialty *',
                  prefixIcon: Icon(Icons.star),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Official Email Address *',
                  prefixIcon: Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Official Phone Number',
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D9488),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Submit Verification Request',
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
