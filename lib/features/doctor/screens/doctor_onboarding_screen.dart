import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/state/app_state.dart';
import '../doctor_theme.dart';

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
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _licenseController.dispose();
    _hospitalController.dispose();
    _specialtyController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _submit() async {
    final name = _nameController.text.trim();
    final license = _licenseController.text.trim();
    final hospital = _hospitalController.text.trim();
    final specialty = _specialtyController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty || license.isEmpty || hospital.isEmpty ||
        specialty.isEmpty || email.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all required fields.')),
      );
      return;
    }
    setState(() => _isLoading = true);
    final appState = Provider.of<AppState>(context, listen: false);
    final error = await appState.registerDoctor(
      name: name,
      license: license,
      hospital: hospital,
      specialty: specialty,
      email: email,
      phone: phone,
    );
    if (mounted) setState(() => _isLoading = false);
    if (error == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Registration successful! NPI authorized.')),
        );
        Navigator.pop(context);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      }
    }
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool required = true,
    TextInputType keyboard = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          keyboardType: keyboard,
          style: GoogleFonts.inter(fontSize: 14, color: Dr.text),
          decoration: InputDecoration(
            labelText: required ? '$label *' : label,
            labelStyle: Dr.meta(13),
            prefixIcon: Icon(icon, color: Dr.sub, size: 20),
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
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        const SizedBox(height: 14),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClinicalScaffold(
      appBar: clinicalAppBar(title: 'Doctor Registration'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ─────────────────────────────────────────
            DoctorCard(
              borderColor: Dr.green.withOpacity(0.3),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Dr.green.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.how_to_reg_rounded,
                        color: Dr.green, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Request a Doctor Account',
                            style: Dr.heading(15)),
                        const SizedBox(height: 2),
                        Text(
                          'Enter your medical license details for secure NPI verification.',
                          style: Dr.meta(12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Form ────────────────────────────────────────────
            sectionHeader('Personal & Professional Details'),
            _field(
              controller: _nameController,
              label: 'Full Name',
              icon: Icons.person_outline_rounded,
            ),
            _field(
              controller: _licenseController,
              label: 'Medical License / NPI',
              icon: Icons.badge_outlined,
              keyboard: TextInputType.number,
            ),
            _field(
              controller: _hospitalController,
              label: 'Hospital / Clinic Name',
              icon: Icons.local_hospital_outlined,
            ),
            _field(
              controller: _specialtyController,
              label: 'Medical Specialty',
              icon: Icons.medical_services_outlined,
            ),

            sectionHeader('Contact Information'),
            _field(
              controller: _emailController,
              label: 'Official Email Address',
              icon: Icons.email_outlined,
              keyboard: TextInputType.emailAddress,
            ),
            _field(
              controller: _phoneController,
              label: 'Official Phone Number',
              icon: Icons.phone_outlined,
              required: false,
              keyboard: TextInputType.phone,
            ),

            // ── Submit ──────────────────────────────────────────
            DoctorPrimaryButton(
              label: 'Submit Verification Request',
              icon: Icons.send_rounded,
              isLoading: _isLoading,
              onPressed: _submit,
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Back to Login',
                    style:
                        GoogleFonts.inter(color: Dr.sub, fontSize: 13)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
