import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/state/app_state.dart';

// ── Design Tokens ─────────────────────────────────────────────────────────
const _kBg = Color(0xFF0A0F1D);
const _kCard = Color(0xFF1E293B);
const _kBorder = Color(0xFF334155);
const _kAccent = Color(0xFF0EA5E9);
const _kText = Color(0xFFFFFFFF);
const _kMuted = Color(0xFF94A3B8);
const _kError = Color(0xFFEF4444);

class PatientLoginScreen extends StatefulWidget {
  const PatientLoginScreen({super.key});

  @override
  State<PatientLoginScreen> createState() => _PatientLoginScreenState();
}

class _PatientLoginScreenState extends State<PatientLoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLoading = false;
  bool _obscure = true;
  String? _errorMsg;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _errorMsg = null;
    });
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;

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


  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);

    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          // Security mesh background
          Positioned.fill(child: CustomPaint(painter: _AuthMeshBg())),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back
                  IconButton(
                    onPressed: () => appState.setPatientAuthState(
                      PatientAuthState.authChoice,
                    ),
                    icon: const Icon(
                      CupertinoIcons.arrow_left,
                      color: _kMuted,
                      size: 22,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),

                  const SizedBox(height: 32),

                  // Shield badge
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: _kCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _kAccent.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _kAccent.withValues(alpha: 0.2),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: const Icon(
                      CupertinoIcons.lock_shield_fill,
                      color: _kAccent,
                      size: 26,
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    'Sign in to your\nHealth Vault',
                    style: GoogleFonts.sora(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: _kText,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Authenticate with your AegisRx credentials.',
                    style: GoogleFonts.inter(fontSize: 14, color: _kMuted),
                  ),

                  const SizedBox(height: 36),

                  // ── Email field ────────────────────────────────
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    style: GoogleFonts.inter(color: _kText, fontSize: 14),
                    decoration: _field(
                      label: 'Email address',
                      icon: CupertinoIcons.mail,
                      hint: 'you@example.com',
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ── Password field ─────────────────────────────
                  TextField(
                    controller: _passCtrl,
                    obscureText: _obscure,
                    style: GoogleFonts.inter(color: _kText, fontSize: 14),
                    decoration: _field(
                      label: 'Password',
                      icon: CupertinoIcons.lock,
                      suffix: IconButton(
                        icon: Icon(
                          _obscure
                              ? CupertinoIcons.eye
                              : CupertinoIcons.eye_slash,
                          color: _kMuted,
                          size: 18,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    onSubmitted: (_) => _login(),
                  ),

                  // ── Forgot password ────────────────────────────
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => _showForgotDialog(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 8,
                        ),
                      ),
                      child: Text(
                        'Forgot password?',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: _kAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  // ── Error banner ───────────────────────────────
                  if (_errorMsg != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: _kError.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _kError.withValues(alpha: 0.35),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            CupertinoIcons.exclamationmark_circle,
                            color: _kError,
                            size: 16,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMsg!,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: _kError,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ] else
                    const SizedBox(height: 20),

                  // ── Sign-in CTA ────────────────────────────────
                  _PrimaryBtn(
                    label: 'Sign in',
                    onPressed: _login,
                    isLoading: _isLoading,
                  ),

                  const SizedBox(height: 24),

                  // Divider
                  Row(
                    children: [
                      const Expanded(child: Divider(color: _kBorder)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'OR',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: _kMuted,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider(color: _kBorder)),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Create account
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () =>
                          appState.setPatientAuthState(PatientAuthState.signup),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: _kBorder, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Create new account',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _kText,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Back to role
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: () => appState.resetFlow(),
                          child: Text(
                            'Back to role selection',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: _kMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _field({
    required String label,
    required IconData icon,
    Widget? suffix,
    String? hint,
  }) => InputDecoration(
    labelText: label,
    hintText: hint,
    hintStyle: GoogleFonts.inter(color: _kMuted, fontSize: 14),
    labelStyle: GoogleFonts.inter(color: _kMuted, fontSize: 14),
    prefixIcon: Icon(icon, color: _kMuted, size: 20),
    suffixIcon: suffix,
    filled: true,
    fillColor: _kCard,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _kBorder, width: 1.5),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _kAccent, width: 1.5),
    ),
  );

  void _showForgotDialog(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (context) => Dialog(
        backgroundColor: _kCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _kBorder, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                CupertinoIcons.lock_rotation,
                color: _kAccent,
                size: 36,
              ),
              const SizedBox(height: 16),
              Text(
                'Password Recovery',
                style: GoogleFonts.sora(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _kText,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Self-sovereign password recovery will be available soon. Contact your vault administrator.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: _kMuted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              _PrimaryBtn(label: 'OK', onPressed: () => Navigator.pop(context)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared helpers ─────────────────────────────────────────────────────────

class _AuthMeshBg extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0EA5E9).withValues(alpha: 0.03)
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

class _PrimaryBtn extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const _PrimaryBtn({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _kAccent,
          disabledBackgroundColor: _kAccent.withValues(alpha: 0.4),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}
