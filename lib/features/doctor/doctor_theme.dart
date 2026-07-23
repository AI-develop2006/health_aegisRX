// ════════════════════════════════════════════════════════════════════════════
// AegisRx Doctor Portal — Component Library
// Design System: AegisRx Clinical Precision
// Color Rules:
//   Blue (#2563EB)   = Primary actions & main buttons
//   Red (#BA1A1A)    = Critical alerts & high risk
//   Orange (#D97706) = Warnings & medium risk
//   Teal (#14B8A6)   = Safe recommendations & verified badges
//   Purple (#7C3AED) = AI features (Voice dictation, AI audit, OCR import)
// ════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:health_lock/core/theme/design_system.dart';

// ── Legacy Token Shim ──────────────────────────────────────────────────────
class Dr {
  // Canvas & Surfaces
  static const bg   = AegisColors.background;
  static const card = AegisColors.surface;

  // Structure & Typography
  static const text   = AegisColors.textPrimary;
  static const border = AegisColors.border;
  static const sub    = AegisColors.textSecondary;

  // Color Role Tokens
  static const primary = AegisColors.primary;   // Royal Blue (Primary actions)
  static const green   = AegisColors.secondary; // Medical Teal (Safe / Verified)
  static const amber   = AegisColors.warning;   // Amber/Orange (Warnings)
  static const red     = AegisColors.danger;    // Crimson Red (Critical alerts)
  static const purple  = AegisColors.tertiary;  // AI Purple (AI features)

  // Shadows
  static const cardShadow = BoxShadow(
    color: Color(0x0A0B1C30),
    blurRadius: 12,
    offset: Offset(0, 4),
    spreadRadius: 0,
  );

  // Text Style Helpers
  static TextStyle heading(double size) => AegisTypography.headlineMedium.copyWith(
    fontSize: size,
    color: Dr.text,
  );

  static TextStyle body(double size) => AegisTypography.bodyMedium.copyWith(
    fontSize: size,
    color: Dr.text,
  );

  static TextStyle meta(double size) => AegisTypography.bodySmall.copyWith(
    fontSize: size,
    color: Dr.sub,
  );

  static TextStyle mono(double size) => AegisTypography.monoMedium.copyWith(
    fontSize: size,
    color: Dr.text,
  );
}


// ── Flat Clinical Card ─────────────────────────────────────────────────────
class DoctorCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? borderColor;
  final double borderRadius;

  const DoctorCard({
    super.key,
    required this.child,
    this.padding,
    this.borderColor,
    this.borderRadius = AegisRadius.lg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.symmetric(
        horizontal: AegisTokens.cardPaddingH,
        vertical: AegisTokens.cardPaddingV,
      ),
      decoration: BoxDecoration(
        color: AegisTokens.cardBg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? AegisTokens.cardBorder,
          width: AegisBorders.thin,
        ),
        boxShadow: AegisShadows.sm,
      ),
      child: child,
    );
  }
}


// ── Primary Action Button — Royal Blue ─────────────────────────────────────
class DoctorPrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? backgroundColor;

  const DoctorPrimaryButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? AegisColors.primary; // Blue for primary actions
    return SizedBox(
      width: double.infinity,
      height: AegisTokens.btnHeight,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: Colors.white,
          disabledBackgroundColor: bg.withValues(alpha: 0.4),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: AegisRadius.button),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: AegisIconSize.sm, color: Colors.white),
                    const SizedBox(width: AegisSpacing.sm),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      style: AegisTypography.labelLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}


