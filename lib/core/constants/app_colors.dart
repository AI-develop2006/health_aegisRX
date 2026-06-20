import 'package:flutter/material.dart';

class AppColors {
  // ── Background & Surface ──────────────────────────────────────
  static const Color baseCanvas = Color(0xFFF0F4F8);       // Soft cool gray
  static const Color cardSurface = Color(0xFFFFFFFF);       // Pure white cards
  static const Color deepNavy = Color(0xFF1E40AF);          // Deep blue for headers

  // ── Borders & Fills ───────────────────────────────────────────
  static const Color pearlFill = Color(0xFFFFFFFF);         // White card fill
  static const Color borderWhite = Color(0xFFE2E8F0);       // Slate-200 borders
  static const Color darkRimGray = Color(0xFFF1F5F9);       // Slate-100 subtle rim

  // ── Typography ────────────────────────────────────────────────
  static const Color primaryText = Color(0xFF1E293B);       // Slate-800 (dark text)
  static const Color mutedText = Color(0xFF64748B);         // Slate-500 (secondary)

  // ── Accent & Status ───────────────────────────────────────────
  static const Color clinicalBlue = Color(0xFF2563EB);      // Primary clinical blue
  static const Color emeraldAccent = Color(0xFF059669);     // Success / verified green
  static const Color amberWarning = Color(0xFFD97706);      // Warning amber
  static const Color crimsonLockout = Color(0xFFDC2626);    // Danger / alert red

  // ── Ambient Gradient Blobs ────────────────────────────────────
  static const Color ambientBlue = Color(0xFFDBEAFE);       // Blue-100 ambient
  static const Color ambientGreen = Color(0xFFD1FAE5);      // Emerald-100 ambient

  // ── Legacy aliases (keep references working) ──────────────────
  static const Color indigoDusk = deepNavy;
  static const Color mutedTeal = Color(0xFF0D9488);         // Teal-600 for accents
}
