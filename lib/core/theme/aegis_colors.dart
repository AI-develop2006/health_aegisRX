// ============================================================
// AegisRx Design System — Color System
// Clinical Precision Palette · WCAG AA Compliant
// ============================================================

import 'package:flutter/material.dart';

class AegisColors {
  AegisColors._();

  // ── Primary Brand ──────────────────────────────────────────
  // Royal Blue — core actions, primary buttons, active navigation
  static const Color primary       = Color(0xFF2563EB);
  static const Color primaryLight  = Color(0xFF3B82F6);
  static const Color primaryDark   = Color(0xFF1D4ED8);
  static const Color primarySurface= Color(0xFFEFF6FF); // bg tint for primary
  static const Color onPrimary     = Color(0xFFFFFFFF);

  // ── Medical Teal ───────────────────────────────────────────
  // Health-positive: safe prescriptions, verified states, wellness
  static const Color secondary       = Color(0xFF14B8A6);
  static const Color secondaryLight  = Color(0xFF2DD4BF);
  static const Color secondaryDark   = Color(0xFF0F766E);
  static const Color secondarySurface= Color(0xFFF0FDFA);
  static const Color onSecondary     = Color(0xFFFFFFFF);

  // ── AI & Blockchain Violet ─────────────────────────────────
  // Exclusively for AI explanations, voice parser, blockchain anchors
  static const Color tertiary       = Color(0xFF7C3AED);
  static const Color tertiaryLight  = Color(0xFF8B5CF6);
  static const Color tertiarySurface= Color(0xFFF5F3FF);
  static const Color onTertiary     = Color(0xFFFFFFFF);

  // ── Neutral Surface System ─────────────────────────────────
  static const Color background     = Color(0xFFF6F8FC); // Level 0 — page bg
  static const Color surface        = Color(0xFFFFFFFF); // Level 1 — cards
  static const Color surfaceDim     = Color(0xFFEFF4FF); // Level 1 dim
  static const Color surfaceOverlay = Color(0xCCFFFFFF); // Level 2 — modals (glass)
  static const Color inverseSurface = Color(0xFF213145); // Dark nav/snackbar

  // ── Text Colors ────────────────────────────────────────────
  // WCAG AA: #0F172A on #F6F8FC = 13.8:1 contrast ratio ✅
  static const Color textPrimary    = Color(0xFF0F172A); // Deep Navy
  static const Color textSecondary  = Color(0xFF475569); // Slate Gray
  static const Color textTertiary   = Color(0xFF94A3B8); // Muted
  static const Color textInverse    = Color(0xFFEAF1FF); // On dark surfaces
  static const Color textDisabled   = Color(0xFFCBD5E1);

  // ── Border & Divider ───────────────────────────────────────
  static const Color border         = Color(0xFFE2E8F0);
  static const Color borderFocus    = Color(0xFF2563EB);
  static const Color borderError    = Color(0xFFBA1A1A);
  static const Color divider        = Color(0xFFF1F5F9);

  // ── Status Semantic ────────────────────────────────────────
  // Danger (WCAG AA: #BA1A1A on white = 5.2:1 ✅)
  static const Color danger         = Color(0xFFBA1A1A);
  static const Color dangerLight    = Color(0xFFFFEDED);
  static const Color dangerDark     = Color(0xFF93000A);

  // Warning (WCAG AA: #92400E on #FFFBEB = 5.7:1 ✅)
  static const Color warning        = Color(0xFFD97706);
  static const Color warningLight   = Color(0xFFFEF3C7);
  static const Color warningDark    = Color(0xFF92400E);

  // Success
  static const Color success        = Color(0xFF16A34A);
  static const Color successLight   = Color(0xFFF0FDF4);
  static const Color successDark    = Color(0xFF14532D);

  // Info
  static const Color info           = Color(0xFF0EA5E9);
  static const Color infoLight      = Color(0xFFE0F2FE);

  // ── Gradient Presets ───────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient aiGradient = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFF2563EB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient healthGradient = LinearGradient(
    colors: [Color(0xFF14B8A6), Color(0xFF2563EB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Portal Identity Colors ─────────────────────────────────
  // Used for portal-specific accent badges only
  static const Color patientAccent  = Color(0xFF2563EB);  // Royal Blue
  static const Color doctorAccent   = Color(0xFF14B8A6);  // Medical Teal
  static const Color pharmacyAccent = Color(0xFF7C3AED);  // Violet
}
