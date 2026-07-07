import 'package:flutter/material.dart';

class AppColors {
  // ── Canvas & Surfaces (60% Dominant) ─────────────────────────
  static const Color baseCanvas = Color(0xFFF7F4EB);         // Cream Canvas Background
  static const Color cardSurface = Color(0xFFFFFFFF);        // Pure White Cards
  static const Color surfaceMuted = Color(0xFFFAF9F5);       // Soft Canvas Muted
  static const Color borderWhite = Color(0xFFB88E74);        // Brushed Copper Border (30%)

  // ── Typography & Structure (30% Secondary) ────────────────────
  static const Color primaryText = Color(0xFF4A3325);        // Deep Matte Bronze (Text/Headings)
  static const Color mutedText = Color(0xFFD4A387);          // Soft Rose Gold (Accent labels/subtitles)
  static const Color textFaint = Color(0xFFE6DCD2);          // Very soft warm grey-bronze

  // ── Role Accent Colors & States (10% Accent) ──────────────────
  static const Color patientBlue = Color(0xFF2E8B90);        // Deep Medical Teal (Done/Safe)
  static const Color patientBlueDark = Color(0xFF1E5F62);    // Medical Teal Dark
  static const Color doctorTeal = Color(0xFF2E8B90);         // Deep Medical Teal
  static const Color pharmacyViolet = Color(0xFFB88E74);     // Brushed Copper
  static const Color verifiedEmerald = Color(0xFF2E8B90);    // Deep Medical Teal

  // ── Tint Backgrounds ──────────────────────────────────────────
  static const Color tintBlue = Color(0xFFEAF5F5);           // Soft Teal Tint
  static const Color tintTeal = Color(0xFFEAF5F5);          // Soft Teal Tint
  static const Color tintViolet = Color(0xFFFDFBF7);         // Soft Copper Tint
  static const Color tintEmerald = Color(0xFFEAF5F5);        // Soft Teal Tint
  static const Color tintSlate = Color(0xFFFAF9F5);          // Soft Canvas Tint

  // ── Status Colors ─────────────────────────────────────────────
  static const Color statusLocked = Color(0xFFB88E74);       // Brushed Copper (Locked)
  static const Color statusPending = Color(0xFFD97736);      // Warm Amber Copper (Warning)
  static const Color statusCritical = Color(0xFFB33A3A);     // Burgundy Red (Critical)

  // ── Legacy Aliases & Safety Fallbacks ─────────────────────────
  static const Color clinicalBlue = Color(0xFF2E8B90);
  static const Color emeraldAccent = Color(0xFF2E8B90);
  static const Color amberWarning = Color(0xFFD97736);
  static const Color crimsonLockout = Color(0xFFB33A3A);
  static const Color darkRimGray = Color(0xFFB88E74);
  static const Color pearlFill = Color(0xFFFFFFFF);
  static const Color deepNavy = Color(0xFF4A3325);
  static const Color gradientTeal = Color(0xFF2E8B90);
  static const Color gradientBlue = Color(0xFF2E8B90);
  static const Color ambientBlue = Color(0xFFEAF5F5);
  static const Color ambientGreen = Color(0xFFEAF5F5);
  static const Color indigoDusk = Color(0xFF4A3325);
  static const Color mutedTeal = Color(0xFF2E8B90);
}