// ── AI Action Button — AI Purple (#7C3AED) ────────────────────────────────
class DoctorAiButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isLoading;

  const DoctorAiButton({
    super.key,
    required this.label,
    this.icon = Icons.auto_awesome_rounded,
    this.onPressed,
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
          backgroundColor: AegisColors.tertiary, // AI Purple
          foregroundColor: Colors.white,
          disabledBackgroundColor: AegisColors.tertiarySurface,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: AegisRadius.button),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: AegisIconSize.sm, color: Colors.white),
                  const SizedBox(width: AegisSpacing.sm),
                  Flexible(
                    child: Text(
                      label,
                      style: AegisTypography.labelLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}


// ── Outlined Secondary Button ──────────────────────────────────────────────
class DoctorOutlinedButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color? color;

  const DoctorOutlinedButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AegisColors.primary;
    return SizedBox(
      width: double.infinity,
      height: AegisTokens.btnHeight,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: c,
          side: BorderSide(color: c, width: AegisBorders.regular),
          shape: RoundedRectangleBorder(borderRadius: AegisRadius.button),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: AegisIconSize.sm, color: c),
              const SizedBox(width: AegisSpacing.sm),
            ],
            Flexible(
              child: Text(
                label,
                style: AegisTypography.labelLarge.copyWith(color: c, fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ── Status Badge Chip ──────────────────────────────────────────────────────
class DoctorStatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const DoctorStatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AegisTokens.chipPaddingH,
        vertical: AegisTokens.chipPaddingV,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: AegisRadius.chip,
        border: Border.all(color: color.withValues(alpha: 0.45), width: AegisBorders.thin),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: AegisIconSize.xs, color: color),
            const SizedBox(width: AegisSpacing.xs),
          ],
          Flexible(
            child: Text(
              label,
              style: AegisTypography.labelSmall.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}


// ── Clinical Grid Dot Background ───────────────────────────────────────────
class ClinicalGridPainter extends CustomPainter {
  const ClinicalGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AegisColors.primary.withValues(alpha: 0.04)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.fill;

    const spacing = 22.0;
    const dotRadius = 1.0;

    for (double x = 0; x <= size.width; x += spacing) {
      for (double y = 0; y <= size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


// ── Scaffold with Clinical Grid Background ─────────────────────────────────
class ClinicalScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;

  const ClinicalScaffold({
    super.key,
    this.appBar,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AegisColors.background,
      appBar: appBar,
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: const ClinicalGridPainter(),
            ),
          ),
          SafeArea(
            bottom: false,
            child: body,
          ),
        ],
      ),
    );
  }
}


// ── Clinical AppBar ────────────────────────────────────────────────────────
PreferredSizeWidget clinicalAppBar({
  required String title,
  List<Widget>? actions,
  bool showBack = true,
  BuildContext? context,
}) {
  return AppBar(
    backgroundColor: AegisColors.surface,
    elevation: 0,
    scrolledUnderElevation: 0,
    surfaceTintColor: Colors.transparent,
    automaticallyImplyLeading: showBack,
    iconTheme: const IconThemeData(
      color: AegisColors.textPrimary,
      size: AegisIconSize.base,
    ),
    title: Text(title, style: AegisTypography.headlineMedium.copyWith(color: AegisColors.textPrimary)),
    bottom: const PreferredSize(
      preferredSize: Size.fromHeight(1),
      child: Divider(
        height: 1,
        thickness: 1,
        color: AegisColors.border,
      ),
    ),
    actions: actions,
  );
}


// ── Section Header ─────────────────────────────────────────────────────────
Widget sectionHeader(String title) {
  return Padding(
    padding: const EdgeInsets.only(bottom: AegisSpacing.sm),
    child: Text(
      title,
      style: AegisTypography.titleSmall.copyWith(
        color: AegisColors.textPrimary,
        letterSpacing: 0.3,
      ),
    ),
  );
}


// ── Risk Color Helper ──────────────────────────────────────────────────────
Color riskColor(String level) {
  switch (level.toUpperCase()) {
    case 'HIGH_RISK':
    case 'CRITICAL':
    case 'HIGH':
      return AegisColors.danger; // Crimson Red for critical/high risk
    case 'WARNING':
    case 'MEDIUM':
      return AegisColors.warning; // Amber/Orange for warnings
    default:
      return AegisColors.secondary; // Medical Teal for safe
  }
}

String riskLabel(String level) {
  switch (level.toUpperCase()) {
    case 'HIGH_RISK':
    case 'CRITICAL':
    case 'HIGH':
      return 'HIGH RISK';
    case 'WARNING':
    case 'MEDIUM':
      return 'WARNING';
    default:
      return 'SAFE';
  }
}
