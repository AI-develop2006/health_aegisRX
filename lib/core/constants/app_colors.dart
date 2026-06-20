import 'package:flutter/material.dart';

class AppColors {
  // ── Canvas & Surfaces ─────────────────────────────────────────
  static const Color baseCanvas = Color(0xFFF4F6F9);         // --canvas
  static const Color cardSurface = Color(0xFFFFFFFF);        // --surface
  static const Color surfaceMuted = Color(0xFFF1F5F9);       // --surface-muted
  static const Color borderWhite = Color(0xFFE4E9F0);        // --border (reused naming to prevent breaks)

  // ── Typography ────────────────────────────────────────────────
  static const Color primaryText = Color(0xFF0F172A);        // --text-primary
  static const Color mutedText = Color(0xFF64748B);          // --text-muted
  static const Color textFaint = Color(0xFF94A3B8);          // --text-faint

  // ── Role Accent Colors ─────────────────────────────────────────
  static const Color patientBlue = Color(0xFF2563EB);        // --patient-blue
  static const Color patientBlueDark = Color(0xFF1D4ED8);    // --patient-blue-dark
  static const Color doctorTeal = Color(0xFF0D9488);          // --doctor-teal
  static const Color pharmacyViolet = Color(0xFF7C3AED);      // --pharmacy-violet
  static const Color verifiedEmerald = Color(0xFF059669);    // --verified-emerald

  // ── Tint Backgrounds ──────────────────────────────────────────
  static const Color tintBlue = Color(0xFFE8F0FE);           // --tint-blue
  static const Color tintTeal = Color(0xFFF0FDFA);           // --tint-teal
  static const Color tintViolet = Color(0xFFF3F0FE);         // --tint-violet
  static const Color tintEmerald = Color(0xFFECFDF5);        // --tint-emerald
  static const Color tintSlate = Color(0xFFF1F5F9);          // --tint-slate

  // ── Status Colors ─────────────────────────────────────────────
  static const Color statusLocked = Color(0xFF94A3B8);       // --status-locked
  static const Color statusPending = Color(0xFFD97706);      // --status-pending
  static const Color statusCritical = Color(0xFFDC2626);     // --status-critical

  // ── Legacy Aliases & Safety Fallbacks ─────────────────────────
  static const Color clinicalBlue = patientBlue;             // For references to clinicalBlue
  static const Color emeraldAccent = verifiedEmerald;        // For references to emeraldAccent
  static const Color amberWarning = statusPending;           // For references to amberWarning
  static const Color crimsonLockout = statusCritical;         // For references to crimsonLockout
  static const Color darkRimGray = borderWhite;              // Fallback
  static const Color pearlFill = surfaceMuted;               // Fallback
  static const Color deepNavy = patientBlueDark;             // Fallback
  static const Color gradientTeal = doctorTeal;              // Fallback
  static const Color gradientBlue = patientBlue;             // Fallback
  static const Color ambientBlue = tintBlue;                 // Fallback
  static const Color ambientGreen = tintTeal;                // Fallback
  static const Color indigoDusk = patientBlueDark;           // Fallback
  static const Color mutedTeal = doctorTeal;                 // Fallback
}
