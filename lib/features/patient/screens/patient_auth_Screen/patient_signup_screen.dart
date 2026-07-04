import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/state/app_state.dart';
import '../../../../shared/widgets/neon_card.dart';

class PatientSignUpScreen extends StatefulWidget {
  const PatientSignUpScreen({super.key});

  @override
  State<PatientSignUpScreen> createState() => _PatientSignUpScreenState();
}

class _PatientSignUpScreenState extends State<PatientSignUpScreen> {
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _idNumberController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  DateTime? _dob;
  String? _gender = 'Female';
  String? _country = 'India';
  String? _idType = 'Aadhaar';
  String? _uploadedFileName;
  bool _agreeToPolicy = false;

  void _pickDocument() {
    setState(() {
      _uploadedFileName = 'id_proof_document_${_idType!.toLowerCase()}.pdf';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$_idType Document uploaded successfully (mock).')),
    );
  }

  void _signup() {
    final name = _nameController.text;
    final mobile = _mobileController.text;
    final idNumber = _idNumberController.text;
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (name.isEmpty || mobile.isEmpty || idNumber.isEmpty || password.isEmpty || confirm.isEmpty || _dob == null || _uploadedFileName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields (*) and upload your ID document.')),
      );
      return;
    }

    if (password != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match.')),
      );
      return;
    }

    if (!_agreeToPolicy) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must agree to the Terms and Privacy Policy.')),
      );
      return;
    }

    final appState = Provider.of<AppState>(context, listen: false);
    // Save contact number to show in verification screen
    appState.setTempVerificationContact(mobile);
    appState.setPatientAuthState(PatientAuthState.verification);
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _dob) {
      setState(() {
        _dob = picked;
      });
    }
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
        title: const Text('Patient Sign Up', style: TextStyle(fontFamily: 'Sora')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            appState.setPatientAuthState(PatientAuthState.authChoice);
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
                'Create your patient vault',
                style: TextStyle(
                  fontFamily: 'Sora',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Legal Name *',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date of Birth *',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _dob == null
                        ? 'Select Date'
                        : '${_dob!.day}/${_dob!.month}/${_dob!.year}',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: _dob == null
                          ? (isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8))
                          : (isLight ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _gender,
                decoration: const InputDecoration(
                  labelText: 'Gender *',
                  prefixIcon: Icon(Icons.people),
                ),
                items: ['Male', 'Female', 'Other', 'Prefer not to say']
                    .map((label) => DropdownMenuItem(
                          value: label,
                          child: Text(label),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _gender = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _country,
                decoration: const InputDecoration(
                  labelText: 'Region / Country *',
                  prefixIcon: Icon(Icons.public),
                ),
                items: ['India', 'USA', 'UK', 'Canada', 'Germany']
                    .map((label) => DropdownMenuItem(
                          value: label,
                          child: Text(label),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _country = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _mobileController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Primary Mobile Number (with country code) *',
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email address (Optional)',
                  prefixIcon: Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _idType,
                decoration: const InputDecoration(
                  labelText: 'Nationality / ID Type *',
                  prefixIcon: Icon(Icons.badge),
                ),
                items: ['Aadhaar', 'SSN', 'NHS', 'Passport', 'Other']
                    .map((label) => DropdownMenuItem(
                          value: label,
                          child: Text(label),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _idType = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _idNumberController,
                decoration: const InputDecoration(
                  labelText: 'ID Number *',
                  prefixIcon: Icon(Icons.credit_card),
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _pickDocument,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Upload ID Proof Document *',
                    prefixIcon: Icon(Icons.cloud_upload_rounded),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _uploadedFileName ?? 'Tap to upload ID document (PDF, PNG, JPG)',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            color: _uploadedFileName == null
                                ? (isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8))
                                : const Color(0xFF10B981),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_uploadedFileName != null)
                        const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 20)
                      else
                        Icon(
                          Icons.attach_file_rounded,
                          color: isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                          size: 20,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password *',
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password *',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Checkbox(
                    value: _agreeToPolicy,
                    onChanged: (val) {
                      setState(() {
                        _agreeToPolicy = val ?? false;
                      });
                    },
                  ),
                  Expanded(
                    child: Wrap(
                      children: [
                        const Text(
                          'I agree to the ',
                          style: TextStyle(fontFamily: 'Inter'),
                        ),
                        GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Terms of Use coming soon.')),
                            );
                          },
                          child: Text(
                            'Terms of Use',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              color: accent10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Text(' and ', style: TextStyle(fontFamily: 'Inter')),
                        GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Privacy Policy coming soon.')),
                            );
                          },
                          child: Text(
                            'Privacy Policy',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              color: accent10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _signup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent10,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Register',
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
                    appState.setPatientAuthState(PatientAuthState.login);
                  },
                  child: Text(
                    'Already have an account? Sign in',
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
