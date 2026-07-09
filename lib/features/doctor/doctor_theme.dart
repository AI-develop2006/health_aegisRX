
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ═══════════════════════════════════════════════════════════════
// AegisRx Doctor Portal — Clinical Cockpit Design System
// 60-30-10 Sterile Clinical Palette
// ═══════════════════════════════════════════════════════════════

/// All design tokens for the doctor portal. Import this file in every screen.
class Dr {
  // 60% DOMINANT — Canvas Surface
  static const bg = Color(0xFFF4F7F6);   // Soft clinical canvas
  static const card = Color(0xFFFFFFFF); // Crisp card base

  // 30% SECONDARY — Structure & Typography
  static const text = Color(0xFF111E1C);   // Deepest charcoal-teal
  static const border = Color(0xFFD1DDD9); // Muted clinical steel
  static const sub = Color(0xFF5A6E6A);    // Gray-teal metadata

  // 10% ACCENT — Diagnostic Action Lights
  static const green = Color(0xFF00A86B);  // Medical Green — safe/verified/CTA
  static const amber = Color(0xFFD97736);  // Warning state
  static const red = Color(0xFFB33A3A);    // Critical alert

  // Shadows
  static const cardShadow = BoxShadow(
    color: Color(0x0F00A86B), // Medical Green at 6% opacity
    blurRadius: 12,
    offset: Offset(0, 4),
    spreadRadius: 1,
  );

  // Text styles
  static TextStyle heading(double size) => GoogleFonts.sora(
        fontSize: size,
        fontWeight: FontWeight.bold,
        color: Dr.text,
      );
  static TextStyle body(double size) => GoogleFonts.inter(
        fontSize: size,
        color: Dr.text,
      );
  static TextStyle meta(double size) => GoogleFonts.inter(
        fontSize: size,
        color: Dr.sub,
      );
  static TextStyle mono(double size) => GoogleFonts.jetBrainsMono(
        fontSize: size,
        color: Dr.text,
      );
}

// ── Flat clinical card ─────────────────────────────────────────
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
    this.borderRadius = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Dr.card,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor ?? Dr.border, width: 1.0),
        boxShadow: const [Dr.cardShadow],
      ),
      child: child,
    );
  }
}

// ── Primary CTA button — Medical Green ────────────────────────
class DoctorPrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isLoading;

  const DoctorPrimaryButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
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
          backgroundColor: Dr.green,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
                    Icon(icon, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.white,
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

// ── Outlined secondary button ──────────────────────────────────
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
    final c = color ?? Dr.green;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: c,
          side: BorderSide(color: c, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: c),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: c,
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

// ── Status badge chip ──────────────────────────────────────────
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Clinical Grid Background Painter ──────────────────────────
class ClinicalGridPainter extends CustomPainter {
  const ClinicalGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00A86B).withOpacity(0.05)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.fill;

    const spacing = 20.0;
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

// ── Scaffold with clinical grid background ─────────────────────
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
      backgroundColor: Dr.bg,
      appBar: appBar,
      body: CustomPaint(
        painter: const ClinicalGridPainter(),
        child: body,
      ),
    );
  }
}

// ── Clinical AppBar ────────────────────────────────────────────
PreferredSizeWidget clinicalAppBar({
  required String title,
  List<Widget>? actions,
  bool showBack = true,
  BuildContext? context,
}) {
  return AppBar(
    backgroundColor: Dr.card,
    elevation: 0,
    scrolledUnderElevation: 0,
    surfaceTintColor: Colors.transparent,
    automaticallyImplyLeading: showBack,
    iconTheme: const IconThemeData(color: Dr.text),
    title: Text(
      title,
      style: GoogleFonts.sora(
        fontWeight: FontWeight.bold,
        fontSize: 17,
        color: Dr.text,
      ),
    ),
    bottom: PreferredSize(
      preferredSize: const Size.fromHeight(1),
      child: Container(height: 1, color: Dr.border),
    ),
    actions: actions,
  );
}

// ── Section header ─────────────────────────────────────────────
Widget sectionHeader(String title) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(title, style: Dr.heading(15)),
  );
}

// ── Risk color helper ──────────────────────────────────────────
Color riskColor(String level) {
  switch (level.toUpperCase()) {
    case 'HIGH_RISK':
    case 'CRITICAL':
      return Dr.red;
    case 'WARNING':
    case 'MEDIUM':
      return Dr.amber;
    default:
      return Dr.green;
  }
}

String riskLabel(String level) {
  switch (level.toUpperCase()) {
    case 'HIGH_RISK':
    case 'CRITICAL':
      return 'HIGH RISK';
    case 'WARNING':
    case 'MEDIUM':
      return 'WARNING';
    default:
      return 'SAFE';
  }
}
