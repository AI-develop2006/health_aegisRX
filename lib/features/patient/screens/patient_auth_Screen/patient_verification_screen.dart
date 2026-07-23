// ════════════════════════════════════════════════════════════════════════════
// AegisRx — Patient Verification Screen (OTP)
// Design System: AegisRx Clinical Precision
// Business logic: UNCHANGED — _verify(), _resend(), timer, OTP cell logic preserved
// ════════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/design_system.dart';

class PatientVerificationScreen extends StatefulWidget {
  final String identifier;
  const PatientVerificationScreen({super.key, required this.identifier});

  @override
  State<PatientVerificationScreen> createState() =>
      _PatientVerificationScreenState();
}

class _PatientVerificationScreenState
    extends State<PatientVerificationScreen> {
  static const int _otpLen = 6;
  final List<TextEditingController> _ctrl =
      List.generate(_otpLen, (_) => TextEditingController());
  final List<FocusNode> _focus =
      List.generate(_otpLen, (_) => FocusNode());

  int _countdown = 60;
  Timer? _timer;
  bool _canResend  = false;
  bool _isVerifying = false;
  bool _isVerified  = false;

  // ── BUSINESS LOGIC UNCHANGED ──────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) FocusScope.of(context).requestFocus(_focus[0]);
    });
  }

  void _startTimer() {
    _countdown = 60;
    _canResend = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      if (_countdown <= 1) {
        t.cancel();
        setState(() => _canResend = true);
      } else {
        setState(() => _countdown--);
      }
    });
  }

  @override
  void dispose() {
    for (final c in _ctrl) { c.dispose(); }
    for (final f in _focus) { f.dispose(); }
    _timer?.cancel();
    super.dispose();
  }

  String get _otpCode => _ctrl.map((c) => c.text).join();

  void _onDigitEntered(int index, String value) {
    if (value.isNotEmpty) {
      if (index < _otpLen - 1) {
        FocusScope.of(context).requestFocus(_focus[index + 1]);
      } else {
        _focus[index].unfocus();
        Future.delayed(const Duration(milliseconds: 100), _verify);
      }
    }
  }

  void _onKeyEvent(int index, RawKeyEvent event) {
    if (event is RawKeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _ctrl[index].text.isEmpty &&
        index > 0) {
      FocusScope.of(context).requestFocus(_focus[index - 1]);
      _ctrl[index - 1].clear();
    }
  }

  void _verify() {
    final code = _otpCode;
    if (code.length != _otpLen) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter all $_otpLen digits.'),
          backgroundColor: AegisColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() => _isVerifying = true);

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() { _isVerifying = false; _isVerified = true; });

      Future.delayed(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Dialog(
            backgroundColor: AegisColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: AegisRadius.card,
              side: const BorderSide(color: AegisColors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AegisSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AegisColors.successLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.verified_rounded,
                        color: AegisColors.success, size: 32),
                  ),
                  const SizedBox(height: AegisSpacing.base),
                  Text('Vault Activated!',
                      style: AegisTypography.headlineMedium.copyWith(
                          color: AegisColors.textPrimary)),
                  const SizedBox(height: AegisSpacing.sm),
                  Text(
                    'Your identity is verified. You can now sign in with your credentials.',
                    textAlign: TextAlign.center,
                    style: AegisTypography.bodyMedium.copyWith(
                        color: AegisColors.textSecondary, height: 1.5),
                  ),
                  const SizedBox(height: AegisSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    height: AegisTokens.btnHeight,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Provider.of<AppState>(context, listen: false)
                            .setPatientAuthState(PatientAuthState.login);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AegisColors.success,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: AegisRadius.button),
                        textStyle: AegisTypography.labelLarge,
                      ),
                      child: const Text('Proceed to Login'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      });
    });
  }

  void _resend() {
    if (!_canResend) return;
    _startTimer();
    for (final c in _ctrl) { c.clear(); }
    setState(() => _isVerified = false);
    FocusScope.of(context).requestFocus(_focus[0]);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Verification code resent.'),
        backgroundColor: AegisColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
  // ── END BUSINESS LOGIC ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final masked = widget.identifier.length > 4
        ? '${widget.identifier.substring(0, 3)}●●●${widget.identifier.substring(widget.identifier.length - 2)}'
        : widget.identifier.isNotEmpty
            ? widget.identifier
            : 'your registered contact';

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
                  _BackBtn(onTap: () => appState.setPatientAuthState(PatientAuthState.signup)),
                  const SizedBox(height: AegisSpacing.xl),

                  // ── Icon badge (animated) ──────────────────────
                  AnimatedContainer(
                    duration: AegisMotion.moderate,
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: _isVerified ? AegisColors.successLight : AegisColors.primarySurface,
                      borderRadius: BorderRadius.circular(AegisRadius.md),
                      border: Border.all(
                        color: (_isVerified ? AegisColors.success : AegisColors.primary)
                            .withValues(alpha: 0.4),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (_isVerified ? AegisColors.success : AegisColors.primary)
                              .withValues(alpha: 0.15),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      _isVerified
                          ? Icons.verified_rounded
                          : Icons.shield_outlined,
                      color: _isVerified ? AegisColors.success : AegisColors.primary,
                      size: AegisIconSize.lg,
                    ),
                  ),

                  const SizedBox(height: AegisSpacing.base),

                  Text(
                    'Verify your\nmobile number',
                    style: AegisTypography.displaySmall.copyWith(
                      color: AegisColors.textPrimary,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: AegisSpacing.sm),
                  RichText(
                    text: TextSpan(
                      style: AegisTypography.bodyMedium.copyWith(
                          color: AegisColors.textSecondary),
                      children: [
                        const TextSpan(text: 'A 6-digit code was sent to '),
                        TextSpan(
                          text: masked,
                          style: AegisTypography.bodyMedium.copyWith(
                            color: AegisColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AegisSpacing.xxl),

                  // ── OTP Grid ───────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(
                      _otpLen,
                      (i) => _OtpCell(
                        controller: _ctrl[i],
                        focusNode: _focus[i],
                        isVerified: _isVerified,
                        onChanged: (v) => _onDigitEntered(i, v),
                        onKey: (e) => _onKeyEvent(i, e),
                      ),
                    ),
                  ),

                  const SizedBox(height: AegisSpacing.lg),

                  // ── Timer / Resend ─────────────────────────────
                  Center(
                    child: _canResend
                        ? TextButton(
                            onPressed: _resend,
                            child: Text(
                              'Resend code',
                              style: AegisTypography.labelMedium.copyWith(
                                  color: AegisColors.primary),
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.timer_outlined,
                                  size: AegisIconSize.sm,
                                  color: AegisColors.textTertiary),
                              const SizedBox(width: AegisSpacing.xs),
                              Text(
                                'Resend in ${_countdown}s',
                                style: AegisTypography.bodySmall.copyWith(
                                    color: AegisColors.textTertiary),
                              ),
                            ],
                          ),
                  ),

                  const SizedBox(height: AegisSpacing.base),

                  // ── Verify CTA ─────────────────────────────────
                  AnimatedContainer(
                    duration: AegisMotion.moderate,
                    width: double.infinity,
                    height: AegisTokens.btnHeight,
                    child: ElevatedButton(
                      onPressed: _isVerifying || _isVerified ? null : _verify,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _isVerified ? AegisColors.success : AegisColors.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            (_isVerified ? AegisColors.success : AegisColors.primary)
                                .withValues(alpha: 0.4),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: AegisRadius.button),
                        textStyle: AegisTypography.labelLarge,
                      ),
                      child: _isVerifying
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5, color: Colors.white),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_isVerified)
                                  const Padding(
                                    padding: EdgeInsets.only(right: AegisSpacing.sm),
                                    child: Icon(Icons.check_rounded,
                                        size: AegisIconSize.sm, color: Colors.white),
                                  ),
                                Text(_isVerified ? 'Identity Confirmed' : 'Verify Code'),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: AegisSpacing.base),

                  // ── Security info note ─────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AegisSpacing.md,
                      vertical: AegisSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: AegisColors.surface,
                      borderRadius: AegisRadius.card,
                      border: Border.all(color: AegisColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            color: AegisColors.textTertiary, size: AegisIconSize.sm),
                        const SizedBox(width: AegisSpacing.sm),
                        Expanded(
                          child: Text(
                            'This code expires in 10 minutes. Never share it with anyone.',
                            style: AegisTypography.labelSmall.copyWith(
                              color: AegisColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
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
}

// ── OTP Cell ──────────────────────────────────────────────────────────────
class _OtpCell extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isVerified;
  final ValueChanged<String> onChanged;
  final Function(RawKeyEvent) onKey;

  const _OtpCell({
    required this.controller,
    required this.focusNode,
    required this.isVerified,
    required this.onChanged,
    required this.onKey,
  });

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: FocusNode(),
      onKey: onKey,
      child: SizedBox(
        width: 46,
        height: 58,
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 1,
          style: AegisTypography.monoLarge.copyWith(
            color: isVerified ? AegisColors.success : AegisColors.textPrimary,
          ),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: onChanged,
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: AegisColors.surface,
            contentPadding: EdgeInsets.zero,
            enabledBorder: OutlineInputBorder(
              borderRadius: AegisRadius.input,
              borderSide: BorderSide(
                color: isVerified ? AegisColors.success : AegisColors.border,
                width: AegisBorders.regular,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AegisRadius.input,
              borderSide: BorderSide(
                color: isVerified ? AegisColors.success : AegisColors.primary,
                width: AegisBorders.thick,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Shared helpers ─────────────────────────────────────────────────────────
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
