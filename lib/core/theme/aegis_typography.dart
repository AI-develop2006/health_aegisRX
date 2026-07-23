// ============================================================
// AegisRx Design System — Typography Scale
// Font: Inter (UI) · Geist Mono (Data/Code)
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AegisTypography {
  AegisTypography._();

  // ── Base Font Families ────────────────────────────────────
  // _sans is 'Inter' — applied via GoogleFonts.inter() calls directly below
  static const String _mono = 'GeistMono'; // For hashes, IDs, clinical codes

  // ── Font Size Scale (px) ──────────────────────────────────
  static const double _size10 = 10.0;
  static const double _size11 = 11.0;
  static const double _size12 = 12.0;
  static const double _size13 = 13.0;
  static const double _size14 = 14.0;
  static const double _size15 = 15.0;
  static const double _size16 = 16.0;
  static const double _size18 = 18.0;
  static const double _size20 = 20.0;
  static const double _size22 = 22.0;
  static const double _size24 = 24.0;
  static const double _size28 = 28.0;
  static const double _size32 = 32.0;

  // ── Line Heights ───────────────────────────────────────────
  static const double _lineNone   = 1.0;
  static const double _lineTight  = 1.15;
  static const double _lineNormal = 1.4;
  static const double _lineRelax  = 1.6;

  // ── Letter Spacing ─────────────────────────────────────────
  static const double _trackingTight  = -0.3;
  static const double _trackingNormal =  0.0;
  static const double _trackingWide   =  0.5;
  static const double _trackingWidest =  1.0;  // label-caps

  // ─────────────────────────────────────────────────────────
  // DISPLAY — Hero numbers, large stats, medication dosage
  // ─────────────────────────────────────────────────────────
  static TextStyle get displayLarge => GoogleFonts.inter(
    fontSize: _size32,
    fontWeight: FontWeight.w800,
    letterSpacing: _trackingTight,
    height: _lineNone,
  );

  static TextStyle get displayMedium => GoogleFonts.inter(
    fontSize: _size28,
    fontWeight: FontWeight.w700,
    letterSpacing: _trackingTight,
    height: _lineTight,
  );

  static TextStyle get displaySmall => GoogleFonts.inter(
    fontSize: _size24,
    fontWeight: FontWeight.w700,
    letterSpacing: _trackingTight,
    height: _lineTight,
  );

  // ─────────────────────────────────────────────────────────
  // HEADLINE — Screen titles, section headers
  // ─────────────────────────────────────────────────────────
  static TextStyle get headlineLarge => GoogleFonts.inter(
    fontSize: _size22,
    fontWeight: FontWeight.w700,
    letterSpacing: _trackingTight,
    height: _lineTight,
  );

  static TextStyle get headlineMedium => GoogleFonts.inter(
    fontSize: _size20,
    fontWeight: FontWeight.w700,
    letterSpacing: _trackingNormal,
    height: _lineTight,
  );

  static TextStyle get headlineSmall => GoogleFonts.inter(
    fontSize: _size18,
    fontWeight: FontWeight.w600,
    letterSpacing: _trackingNormal,
    height: _lineNormal,
  );

  // ─────────────────────────────────────────────────────────
  // TITLE — Card headers, form section titles
  // ─────────────────────────────────────────────────────────
  static TextStyle get titleLarge => GoogleFonts.inter(
    fontSize: _size16,
    fontWeight: FontWeight.w600,
    letterSpacing: _trackingNormal,
    height: _lineNormal,
  );

  static TextStyle get titleMedium => GoogleFonts.inter(
    fontSize: _size15,
    fontWeight: FontWeight.w600,
    letterSpacing: _trackingNormal,
    height: _lineNormal,
  );

  static TextStyle get titleSmall => GoogleFonts.inter(
    fontSize: _size14,
    fontWeight: FontWeight.w600,
    letterSpacing: _trackingNormal,
    height: _lineNormal,
  );

  // ─────────────────────────────────────────────────────────
  // BODY — General reading text
  // ─────────────────────────────────────────────────────────
  static TextStyle get bodyLarge => GoogleFonts.inter(
    fontSize: _size16,
    fontWeight: FontWeight.w400,
    letterSpacing: _trackingNormal,
    height: _lineRelax,
  );

  static TextStyle get bodyMedium => GoogleFonts.inter(
    fontSize: _size14,
    fontWeight: FontWeight.w400,
    letterSpacing: _trackingNormal,
    height: _lineRelax,
  );

  static TextStyle get bodySmall => GoogleFonts.inter(
    fontSize: _size13,
    fontWeight: FontWeight.w400,
    letterSpacing: _trackingNormal,
    height: _lineRelax,
  );

  // ─────────────────────────────────────────────────────────
  // LABEL — Chips, badges, metadata tags
  // ─────────────────────────────────────────────────────────
  static TextStyle get labelLarge => GoogleFonts.inter(
    fontSize: _size13,
    fontWeight: FontWeight.w600,
    letterSpacing: _trackingWidest,
    height: _lineNone,
  );

  static TextStyle get labelMedium => GoogleFonts.inter(
    fontSize: _size12,
    fontWeight: FontWeight.w600,
    letterSpacing: _trackingWide,
    height: _lineNone,
  );

  static TextStyle get labelSmall => GoogleFonts.inter(
    fontSize: _size11,
    fontWeight: FontWeight.w500,
    letterSpacing: _trackingWide,
    height: _lineNone,
  );

  static TextStyle get labelCaps => GoogleFonts.inter(
    fontSize: _size10,
    fontWeight: FontWeight.w700,
    letterSpacing: _trackingWidest,
    height: _lineNone,
  ).copyWith(fontFeatures: [const FontFeature.enable('smcp')]);

  // ─────────────────────────────────────────────────────────
  // MONO — Blockchain hashes, Rx IDs, clinical codes
  // ─────────────────────────────────────────────────────────
  static TextStyle get monoMedium => TextStyle(
    fontFamily: _mono,
    fontSize: _size12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.3,
    height: _lineNormal,
    fontFamilyFallback: const ['Courier New', 'monospace'],
  );

  static TextStyle get monoSmall => TextStyle(
    fontFamily: _mono,
    fontSize: _size11,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
    height: _lineNormal,
    fontFamilyFallback: const ['Courier New', 'monospace'],
  );

  static TextStyle get monoLarge => TextStyle(
    fontFamily: _mono,
    fontSize: _size20,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
    height: _lineNormal,
    fontFamilyFallback: const ['Courier New', 'monospace'],
  );

  static TextStyle get monoXL => TextStyle(
    fontFamily: _mono,
    fontSize: _size24,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
    height: _lineNormal,
    fontFamilyFallback: const ['Courier New', 'monospace'],
  );

  // ─────────────────────────────────────────────────────────
  // Build TextTheme for MaterialApp
  // ─────────────────────────────────────────────────────────
  static TextTheme get textTheme => TextTheme(
    displayLarge:   displayLarge,
    displayMedium:  displayMedium,
    displaySmall:   displaySmall,
    headlineLarge:  headlineLarge,
    headlineMedium: headlineMedium,
    headlineSmall:  headlineSmall,
    titleLarge:     titleLarge,
    titleMedium:    titleMedium,
    titleSmall:     titleSmall,
    bodyLarge:      bodyLarge,
    bodyMedium:     bodyMedium,
    bodySmall:      bodySmall,
    labelLarge:     labelLarge,
    labelMedium:    labelMedium,
    labelSmall:     labelSmall,
  );
}
