// ════════════════════════════════════════════════════════════════════════════
// AegisRx — Patient Sign Up Screen
// Design System: AegisRx Clinical Precision
// Business logic: UNCHANGED — signUpWithEmail(), _pickDocument(), _selectDate()
//                              _signup() validation chain all preserved exactly
// ════════════════════════════════════════════════════════════════════════════

import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/design_system.dart';

class PatientSignUpScreen extends StatefulWidget {
  const PatientSignUpScreen({super.key});

  @override
  State<PatientSignUpScreen> createState() => _PatientSignUpScreenState();
}

class _PatientSignUpScreenState extends State<PatientSignUpScreen> {
  final _nameController          = TextEditingController();
  final _mobileController        = TextEditingController();
  final _emailController         = TextEditingController();
  final _idNumberController      = TextEditingController();
  final _passwordController      = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  DateTime? _dob;
  String? _gender  = 'Female';
  String? _country = 'India';
  String? _idType  = 'Aadhaar';
  String? _uploadedFileName;
  bool _agreeToPolicy   = false;
  bool _isUploadingDoc  = false;
  bool _isLoading       = false;
  bool _obscurePass     = true;
  bool _obscureConfirm  = true;

  // ── BUSINESS LOGIC UNCHANGED ──────────────────────────────────────────────
  void _pickDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
      );
      if (result == null || result.files.single.path == null) return;

      if (!mounted || !context.mounted) return;
      setState(() => _isUploadingDoc = true);
      final File localFile = File(result.files.single.path!);
      final appState = Provider.of<AppState>(context, listen: false);
      final remoteName = await appState.uploadPatientIdDocument(localFile);
      if (!mounted || !context.mounted) return;
      setState(() {
        _isUploadingDoc = false;
        if (remoteName != null) {
          _uploadedFileName = remoteName;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ID Document uploaded successfully!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to upload document to secure server.')),
          );
        }
      });
    } catch (e) {
      if (!mounted || !context.mounted) return;
      setState(() => _isUploadingDoc = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking/uploading file: $e')),
      );
    }
  }

  void _signup() async {
    final name    = _nameController.text.trim();
    final mobile  = _mobileController.text.trim();
    final email   = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm  = _confirmPasswordController.text;

    if (name.isEmpty || mobile.isEmpty || email.isEmpty || password.isEmpty ||
        confirm.isEmpty || _dob == null || _uploadedFileName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields (*) and upload your ID document.')),
      );
      return;
    }

    final emailRegExp = RegExp(r"^[a-zA-Z0-9._%+-]+@gmail\.com$");
    if (!emailRegExp.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid Gmail address (ending with @gmail.com).')),
      );
      return;
    }

    final passwordRegExp =
        RegExp(r"^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$");
    if (!passwordRegExp.hasMatch(password)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must be at least 8 chars with uppercase, lowercase, numbers, and special characters.'),
        ),
      );
      return;
    }

    if (_idType == 'Aadhaar') {
      final sanitizedAadhaar = _idNumberController.text.trim().replaceAll(RegExp(r'\s+'), '');
      if (!RegExp(r'^\d{12}$').hasMatch(sanitizedAadhaar)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aadhaar number must be exactly 12 numeric digits.')),
        );
        return;
      }
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

    setState(() => _isLoading = true);
    final appState = Provider.of<AppState>(context, listen: false);
    final error = await appState.signUpWithEmail(
      email, password,
      name: name,
      mobile: mobile,
      dob: _dob != null ? _dob!.toIso8601String().split('T').first : '',
      gender: _gender ?? '',
      country: _country ?? '',
      idType: _idType ?? '',
      idNumber: _idNumberController.text.trim(),
      uploadedFileName: _uploadedFileName ?? '',
    );

    if (mounted) setState(() => _isLoading = false);
    if (error == null) {
      appState.setTempVerificationContact(mobile);
      appState.setPatientAuthState(PatientAuthState.verification);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _dob) setState(() => _dob = picked);
  }
  // ── END BUSINESS LOGIC ────────────────────────────────────────────────────

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _idNumberController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);

    return Scaffold(
      backgroundColor: AegisColors.background,
      appBar: AppBar(
        backgroundColor: AegisColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: AegisIconSize.sm, color: AegisColors.textSecondary),
          onPressed: () => appState.setPatientAuthState(PatientAuthState.authChoice),
        ),
        title: Text('Create Account',
            style: AegisTypography.headlineMedium.copyWith(color: AegisColors.textPrimary)),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AegisColors.border),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AegisSpacing.pagePadding,
          vertical: AegisSpacing.base,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Section header ─────────────────────────────────
            _SectionCard(
              title: 'Personal Information',
              icon: Icons.person_outline_rounded,
              iconColor: AegisColors.primary,
              iconBg: AegisColors.primarySurface,
              children: [
                _SignupField(
                  controller: _nameController,
                  label: 'Full Legal Name *',
                  icon: Icons.person_outline_rounded,
                ),
                const SizedBox(height: AegisSpacing.md),

                // DOB picker
                InkWell(
                  onTap: () => _selectDate(context),
                  borderRadius: AegisRadius.input,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AegisSpacing.inputPaddingH,
                      vertical: AegisSpacing.inputPaddingV,
                    ),
                    decoration: BoxDecoration(
                      color: AegisColors.surface,
                      borderRadius: AegisRadius.input,
                      border: Border.all(color: AegisColors.border, width: AegisBorders.regular),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined,
                            color: AegisColors.textTertiary, size: AegisIconSize.md),
                        const SizedBox(width: AegisSpacing.md),
                        Expanded(
                          child: Text(
                            _dob == null
                                ? 'Date of Birth *'
                                : '${_dob!.day}/${_dob!.month}/${_dob!.year}',
                            style: AegisTypography.bodyMedium.copyWith(
                              color: _dob == null
                                  ? AegisColors.textTertiary
                                  : AegisColors.textPrimary,
                            ),
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded,
                            color: AegisColors.textTertiary, size: AegisIconSize.md),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AegisSpacing.md),

                _SignupDropdown<String>(
                  value: _gender,
                  label: 'Gender *',
                  icon: Icons.people_outline_rounded,
                  items: ['Male', 'Female', 'Other', 'Prefer not to say'],
                  onChanged: (v) => setState(() => _gender = v),
                ),
                const SizedBox(height: AegisSpacing.md),

                _SignupDropdown<String>(
                  value: _country,
                  label: 'Region / Country *',
                  icon: Icons.public_outlined,
                  items: ['India', 'USA', 'UK', 'Canada', 'Germany'],
                  onChanged: (v) => setState(() => _country = v),
                ),
              ],
            ),

            const SizedBox(height: AegisSpacing.base),

            // ── Contact section ───────────────────────────────
            _SectionCard(
              title: 'Contact Details',
              icon: Icons.phone_outlined,
              iconColor: AegisColors.secondary,
              iconBg: AegisColors.secondarySurface,
              children: [
                _SignupField(
                  controller: _mobileController,
                  label: 'Mobile Number (with country code) *',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: AegisSpacing.md),
                _SignupField(
                  controller: _emailController,
                  label: 'Gmail Address *',
                  hint: 'you@gmail.com',
                  icon: Icons.mail_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                ),
              ],
            ),

            const SizedBox(height: AegisSpacing.base),

            // ── Identity section ──────────────────────────────
            _SectionCard(
              title: 'Identity Verification',
              icon: Icons.badge_outlined,
              iconColor: AegisColors.tertiary,
              iconBg: AegisColors.tertiarySurface,
              children: [
                _SignupDropdown<String>(
                  value: _idType,
                  label: 'ID Type *',
                  icon: Icons.badge_outlined,
                  items: ['Aadhaar', 'SSN', 'NHS', 'Passport', 'Other'],
                  onChanged: (v) => setState(() => _idType = v),
                ),
                const SizedBox(height: AegisSpacing.md),
                _SignupField(
                  controller: _idNumberController,
                  label: 'ID Number *',
                  icon: Icons.credit_card_outlined,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: AegisSpacing.md),

                // Document upload tile
                InkWell(
                  onTap: _isUploadingDoc ? null : _pickDocument,
                  borderRadius: AegisRadius.input,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AegisSpacing.inputPaddingH,
                      vertical: AegisSpacing.inputPaddingV,
                    ),
                    decoration: BoxDecoration(
                      color: AegisColors.surface,
                      borderRadius: AegisRadius.input,
                      border: Border.all(
                        color: _uploadedFileName != null
                            ? AegisColors.success.withValues(alpha: 0.5)
                            : AegisColors.border,
                        width: AegisBorders.regular,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _uploadedFileName != null
                              ? Icons.check_circle_outline_rounded
                              : Icons.cloud_upload_outlined,
                          color: _uploadedFileName != null
                              ? AegisColors.success
                              : AegisColors.textTertiary,
                          size: AegisIconSize.md,
                        ),
                        const SizedBox(width: AegisSpacing.md),
                        Expanded(
                          child: Text(
                            _isUploadingDoc
                                ? 'Uploading to secure server...'
                                : (_uploadedFileName ??
                                    'Upload ID Document * (PDF, PNG, JPG)'),
                            style: AegisTypography.bodyMedium.copyWith(
                              color: _uploadedFileName != null
                                  ? AegisColors.success
                                  : AegisColors.textTertiary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_isUploadingDoc)
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AegisColors.primary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AegisSpacing.base),

            // ── Security section ──────────────────────────────
            _SectionCard(
              title: 'Account Security',
              icon: Icons.lock_outline_rounded,
              iconColor: AegisColors.danger,
              iconBg: AegisColors.dangerLight,
              children: [
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePass,
                  style: AegisTypography.bodyMedium.copyWith(color: AegisColors.textPrimary),
                  decoration: _signupFieldDecoration(
                    label: 'Password *',
                    icon: Icons.lock_outline_rounded,
                    suffix: IconButton(
                      icon: Icon(
                        _obscurePass
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AegisColors.textTertiary,
                        size: AegisIconSize.md,
                      ),
                      onPressed: () => setState(() => _obscurePass = !_obscurePass),
                    ),
                  ),
                ),
                const SizedBox(height: AegisSpacing.xs),
                Text(
                  'Min. 8 chars · Upper & lowercase · Number · Special char',
                  style: AegisTypography.labelSmall.copyWith(color: AegisColors.textTertiary),
                ),
                const SizedBox(height: AegisSpacing.md),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirm,
                  style: AegisTypography.bodyMedium.copyWith(color: AegisColors.textPrimary),
                  decoration: _signupFieldDecoration(
                    label: 'Confirm Password *',
                    icon: Icons.lock_rounded,
                    suffix: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AegisColors.textTertiary,
                        size: AegisIconSize.md,
                      ),
                      onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AegisSpacing.base),

            // ── Policy consent ────────────────────────────────
            Container(
              padding: const EdgeInsets.all(AegisSpacing.md),
              decoration: BoxDecoration(
                color: AegisColors.surface,
                borderRadius: AegisRadius.card,
                border: Border.all(color: AegisColors.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _agreeToPolicy,
                    activeColor: AegisColors.primary,
                    onChanged: (val) => setState(() => _agreeToPolicy = val ?? false),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(width: AegisSpacing.sm),
                  Expanded(
                    child: Wrap(
                      children: [
                        Text('I agree to the ',
                            style: AegisTypography.bodySmall.copyWith(
                                color: AegisColors.textSecondary)),
                        GestureDetector(
                          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Terms of Use coming soon.')),
                          ),
                          child: Text('Terms of Use',
                              style: AegisTypography.bodySmall.copyWith(
                                  color: AegisColors.primary,
                                  fontWeight: FontWeight.bold)),
                        ),
                        Text(' and ',
                            style: AegisTypography.bodySmall.copyWith(
                                color: AegisColors.textSecondary)),
                        GestureDetector(
                          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Privacy Policy coming soon.')),
                          ),
                          child: Text('Privacy Policy',
                              style: AegisTypography.bodySmall.copyWith(
                                  color: AegisColors.primary,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AegisSpacing.lg),

            // ── CTA ───────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: AegisTokens.btnHeight,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _signup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AegisColors.primary,
                  foregroundColor: AegisColors.onPrimary,
                  disabledBackgroundColor: AegisColors.primarySurface,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: AegisRadius.button),
                  textStyle: AegisTypography.labelLarge,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shield_rounded, size: AegisIconSize.sm),
                          SizedBox(width: AegisSpacing.sm),
                          Text('Create Secure Vault'),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: AegisSpacing.md),

            Center(
              child: TextButton(
                onPressed: () => appState.setPatientAuthState(PatientAuthState.login),
                child: Text(
                  'Already have an account? Sign in →',
                  style: AegisTypography.bodySmall.copyWith(color: AegisColors.primary),
                ),
              ),
            ),

            const SizedBox(height: AegisSpacing.safeBottom),
          ],
        ),
      ),
    );
  }

  InputDecoration _signupFieldDecoration({
    required String label,
    required IconData icon,
    Widget? suffix,
  }) =>
      InputDecoration(
        labelText: label,
        labelStyle:
            AegisTypography.bodyMedium.copyWith(color: AegisColors.textSecondary),
        prefixIcon: Icon(icon, color: AegisColors.textTertiary, size: AegisIconSize.md),
        suffixIcon: suffix,
        filled: true,
        fillColor: AegisColors.surface,
        counterText: '',
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AegisSpacing.inputPaddingH,
          vertical: AegisSpacing.inputPaddingV,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AegisRadius.input,
          borderSide: const BorderSide(color: AegisColors.border, width: AegisBorders.regular),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AegisRadius.input,
          borderSide: const BorderSide(color: AegisColors.primary, width: AegisBorders.regular),
        ),
      );
}

