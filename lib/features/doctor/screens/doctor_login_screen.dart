// ════════════════════════════════════════════════════════════════════════════
// AegisRx — Doctor Login Screen
// Design System: AegisRx Clinical Precision
// Business logic: UNCHANGED — loginDoctor(), resetFlow() preserved exactly
// ════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/state/app_state.dart';
import '../../../core/theme/design_system.dart';
import 'doctor_onboarding_screen.dart';

class DoctorLoginScreen extends StatefulWidget {
  const DoctorLoginScreen({super.key});

  @override
  State<DoctorLoginScreen> createState() => _DoctorLoginScreenState();
}

class _DoctorLoginScreenState extends State<DoctorLoginScreen>
    with SingleTickerProviderStateMixin {
  final _npiController = TextEditingController();
  bool _isLoading = false;

  late AnimationController _entryCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(vsync: this, duration: AegisMotion.normal);
    _fadeAnim = CurvedAnimation(
      parent: _entryCtrl,
      curve: AegisMotion.decelerate,
    );
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _entryCtrl, curve: AegisMotion.decelerate),
        );
    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _npiController.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  // ── BUSINESS LOGIC UNCHANGED ──────────────────────────────────────────────
  void _login() async {
    final npi = _npiController.text.trim();
    if (npi.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your National Provider Identifier (NPI)'),
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    final appState = Provider.of<AppState>(context, listen: false);
    final error = await appState.loginDoctor(npi);
    if (mounted) setState(() => _isLoading = false);
    if (error != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }
  // ── END BUSINESS LOGIC ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AegisColors.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _DoctorAuthGridPainter()),
          ),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AegisSpacing.pagePadding,
                      vertical: AegisSpacing.xl,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // ── Doctor Portal Badge ────────────────────
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: AegisColors.doctorAccent.withValues(
                              alpha: 0.1,
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AegisColors.doctorAccent.withValues(
                                alpha: 0.35,
                              ),
                              width: AegisBorders.regular,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AegisColors.doctorAccent.withValues(
                                  alpha: 0.15,
                                ),
                                blurRadius: 24,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.medical_services_rounded,
                            size: 40,
                            color: AegisColors.doctorAccent,
                          ),
                        ),

                        const SizedBox(height: AegisSpacing.base),

                        Text(
                          'AegisRx',
                          style: AegisTypography.displaySmall.copyWith(
                            color: AegisColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AegisSpacing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AegisSpacing.md,
                            vertical: AegisSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: AegisColors.doctorAccent.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: AegisRadius.chip,
                            border: Border.all(
                              color: AegisColors.doctorAccent.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          child: Text(
                            'PRACTITIONER PORTAL',
                            style: AegisTypography.labelCaps.copyWith(
                              color: AegisColors.doctorAccent,
                              letterSpacing: 2.5,
                            ),
                          ),
                        ),

                        const SizedBox(height: AegisSpacing.xxl),

                        // ── Login card ─────────────────────────────
                        Container(
                          padding: const EdgeInsets.all(AegisSpacing.lg),
                          decoration: BoxDecoration(
                            color: AegisColors.surface,
                            borderRadius: AegisRadius.card,
                            border: Border.all(color: AegisColors.border),
                            boxShadow: AegisShadows.md,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Card header
                              Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: AegisColors.doctorAccent
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(
                                        AegisRadius.sm,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.badge_outlined,
                                      size: AegisIconSize.sm,
                                      color: AegisColors.doctorAccent,
                                    ),
                                  ),
                                  const SizedBox(width: AegisSpacing.sm),
                                  Text(
                                    'Clinician Authentication',
                                    style: AegisTypography.titleSmall.copyWith(
                                      color: AegisColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: AegisSpacing.base),
                              const Divider(
                                height: 1,
                                color: AegisColors.border,
                              ),
                              const SizedBox(height: AegisSpacing.base),

                              // NPI field
                              TextField(
                                controller: _npiController,
                                keyboardType: TextInputType.text,
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 15,
                                  color: AegisColors.textPrimary,
                                  letterSpacing: 2,
                                ),
                                onSubmitted: (_) => _login(),
                                decoration: InputDecoration(
                                  labelText:
                                      'National Provider Identifier (NPI)',
                                  hintText: 'xxxxxxx',
                                  hintStyle: AegisTypography.bodyMedium
                                      .copyWith(
                                        color: AegisColors.textTertiary,
                                      ),
                                  labelStyle: AegisTypography.bodyMedium
                                      .copyWith(
                                        color: AegisColors.textSecondary,
                                      ),
                                  prefixIcon: const Icon(
                                    Icons.badge_rounded,
                                    color: AegisColors.textTertiary,
                                    size: AegisIconSize.md,
                                  ),
                                  filled: true,
                                  fillColor: AegisColors.background,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: AegisSpacing.inputPaddingH,
                                    vertical: AegisSpacing.inputPaddingV,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: AegisRadius.input,
                                    borderSide: const BorderSide(
                                      color: AegisColors.border,
                                      width: AegisBorders.regular,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: AegisRadius.input,
                                    borderSide: BorderSide(
                                      color: AegisColors.doctorAccent,
                                      width: AegisBorders.regular,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: AegisSpacing.base),

                              // CTA
                              SizedBox(
                                width: double.infinity,
                                height: AegisTokens.btnHeight,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AegisColors.doctorAccent,
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor: AegisColors
                                        .doctorAccent
                                        .withValues(alpha: 0.4),
                                    elevation: 0,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: AegisRadius.button,
                                    ),
                                    textStyle: AegisTypography.labelLarge,
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.login_rounded,
                                              size: AegisIconSize.sm,
                                            ),
                                            SizedBox(width: AegisSpacing.sm),
                                            Flexible(
                                              child: Text(
                                                'Access Clinician Suite',
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: AegisSpacing.lg),

                        // ── Secondary actions ──────────────────────
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const DoctorOnboardingScreen(),
                            ),
                          ),
                          child: Text(
                            'Request a doctor account →',
                            style: AegisTypography.bodySmall.copyWith(
                              color: AegisColors.doctorAccent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Provider.of<AppState>(
                            context,
                            listen: false,
                          ).resetFlow(),
                          child: Text(
                            'Back to role selection',
                            style: AegisTypography.bodySmall.copyWith(
                              color: AegisColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DoctorAuthGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AegisColors.doctorAccent.withValues(alpha: 0.025)
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
