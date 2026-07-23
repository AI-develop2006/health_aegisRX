// ════════════════════════════════════════════════════════════════════════════
// AegisRx — Patient Auth Choice Screen
// Design System: AegisRx Clinical Precision
// Business logic: UNCHANGED — setPatientAuthState() calls preserved exactly
// ════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/design_system.dart';

class PatientAuthChoiceScreen extends StatelessWidget {
  const PatientAuthChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);

    return Scaffold(
      backgroundColor: AegisColors.background,
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _AuthGridPainter())),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AegisSpacing.pagePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AegisSpacing.base),

                  // Back button
                  _BackButton(onTap: () => appState.resetFlow()),

                  const SizedBox(height: AegisSpacing.xl),

                  // ── Icon badge ─────────────────────────────────
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AegisColors.primarySurface,
                      borderRadius: BorderRadius.circular(AegisRadius.md),
                      border: Border.all(
                          color: AegisColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: const Icon(
                      Icons.lock_person_rounded,
                      color: AegisColors.primary,
                      size: AegisIconSize.xl,
                    ),
                  ),

                  const SizedBox(height: AegisSpacing.base),

                  Text(
                    'Patient Vault Access',
                    style: AegisTypography.displaySmall.copyWith(
                      color: AegisColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AegisSpacing.sm),
                  Text(
                    'Decentralised encryption secures\nyour medical identity.',
                    style: AegisTypography.bodyMedium.copyWith(
                      color: AegisColors.textSecondary,
                      height: 1.6,
                    ),
                  ),

                  const SizedBox(height: AegisSpacing.xxl),

                  // ── New patient ────────────────────────────────
                  _ChoiceTile(
                    icon: Icons.person_add_alt_1_rounded,
                    title: 'I am a new patient',
                    subtitle: 'Create your sovereign health vault with cryptographic key pairs.',
                    accentColor: AegisColors.primary,
                    surfaceColor: AegisColors.primarySurface,
                    onTap: () => appState.setPatientAuthState(PatientAuthState.signup),
                  ),

                  const SizedBox(height: AegisSpacing.md),

                  // ── Existing patient ───────────────────────────
                  _ChoiceTile(
                    icon: Icons.lock_open_rounded,
                    title: 'I already have an account',
                    subtitle: 'Decrypt and unlock your existing medical vault records.',
                    accentColor: AegisColors.secondary,
                    surfaceColor: AegisColors.secondarySurface,
                    onTap: () => appState.setPatientAuthState(PatientAuthState.login),
                  ),

                  const Spacer(),

                  // Footer
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: AegisSpacing.lg),
                      child: Text(
                        'AegisRx · HealthLock Security Gateway',
                        style: AegisTypography.labelSmall.copyWith(
                          color: AegisColors.textTertiary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final Color surfaceColor;
  final VoidCallback onTap;

  const _ChoiceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.surfaceColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AegisRadius.card,
      child: Container(
        padding: const EdgeInsets.all(AegisSpacing.base),
        decoration: BoxDecoration(
          color: AegisColors.surface,
          borderRadius: AegisRadius.card,
          border: Border.all(color: AegisColors.border),
          boxShadow: AegisShadows.sm,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(AegisRadius.sm),
              ),
              child: Icon(icon, size: AegisIconSize.md, color: accentColor),
            ),
            const SizedBox(width: AegisSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AegisTypography.titleMedium.copyWith(
                          color: AegisColors.textPrimary)),
                  const SizedBox(height: AegisSpacing.xs),
                  Text(subtitle,
                      style: AegisTypography.bodySmall.copyWith(
                          color: AegisColors.textSecondary, height: 1.4)),
                ],
              ),
            ),
            const SizedBox(width: AegisSpacing.sm),
            Icon(Icons.chevron_right_rounded,
                size: AegisIconSize.md, color: AegisColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

// ── Shared subtle grid background ─────────────────────────────────────────
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

// ── Shared back button ─────────────────────────────────────────────────────
class _BackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});

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
