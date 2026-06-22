import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:health_lock/core/constants/app_colors.dart';
import 'package:health_lock/core/theme/app_theme.dart';
import 'package:health_lock/shared/widgets/custom_button.dart';
import 'package:health_lock/main.dart'; // To access SimulationState

class PatientLogin extends StatefulWidget {
  const PatientLogin({super.key});

  @override
  State<PatientLogin> createState() => _PatientLoginState();
}

class _PatientLoginState extends State<PatientLogin> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isRegisterMode = false;
  bool _isLoading = false;
  String? _errorMessage;
  final _nameController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth(SimulationState state) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    String? error;

    if (_isRegisterMode) {
      error = await state.signUpWithEmail(email, password, name: _nameController.text.trim());
    } else {
      error = await state.loginWithEmail(email, password);
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
        _errorMessage = error;
      });
    }
  }

  InputDecoration _inputDecoration(String hint, {Widget? suffixIcon}) {
    return InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: InputBorder.none,
      isDense: true,
      hintText: hint,
      hintStyle: const TextStyle(
        color: AppColors.textFaint,
        fontSize: 13,
      ),
      suffixIcon: suffixIcon,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<SimulationState>(context);

    return Scaffold(
      backgroundColor: AppColors.baseCanvas,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Brand / Logo
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.tintBlue,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.patientBlue.withValues(alpha: 0.2),
                        ),
                      ),
                      child: const Icon(
                        Icons.local_hospital_rounded,
                        color: AppColors.patientBlue,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'HealthLock',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryText,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.tintEmerald,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.verifiedEmerald.withValues(alpha: 0.2),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shield_rounded, size: 12, color: AppColors.verifiedEmerald),
                      SizedBox(width: 4),
                      Text(
                        'Blockchain Secured',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.verifiedEmerald,
                          letterSpacing: 0.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Login Card
                GlassCard(
                  borderRadius: 20,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isRegisterMode ? 'CREATE ACCOUNT' : 'SIGN IN',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: AppColors.primaryText,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Enter your credentials to access your prescription wallet.',
                          style: TextStyle(fontSize: 12, color: AppColors.mutedText),
                        ),
                        const SizedBox(height: 20),

                        // Error display banner
                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.statusCritical.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.statusCritical.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: AppColors.statusCritical, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(fontSize: 11, color: AppColors.statusCritical),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Name field (register only)
                        if (_isRegisterMode) ...[
                          const Text('Full Name', style: TextStyle(fontSize: 11, color: AppColors.mutedText, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                          const SizedBox(height: 6),
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.surfaceMuted,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.borderWhite),
                            ),
                            child: TextFormField(
                              controller: _nameController,
                              style: const TextStyle(fontSize: 13, color: AppColors.primaryText),
                              validator: (value) {
                                if (_isRegisterMode && (value == null || value.trim().isEmpty)) return 'Enter your name';
                                return null;
                              },
                              decoration: _inputDecoration('Jane Doe'),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Email input field
                        const Text('Email Address', style: TextStyle(fontSize: 11, color: AppColors.mutedText, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                        const SizedBox(height: 6),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.borderWhite),
                          ),
                          child: TextFormField(
                            controller: _emailController,
                            style: const TextStyle(fontSize: 13, color: AppColors.primaryText),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) return 'Enter your email address';
                              if (!value.contains('@')) return 'Enter a valid email';
                              return null;
                            },
                            decoration: _inputDecoration('you@example.com'),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Password input field
                        const Text('Password', style: TextStyle(fontSize: 11, color: AppColors.mutedText, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                        const SizedBox(height: 6),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.borderWhite),
                          ),
                          child: TextFormField(
                            controller: _passwordController,
                            style: const TextStyle(fontSize: 13, color: AppColors.primaryText),
                            obscureText: _obscurePassword,
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Enter your password';
                              if (value.length < 6) return 'Password must be at least 6 characters';
                              return null;
                            },
                            decoration: _inputDecoration(
                              '••••••••',
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                  color: AppColors.textFaint,
                                  size: 18,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Submit Button
                        _isLoading
                            ? const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(AppColors.patientBlue)),
                                ),
                              )
                            : Column(
                                children: [
                                  CustomButton(
                                    text: _isRegisterMode ? 'CREATE ACCOUNT' : 'SIGN IN',
                                    icon: _isRegisterMode ? Icons.person_add_rounded : Icons.login_rounded,
                                    backgroundColor: AppColors.patientBlue,
                                    borderColor: Colors.transparent,
                                    textColor: Colors.white,
                                    onPressed: () => _handleAuth(state),
                                  ),
                                ],
                              ),
                        const SizedBox(height: 16),

                        // Switch mode link
                        Center(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _isRegisterMode = !_isRegisterMode;
                                _errorMessage = null;
                              });
                            },
                            child: Text(
                              _isRegisterMode ? 'Already have an account? Sign In' : 'Don\'t have an account? Register Now',
                              style: const TextStyle(fontSize: 12, color: AppColors.patientBlue, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Guest / Demo access button
                const Text(
                  'OR TRY DEMO MODE',
                  style: TextStyle(fontSize: 10, color: AppColors.mutedText, letterSpacing: 0.8, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                CustomButton(
                  text: 'CONTINUE AS GUEST',
                  icon: Icons.double_arrow_rounded,
                  backgroundColor: AppColors.cardSurface,
                  borderColor: AppColors.borderWhite,
                  textColor: AppColors.mutedText,
                  onPressed: () {
                    state.loginOfflineGuest();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
