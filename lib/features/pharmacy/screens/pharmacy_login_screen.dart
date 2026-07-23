// ════════════════════════════════════════════════════════════════════════════
// AegisRx — Pharmacy Login Screen
// Design System: AegisRx Clinical Precision
// Business logic: UNCHANGED — loginPharmacy(), resetFlow() preserved exactly
// ════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/state/app_state.dart';
import '../../../core/theme/design_system.dart';

class PharmacyLoginScreen extends StatefulWidget {
  const PharmacyLoginScreen({super.key});

  @override
  State<PharmacyLoginScreen> createState() => _PharmacyLoginScreenState();
}

class _PharmacyLoginScreenState extends State<PharmacyLoginScreen>
    with SingleTickerProviderStateMixin {
  final _licenseController = TextEditingController();
  bool _isLoading = false;
  String? _selectedPharmacy;

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
    _licenseController.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  // ── BUSINESS LOGIC UNCHANGED ──────────────────────────────────────────────
  void _login() async {
    final license = _licenseController.text.trim();
    if (license.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your registered pharmacy.'),
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    final appState = Provider.of<AppState>(context, listen: false);
    final error = await appState.loginPharmacy(license);
    if (mounted) setState(() => _isLoading = false);
    if (error != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }
  // ── END BUSINESS LOGIC ────────────────────────────────────────────────────

  static const _pharmacyItems = [
    ('PHARM-AMOY-01', 'Aegis Pharmacy', 'Amoy-01'),
    ('PHARM-AMOY-02', 'Sovereign Care', 'Amoy-02'),
    ('PHARM-APOLLO-09', 'Apollo Pharma', 'Apollo-09'),
    ('PHARM-CV-HEALTH', 'CV Health Desk', 'CV-Health'),
    ('PHARM-RX-SECURE', 'SafeRx Dispensary', 'Rx-Secure'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AegisColors.background,
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _PharmacyGridPainter())),
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
                      children: [
                        // ── Portal Badge ───────────────────────────
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: AegisColors.pharmacyAccent.withValues(
                              alpha: 0.1,
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AegisColors.pharmacyAccent.withValues(
                                alpha: 0.35,
                              ),
                              width: AegisBorders.regular,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AegisColors.pharmacyAccent.withValues(
                                  alpha: 0.15,
                                ),
                                blurRadius: 24,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.local_pharmacy_rounded,
                            size: 40,
                            color: AegisColors.pharmacyAccent,
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
                            color: AegisColors.pharmacyAccent.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: AegisRadius.chip,
                            border: Border.all(
                              color: AegisColors.pharmacyAccent.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          child: Text(
                            'PHARMACY PORTAL',
                            style: AegisTypography.labelCaps.copyWith(
                              color: AegisColors.pharmacyAccent,
                              letterSpacing: 2.5,
                            ),
                          ),
                        ),

                        const SizedBox(height: AegisSpacing.xxl),

                        // ── Pharmacy selector card ─────────────────
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
                                      color: AegisColors.pharmacyAccent
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(
                                        AegisRadius.sm,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.local_pharmacy_outlined,
                                      size: AegisIconSize.sm,
                                      color: AegisColors.pharmacyAccent,
                                    ),
                                  ),
                                  const SizedBox(width: AegisSpacing.sm),
                                  Text(
                                    'Dispensation Access',
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

                              // Pharmacy dropdown — preserves all original items
                              DropdownButtonFormField<String>(
                                isExpanded: true,
                                value: _selectedPharmacy,
                                style: AegisTypography.bodyMedium.copyWith(
                                  color: AegisColors.textPrimary,
                                ),
                                dropdownColor: AegisColors.surface,
                                decoration: InputDecoration(
                                  labelText: 'Select Registered Pharmacy',
                                  labelStyle: AegisTypography.bodyMedium
                                      .copyWith(
                                        color: AegisColors.textSecondary,
                                      ),
                                  prefixIcon: const Icon(
                                    Icons.local_pharmacy_rounded,
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
                                      color: AegisColors.pharmacyAccent,
                                      width: AegisBorders.regular,
                                    ),
                                  ),
                                ),
                                items: _pharmacyItems.map((item) {
                                  final (value, name, code) = item;
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '$name ($code)',
                                            overflow: TextOverflow.ellipsis,
                                            style: AegisTypography.bodyMedium
                                                .copyWith(
                                                  color:
                                                      AegisColors.textPrimary,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _selectedPharmacy = val);
                                    _licenseController.text = val;
                                  }
                                },
                              ),

                              const SizedBox(height: AegisSpacing.base),

                              // CTA
                              AnimatedOpacity(
                                opacity: _selectedPharmacy != null ? 1.0 : 0.5,
                                duration: AegisMotion.moderate,
                                child: SizedBox(
                                  width: double.infinity,
                                  height: AegisTokens.btnHeight,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _login,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          AegisColors.pharmacyAccent,
                                      foregroundColor: Colors.white,
                                      disabledBackgroundColor: AegisColors
                                          .pharmacyAccent
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
                                                Icons.medication_rounded,
                                                size: AegisIconSize.sm,
                                              ),
                                              SizedBox(width: AegisSpacing.sm),
                                              Flexible(
                                                child: Text(
                                                  'Access Dispensation Desk',
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: AegisSpacing.lg),

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

class _PharmacyGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AegisColors.pharmacyAccent.withValues(alpha: 0.025)
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
