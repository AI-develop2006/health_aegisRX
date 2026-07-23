// ─────────────────────────────────────────────────────────────
// AegisRx — AppColors (Legacy Compatibility Shim)
// ─────────────────────────────────────────────────────────────
// All constants now forward to AegisColors.
// Screens that import AppColors continue to compile unchanged.
// Migrate screen-level usages to AegisColors over time.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:health_lock/core/theme/aegis_colors.dart';

class AppColors {
  // ── Canvas & Surfaces ──────────────────────────────────────
  static const Color baseCanvas     = AegisColors.background;
  static const Color cardSurface    = AegisColors.surface;
  static const Color surfaceMuted   = AegisColors.surfaceDim;
  static const Color borderWhite    = AegisColors.border;

  // ── Typography ─────────────────────────────────────────────
  static const Color primaryText    = AegisColors.textPrimary;
  static const Color mutedText      = AegisColors.textSecondary;
  static const Color textFaint      = AegisColors.textTertiary;

  // ── Role Accents ───────────────────────────────────────────
  static const Color patientBlue    = AegisColors.primary;
  static const Color patientBlueDark= AegisColors.primaryDark;
  static const Color doctorTeal     = AegisColors.secondary;
  static const Color pharmacyViolet = AegisColors.tertiary;
  static const Color verifiedEmerald= AegisColors.success;

  // ── Tint Backgrounds ───────────────────────────────────────
  static const Color tintBlue       = AegisColors.primarySurface;
  static const Color tintTeal       = AegisColors.secondarySurface;
  static const Color tintViolet     = AegisColors.tertiarySurface;
  static const Color tintEmerald    = AegisColors.successLight;
  static const Color tintSlate      = AegisColors.surfaceDim;

  // ── Status Colors ──────────────────────────────────────────
  static const Color statusLocked   = AegisColors.textTertiary;
  static const Color statusPending  = AegisColors.warning;
  static const Color statusCritical = AegisColors.danger;

  // ── Legacy Aliases ─────────────────────────────────────────
  static const Color clinicalBlue   = AegisColors.secondary;
  static const Color emeraldAccent  = AegisColors.success;
  static const Color amberWarning   = AegisColors.warning;
  static const Color crimsonLockout = AegisColors.danger;
  static const Color darkRimGray    = AegisColors.border;
  static const Color pearlFill      = AegisColors.surface;
  static const Color deepNavy       = AegisColors.textPrimary;
  static const Color gradientTeal   = AegisColors.secondary;
  static const Color gradientBlue   = AegisColors.primary;
  static const Color ambientBlue    = AegisColors.primarySurface;
  static const Color ambientGreen   = AegisColors.successLight;
  static const Color indigoDusk     = AegisColors.textPrimary;
  static const Color mutedTeal      = AegisColors.secondary;
}
