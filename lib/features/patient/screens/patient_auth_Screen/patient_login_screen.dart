// ════════════════════════════════════════════════════════════════════════════
// AegisRx — Patient Login Screen
// Design System: AegisRx Clinical Precision
// Business logic: UNCHANGED — loginWithEmail(), setPatientAuthState() preserved
// ════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/design_system.dart';

class PatientLoginScreen extends StatefulWidget {
  const PatientLoginScreen({super.key});

  @override
  State<PatientLoginScreen> createState() => _PatientLoginScreenState();
}

class _PatientLoginScreenState extends State<PatientLoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _isLoading  = false;
  bool _obscure    = true;
  String? _errorMsg;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  // ── BUSINESS LOGIC UNCHANGED ──────────────────────────────────────────────
  Future<void> _login() async {
    setState(() => _errorMsg = null);
    final email = _emailCtrl.text.trim();
    final pass  = _passCtrl.text;

    if (email.isEmpty || pass.isEmpty) {
      setState(() => _errorMsg = 'Please enter your email and password.');
      return;
    }

    setState(() => _isLoading = true);
    final appState = Provider.of<AppState>(context, listen: false);
    final error = await appState.loginWithEmail(email, pass);
    if (mounted) setState(() => _isLoading = false);

    if (error == null) {
      appState.setPatientAuthState(PatientAuthState.secureSignIn);
    } else {
      if (mounted) setState(() => _errorMsg = error);
    }
  }
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);

    return Scaffold(
      backgroundColor: AegisColors.background,
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _AuthGridPainter())),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AegisSpacing.pagePadding,
                vertical: AegisSpacing.base,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Back
                  _BackBtn(onTap: () => appState.setPatientAuthState(PatientAuthState.authChoice)),
                  const SizedBox(height: AegisSpacing.xl),

                  // ── Shield badge ───────────────────────────────
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AegisColors.primarySurface,
                      borderRadius: BorderRadius.circular(AegisRadius.md),
                      border: Border.all(color: AegisColors.primary.withValues(alpha: 0.3)),
                      boxShadow: [
                        BoxShadow(
                          color: AegisColors.primary.withValues(alpha: 0.12),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.lock_person_rounded,
                      color: AegisColors.primary,
                      size: AegisIconSize.lg,
                    ),
                  ),

                  const SizedBox(height: AegisSpacing.base),

                  Text(
                    'Sign in to your\nHealth Vault',
                    style: AegisTypography.displaySmall.copyWith(
                      color: AegisColors.textPrimary,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: AegisSpacing.sm),
                  Text(
                    'Authenticate with your AegisRx credentials.',
                    style: AegisTypography.bodyMedium.copyWith(
                        color: AegisColors.textSecondary),
                  ),

                  const SizedBox(height: AegisSpacing.xl),

                  // ── Email ──────────────────────────────────────
                  _AuthField(
                    controller: _emailCtrl,
                    label: 'Email address',
                    hint: 'you@example.com',
                    icon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                    hasError: _errorMsg != null,
                  ),
                  const SizedBox(height: AegisSpacing.md),

                  // ── Password ───────────────────────────────────
                  _AuthField(
                    controller: _passCtrl,
                    label: 'Password',
                    icon: Icons.lock_outline_rounded,
                    obscureText: _obscure,
                    hasError: _errorMsg != null,
                    onSubmitted: (_) => _login(),
                    suffix: IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: AegisColors.textTertiary,
                        size: AegisIconSize.md,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),

                  // ── Forgot password ────────────────────────────
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => _showForgotDialog(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AegisSpacing.xs, vertical: AegisSpacing.sm),
                      ),
                      child: Text(
                        'Forgot password?',
                        style: AegisTypography.labelMedium.copyWith(
                          color: AegisColors.primary,
                        ),
                      ),
                    ),
                  ),

                  // ── Error banner ───────────────────────────────
                  AnimatedSize(
                    duration: AegisMotion.moderate,
                    curve: AegisMotion.decelerate,
                    child: _errorMsg != null
                        ? Padding(
                            padding: const EdgeInsets.only(bottom: AegisSpacing.md),
                            child: _ErrorBanner(message: _errorMsg!),
                          )
                        : const SizedBox(height: AegisSpacing.md),
                  ),

                  // ── Sign-in CTA ────────────────────────────────
                  _PrimaryAuthBtn(
                    label: 'Sign in',
                    onPressed: _login,
                    isLoading: _isLoading,
                  ),

                  const SizedBox(height: AegisSpacing.lg),

                  // Divider
                  Row(
                    children: [
                      const Expanded(child: Divider(color: AegisColors.border)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AegisSpacing.md),
                        child: Text('OR',
                            style: AegisTypography.labelSmall.copyWith(
                                color: AegisColors.textTertiary)),
                      ),
                      const Expanded(child: Divider(color: AegisColors.border)),
                    ],
                  ),

                  const SizedBox(height: AegisSpacing.base),

                  // ── Create account ─────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: AegisTokens.btnHeight,
                    child: OutlinedButton(
                      onPressed: () =>
                          appState.setPatientAuthState(PatientAuthState.signup),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: AegisColors.border, width: AegisBorders.regular),
                        shape: RoundedRectangleBorder(borderRadius: AegisRadius.button),
                        textStyle: AegisTypography.labelLarge,
                        foregroundColor: AegisColors.textPrimary,
                      ),
                      child: const Text('Create new account'),
                    ),
                  ),

                  const SizedBox(height: AegisSpacing.md),

                  Center(
                    child: TextButton(
                      onPressed: () => appState.resetFlow(),
                      child: Text(
                        'Back to role selection',
                        style: AegisTypography.bodySmall.copyWith(
                            color: AegisColors.textSecondary),
                      ),
                    ),
                  ),

                  const SizedBox(height: AegisSpacing.base),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showForgotDialog(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (context) => Dialog(
        backgroundColor: AegisColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AegisRadius.card,
          side: const BorderSide(color: AegisColors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AegisSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AegisColors.primarySurface,
                  borderRadius: BorderRadius.circular(AegisRadius.md),
                ),
                child: const Icon(Icons.lock_reset_rounded,
                    color: AegisColors.primary, size: AegisIconSize.lg),
              ),
              const SizedBox(height: AegisSpacing.base),
              Text('Password Recovery',
                  style: AegisTypography.headlineSmall.copyWith(
                      color: AegisColors.textPrimary)),
              const SizedBox(height: AegisSpacing.sm),
              Text(
                'Self-sovereign password recovery will be available soon. Contact your vault administrator.',
                textAlign: TextAlign.center,
                style: AegisTypography.bodyMedium.copyWith(
                    color: AegisColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: AegisSpacing.lg),
              _PrimaryAuthBtn(label: 'OK', onPressed: () => Navigator.pop(context)),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  Shared Auth Screen Components
// ════════════════════════════════════════════════════════════════════════════

class _AuthGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AegisColors.primary.withValues(alpha: 0.025)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    const step = 44.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BackBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _BackBtn({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AegisRadius.sm),
      child: Container(
        padding: const EdgeInsets.all(AegisSpacing.sm),
        decoration: BoxDecoration(
          color: AegisColors.surface,
          borderRadius: BorderRadius.circular(AegisRadius.sm),
          border: Border.all(color: AegisColors.border),
        ),
        child: const Icon(Icons.arrow_back_ios_new_rounded,
            size: AegisIconSize.sm, color: AegisColors.textSecondary),
      ),
    );
  }
}

