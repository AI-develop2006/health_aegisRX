// ════════════════════════════════════════════════════════════════════════════
// AegisRx — Patient Unlock Screen (PIN entry)
// Design System: AegisRx Clinical Precision
// Business logic: UNCHANGED — unlockDevice(), resetFlow() preserved exactly
// ════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/design_system.dart';

class PatientUnlockScreen extends StatefulWidget {
  const PatientUnlockScreen({super.key});

  @override
  State<PatientUnlockScreen> createState() => _PatientUnlockScreenState();
}

class _PatientUnlockScreenState extends State<PatientUnlockScreen>
    with SingleTickerProviderStateMixin {
  final _pinController = TextEditingController();
  bool _isError = false;

  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _pinController.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  // ── BUSINESS LOGIC UNCHANGED ──────────────────────────────────────────────
  void _unlock() {
    final pin = _pinController.text;
    if (pin.isEmpty) return;

    final appState = Provider.of<AppState>(context, listen: false);
    final success = appState.unlockDevice(pin);

    if (!success) {
      setState(() => _isError = true);
      _shakeCtrl.forward(from: 0).then((_) {
        setState(() => _isError = false);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Invalid passcode. Try "1234" or the custom PIN you set.'),
          backgroundColor: AegisColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      _pinController.clear();
    }
  }
  // ── END BUSINESS LOGIC ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AegisColors.background,
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _UnlockGridPainter())),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AegisSpacing.pagePadding,
                  vertical: AegisSpacing.xl,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ── Shield icon ──────────────────────────────
                    AnimatedBuilder(
                      animation: _shakeAnim,
                      builder: (context, child) {
                        final offset = _isError
                            ? 8 * (_shakeAnim.value < 0.5
                                ? _shakeAnim.value * 2
                                : (1 - _shakeAnim.value) * 2)
                            : 0.0;
                        return Transform.translate(
                          offset: Offset(offset * (_shakeAnim.value < 0.5 ? -1 : 1), 0),
                          child: child,
                        );
                      },
                      child: Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: AegisColors.primarySurface,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AegisColors.primary.withValues(alpha: 0.3),
                            width: AegisBorders.regular,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AegisColors.primary.withValues(alpha: 0.15),
                              blurRadius: 24,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.lock_rounded,
                          color: AegisColors.primary,
                          size: 40,
                        ),
                      ),
                    ),

                    const SizedBox(height: AegisSpacing.lg),

                    Text(
                      'Unlock Device Vault',
                      style: AegisTypography.displaySmall.copyWith(
                        color: AegisColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AegisSpacing.sm),
                    Text(
                      'Secure session present.\nEnter your PIN to decrypt local medical keys.',
                      textAlign: TextAlign.center,
                      style: AegisTypography.bodyMedium.copyWith(
                        color: AegisColors.textSecondary,
                        height: 1.6,
                      ),
                    ),

                    const SizedBox(height: AegisSpacing.xxl),

                    // ── PIN field ──────────────────────────────────
                    AnimatedBuilder(
                      animation: _shakeAnim,
                      builder: (context, child) {
                        final dx = _isError
                            ? 6 * (_shakeAnim.value < 0.5
                                ? _shakeAnim.value * 2
                                : (1 - _shakeAnim.value) * 2)
                            : 0.0;
                        return Transform.translate(
                          offset: Offset(dx * (_shakeAnim.value < 0.25 ? -1 : 1), 0),
                          child: child,
                        );
                      },
                      child: TextField(
                        controller: _pinController,
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        maxLength: 6,
                        textAlign: TextAlign.center,
                        style: AegisTypography.monoXL.copyWith(
                          color: _isError ? AegisColors.danger : AegisColors.textPrimary,
                          letterSpacing: 14,
                        ),
                        onSubmitted: (_) => _unlock(),
                        decoration: InputDecoration(
                          counterText: '',
                          hintText: '• • • • • •',
                          hintStyle: AegisTypography.monoLarge.copyWith(
                            color: AegisColors.textTertiary,
                            letterSpacing: 8,
                          ),
                          filled: true,
                          fillColor: AegisColors.surface,
                          prefixIcon: const Icon(Icons.password_rounded,
                              color: AegisColors.textTertiary, size: AegisIconSize.md),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: AegisRadius.input,
                            borderSide: BorderSide(
                              color: _isError ? AegisColors.danger : AegisColors.border,
                              width: AegisBorders.regular,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: AegisRadius.input,
                            borderSide: BorderSide(
                              color: _isError ? AegisColors.danger : AegisColors.primary,
                              width: AegisBorders.thick,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: AegisSpacing.lg),

                    // ── Unlock CTA ─────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: AegisTokens.btnHeight,
                      child: ElevatedButton(
                        onPressed: _unlock,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AegisColors.primary,
                          foregroundColor: AegisColors.onPrimary,
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: AegisRadius.button),
                          textStyle: AegisTypography.labelLarge,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.lock_open_rounded, size: AegisIconSize.sm),
                            SizedBox(width: AegisSpacing.sm),
                            Text('Unlock Vault'),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: AegisSpacing.md),

                    TextButton(
                      onPressed: () =>
                          Provider.of<AppState>(context, listen: false).resetFlow(),
                      child: Text(
                        'Cancel & Switch Role',
                        style: AegisTypography.bodySmall.copyWith(
                            color: AegisColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnlockGridPainter extends CustomPainter {
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