// ── Reusable signup form components ──────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AegisSpacing.base),
      decoration: BoxDecoration(
        color: AegisColors.surface,
        borderRadius: AegisRadius.card,
        border: Border.all(color: AegisColors.border),
        boxShadow: AegisShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(AegisRadius.sm)),
                child: Icon(icon, size: AegisIconSize.sm, color: iconColor),
              ),
              const SizedBox(width: AegisSpacing.sm),
              Text(title,
                  style: AegisTypography.titleSmall.copyWith(
                      color: AegisColors.textPrimary)),
            ],
          ),
          const SizedBox(height: AegisSpacing.base),
          const Divider(height: 1, color: AegisColors.border),
          const SizedBox(height: AegisSpacing.base),
          ...children,
        ],
      ),
    );
  }
}

class _SignupField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData icon;
  final TextInputType? keyboardType;

  const _SignupField({
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: AegisTypography.bodyMedium.copyWith(color: AegisColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: AegisTypography.bodyMedium.copyWith(color: AegisColors.textTertiary),
        labelStyle: AegisTypography.bodyMedium.copyWith(color: AegisColors.textSecondary),
        prefixIcon: Icon(icon, color: AegisColors.textTertiary, size: AegisIconSize.md),
        filled: true,
        fillColor: AegisColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AegisSpacing.inputPaddingH,
          vertical: AegisSpacing.inputPaddingV,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AegisRadius.input,
          borderSide: const BorderSide(color: AegisColors.border, width: AegisBorders.regular),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AegisRadius.input,
          borderSide: const BorderSide(color: AegisColors.primary, width: AegisBorders.regular),
        ),
      ),
    );
  }
}

class _SignupDropdown<T> extends StatelessWidget {
  final T? value;
  final String label;
  final IconData icon;
  final List<String> items;
  final ValueChanged<T?> onChanged;

  const _SignupDropdown({
    required this.value,
    required this.label,
    required this.icon,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      style: AegisTypography.bodyMedium.copyWith(color: AegisColors.textPrimary),
      dropdownColor: AegisColors.surface,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AegisTypography.bodyMedium.copyWith(color: AegisColors.textSecondary),
        prefixIcon: Icon(icon, color: AegisColors.textTertiary, size: AegisIconSize.md),
        filled: true,
        fillColor: AegisColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AegisSpacing.inputPaddingH,
          vertical: AegisSpacing.inputPaddingV,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AegisRadius.input,
          borderSide: const BorderSide(color: AegisColors.border, width: AegisBorders.regular),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AegisRadius.input,
          borderSide: const BorderSide(color: AegisColors.primary, width: AegisBorders.regular),
        ),
      ),
      items: items
          .map((s) => DropdownMenuItem<T>(value: s as T, child: Text(s)))
          .toList(),
      onChanged: onChanged,
    );
  }
}