class _AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData icon;
  final bool obscureText;
  final bool hasError;
  final TextInputType? keyboardType;
  final Widget? suffix;
  final ValueChanged<String>? onSubmitted;

  const _AuthField({
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.obscureText = false,
    this.hasError = false,
    this.keyboardType,
    this.suffix,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      onSubmitted: onSubmitted,
      style: AegisTypography.bodyMedium.copyWith(color: AegisColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: AegisTypography.bodyMedium.copyWith(color: AegisColors.textTertiary),
        labelStyle: AegisTypography.bodyMedium.copyWith(color: AegisColors.textSecondary),
        prefixIcon: Icon(icon, color: AegisColors.textTertiary, size: AegisIconSize.md),
        suffixIcon: suffix,
        filled: true,
        fillColor: AegisColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AegisSpacing.inputPaddingH,
          vertical: AegisSpacing.inputPaddingV,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AegisRadius.input,
          borderSide: BorderSide(
            color: hasError ? AegisColors.danger : AegisColors.border,
            width: AegisBorders.regular,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AegisRadius.input,
          borderSide: BorderSide(
            color: hasError ? AegisColors.danger : AegisColors.primary,
            width: AegisBorders.regular,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AegisRadius.input,
          borderSide: const BorderSide(color: AegisColors.danger, width: AegisBorders.regular),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AegisSpacing.md,
        vertical: AegisSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AegisColors.dangerLight,
        borderRadius: AegisRadius.input,
        border: Border.all(color: AegisColors.danger.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AegisColors.danger, size: AegisIconSize.md),
          const SizedBox(width: AegisSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AegisTypography.bodySmall.copyWith(
                  color: AegisColors.dangerDark, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryAuthBtn extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const _PrimaryAuthBtn({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AegisTokens.btnHeight,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AegisColors.primary,
          foregroundColor: AegisColors.onPrimary,
          disabledBackgroundColor: AegisColors.primarySurface,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: AegisRadius.button),
          textStyle: AegisTypography.labelLarge,
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white),
              )
            : Text(label),
      ),
    );
  }
}
