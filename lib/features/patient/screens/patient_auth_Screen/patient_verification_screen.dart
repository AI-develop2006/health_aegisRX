import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/state/app_state.dart';

// ── Design Tokens ─────────────────────────────────────────────────────────
const _kBg      = Color(0xFF0A0F1D);
const _kCard    = Color(0xFF1E293B);
const _kBorder  = Color(0xFF334155);
const _kAccent  = Color(0xFF0EA5E9);
const _kSuccess = Color(0xFF10B981);
const _kText    = Color(0xFFFFFFFF);
const _kMuted   = Color(0xFF94A3B8);

// ══════════════════════════════════════════════════════════════════════════
//  PATIENT VERIFICATION SCREEN — 6-digit OTP layout
// ══════════════════════════════════════════════════════════════════════════

class PatientVerificationScreen extends StatefulWidget {
  final String identifier;
  const PatientVerificationScreen({super.key, required this.identifier});

  @override
  State<PatientVerificationScreen> createState() =>
      _PatientVerificationScreenState();
}

class _PatientVerificationScreenState
    extends State<PatientVerificationScreen> {
  // 6 individual OTP controllers + focus nodes
  static const int _otpLen = 6;
  final List<TextEditingController> _ctrl =
      List.generate(_otpLen, (_) => TextEditingController());
  final List<FocusNode> _focus =
      List.generate(_otpLen, (_) => FocusNode());

  // Countdown timer
  int _countdown = 60;
  Timer? _timer;
  bool _canResend = false;
  bool _isVerifying = false;
  bool _isVerified = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    // Auto-focus first cell
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
    for (final c in _ctrl) c.dispose();
    for (final f in _focus) f.dispose();
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
        // Auto-submit when last digit entered
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
          content: Text('Please enter all $_otpLen digits.',
              style: GoogleFonts.inter()),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() => _isVerifying = true);

    // Simulate verification (mock success after 1s)
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        _isVerified = true;
      });
      Future.delayed(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Dialog(
            backgroundColor: _kCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: _kBorder, width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _kSuccess.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.checkmark_shield_fill,
                      color: _kSuccess,
                      size: 38,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Verified!',
                      style: GoogleFonts.sora(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: _kText)),
                  const SizedBox(height: 10),
                  Text(
                    'Your vault is activated. You can now sign in with your credentials.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                        fontSize: 13, color: _kMuted, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Provider.of<AppState>(context, listen: false)
                            .setPatientAuthState(PatientAuthState.login);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kSuccess,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Proceed to Login',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
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
    // Clear all cells
    for (final c in _ctrl) c.clear();
    setState(() { _isVerified = false; });
    FocusScope.of(context).requestFocus(_focus[0]);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Verification code resent (mock).',
            style: GoogleFonts.inter()),
        backgroundColor: _kAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final masked = widget.identifier.length > 4
        ? '${widget.identifier.substring(0, 3)}●●●${widget.identifier.substring(widget.identifier.length - 2)}'
        : widget.identifier.isNotEmpty
            ? widget.identifier
            : 'your registered contact';

    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _MeshPainter())),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back
                  IconButton(
                    onPressed: () =>
                        appState.setPatientAuthState(PatientAuthState.signup),
                    icon: const Icon(CupertinoIcons.arrow_left,
                        color: _kMuted, size: 22),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),

                  const SizedBox(height: 32),

                  // Badge
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: _kCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: _isVerified
                              ? _kSuccess.withValues(alpha: 0.5)
                              : _kAccent.withValues(alpha: 0.4),
                          width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: (_isVerified ? _kSuccess : _kAccent)
                              .withValues(alpha: 0.2),
                          blurRadius: 16,
                        )
                      ],
                    ),
                    child: Icon(
                      _isVerified
                          ? CupertinoIcons.checkmark_shield_fill
                          : CupertinoIcons.shield_lefthalf_fill,
                      color: _isVerified ? _kSuccess : _kAccent,
                      size: 26,
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    'Verify your mobile number',
                    style: GoogleFonts.sora(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: _kText),
                  ),
                  const SizedBox(height: 8),
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.inter(fontSize: 14, color: _kMuted),
                      children: [
                        const TextSpan(text: 'A 6-digit code was sent to your mobile: '),
                        TextSpan(
                          text: masked,
                          style: GoogleFonts.inter(
                              color: _kAccent, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // ── OTP Grid ─────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(_otpLen, (i) => _OtpCell(
                      controller: _ctrl[i],
                      focusNode: _focus[i],
                      isVerified: _isVerified,
                      onChanged: (v) => _onDigitEntered(i, v),
                      onKey: (e) => _onKeyEvent(i, e),
                    )),
                  ),

                  const SizedBox(height: 32),

                  // ── Timer / Resend ────────────────────────────
                  Center(
                    child: _canResend
                        ? TextButton(
                            onPressed: _resend,
                            child: Text(
                              'Resend code',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: _kAccent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(CupertinoIcons.clock,
                                  size: 14, color: _kMuted),
                              const SizedBox(width: 6),
                              Text(
                                'Resend in ${_countdown}s',
                                style: GoogleFonts.inter(
                                    fontSize: 13, color: _kMuted),
                              ),
                            ],
                          ),
                  ),

                  const SizedBox(height: 28),

                  // ── Verify CTA ────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isVerifying || _isVerified ? null : _verify,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _isVerified ? _kSuccess : _kAccent,
                        disabledBackgroundColor:
                            (_isVerified ? _kSuccess : _kAccent)
                                .withValues(alpha: 0.4),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isVerifying
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_isVerified)
                                  const Padding(
                                    padding: EdgeInsets.only(right: 8),
                                    child: Icon(
                                        CupertinoIcons.checkmark,
                                        size: 18,
                                        color: Colors.white),
                                  ),
                                Text(
                                  _isVerified
                                      ? 'Identity Confirmed'
                                      : 'Verify Code',
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Security note
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: _kCard,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _kBorder, width: 1),
                    ),
                    child: Row(
                      children: [
                        const Icon(CupertinoIcons.info_circle,
                            color: _kMuted, size: 16),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'This code expires in 10 minutes. Do not share it with anyone.',
                            style: GoogleFonts.inter(
                                fontSize: 12, color: _kMuted, height: 1.4),
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
}

// ── Individual OTP cell widget ─────────────────────────────────────────────
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
        height: 56,
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 1,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: isVerified ? _kSuccess : _kText,
          ),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: onChanged,
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: _kCard,
            contentPadding: EdgeInsets.zero,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isVerified ? _kSuccess : _kBorder,
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isVerified ? _kSuccess : _kAccent,
                width: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MeshPainter extends CustomPainter {
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
