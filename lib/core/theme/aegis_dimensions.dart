// ============================================================
// AegisRx Design System — Spacing, Radius & Elevation
// ============================================================

// ── Spacing Scale ─────────────────────────────────────────
// 4-point base grid. All layout gaps, padding, margin must
// be multiples of 4. Clinical density: tighter than consumer apps.
import 'package:flutter/material.dart';
// ─────────────────────────────────────────────────────────
class AegisSpacing {
  AegisSpacing._();

  static const double px2  = 2.0;
  static const double px4  = 4.0;
  static const double px6  = 6.0;
  static const double px8  = 8.0;
  static const double px10 = 10.0;
  static const double px12 = 12.0;
  static const double px14 = 14.0;
  static const double px16 = 16.0;
  static const double px20 = 20.0;
  static const double px24 = 24.0;
  static const double px28 = 28.0;
  static const double px32 = 32.0;
  static const double px40 = 40.0;
  static const double px48 = 48.0;
  static const double px56 = 56.0;
  static const double px64 = 64.0;

  // Named aliases for semantic clarity
  static const double xs   = px4;    // chip padding, icon gap
  static const double sm   = px8;    // inner card padding
  static const double md   = px12;   // form field vertical padding
  static const double base = px16;   // standard content padding
  static const double lg   = px24;   // section padding
  static const double xl   = px32;   // screen-level padding
  static const double xxl  = px48;   // hero spacing

  // Consistent page-level horizontal padding
  static const double pagePadding = px24;

  // Standard card internal padding
  static const double cardPaddingH = px20;
  static const double cardPaddingV = px16;

  // Form field vertical padding
  static const double inputPaddingV = px14;
  static const double inputPaddingH = px16;

  // Bottom safe area guard
  static const double safeBottom = px24;
}


// ── Radius Scale ──────────────────────────────────────────
// Consistent corner radii. Clinical apps use moderate rounding:
// sharp enough to feel precise, soft enough to feel approachable.
// ─────────────────────────────────────────────────────────


class AegisRadius {
  AegisRadius._();

  static const double none   = 0.0;
  static const double xs     = 4.0;   // small chips, tabs
  static const double sm     = 8.0;   // input borders
  static const double md     = 12.0;  // buttons
  static const double lg     = 16.0;  // cards
  static const double xl     = 20.0;  // large cards
  static const double xxl    = 24.0;  // bottom sheets, modals
  static const double full   = 999.0; // pill-shaped badges

  // Standard shape helpers
  static BorderRadius get card   => BorderRadius.circular(lg);
  static BorderRadius get button => BorderRadius.circular(md);
  static BorderRadius get input  => BorderRadius.circular(sm);
  static BorderRadius get chip   => BorderRadius.circular(full);
  static BorderRadius get modal  => const BorderRadius.vertical(top: Radius.circular(xxl));
  static BorderRadius get badge  => BorderRadius.circular(xs);

  // Shape descriptors
  static RoundedRectangleBorder get cardShape   => RoundedRectangleBorder(borderRadius: card);
  static RoundedRectangleBorder get buttonShape => RoundedRectangleBorder(borderRadius: button);
  static RoundedRectangleBorder get inputShape  => RoundedRectangleBorder(borderRadius: input);
}


// ── Elevation System ──────────────────────────────────────
// Material 3 tonal elevation levels. Each level maps to a
// shadow config + surface tint opacity.
// ─────────────────────────────────────────────────────────
class AegisElevation {
  AegisElevation._();

  static const double none    = 0.0;  // Flat containers
  static const double surface = 1.0;  // Default card surface
  static const double raised  = 2.0;  // Hover state
  static const double overlay = 4.0;  // Dialogs, floating panels
  static const double modal   = 8.0;  // Bottom sheets
  static const double toast   = 16.0; // Floating snackbar / toast
}


// ── Shadow System ─────────────────────────────────────────
class AegisShadows {
  AegisShadows._();

  // Level 0 — no shadow, flat component
  static const List<BoxShadow> none = [];

  // Level 1 — subtle card lift (default for content cards)
  static const List<BoxShadow> sm = [
    BoxShadow(
      color: Color(0x0A0B1C30),
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
    BoxShadow(
      color: Color(0x060B1C30),
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
  ];

  // Level 2 — card hover / raised state
  static const List<BoxShadow> md = [
    BoxShadow(
      color: Color(0x140B1C30),
      blurRadius: 12,
      offset: Offset(0, 4),
      spreadRadius: -2,
    ),
    BoxShadow(
      color: Color(0x0A0B1C30),
      blurRadius: 6,
      offset: Offset(0, 2),
    ),
  ];

  // Level 3 — dialogs, floating panels
  static const List<BoxShadow> lg = [
    BoxShadow(
      color: Color(0x1A0B1C30),
      blurRadius: 24,
      offset: Offset(0, 8),
      spreadRadius: -4,
    ),
    BoxShadow(
      color: Color(0x0C0B1C30),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  // Level 4 — modals, bottom sheets
  static const List<BoxShadow> xl = [
    BoxShadow(
      color: Color(0x240B1C30),
      blurRadius: 40,
      offset: Offset(0, 16),
      spreadRadius: -8,
    ),
    BoxShadow(
      color: Color(0x120B1C30),
      blurRadius: 20,
      offset: Offset(0, 8),
    ),
  ];

  // Primary colored glow — for active CTA buttons
  static const List<BoxShadow> primaryGlow = [
    BoxShadow(
      color: Color(0x402563EB),
      blurRadius: 16,
      offset: Offset(0, 4),
      spreadRadius: -2,
    ),
  ];

  // Success glow — for verified / safe states
  static const List<BoxShadow> successGlow = [
    BoxShadow(
      color: Color(0x3316A34A),
      blurRadius: 12,
      offset: Offset(0, 4),
      spreadRadius: -2,
    ),
  ];

  // Danger glow — for critical alerts and danger buttons
  static const List<BoxShadow> dangerGlow = [
    BoxShadow(
      color: Color(0x40BA1A1A),
      blurRadius: 12,
      offset: Offset(0, 4),
      spreadRadius: -2,
    ),
  ];
}


// ── Border Styles ─────────────────────────────────────────
class AegisBorders {
  AegisBorders._();

  static const double thin    = 1.0;
  static const double regular = 1.5;
  static const double thick   = 2.0;

  static BorderSide get defaultBorder => const BorderSide(
    color: Color(0xFFE2E8F0),
    width: thin,
  );

  static BorderSide get focusBorder => const BorderSide(
    color: Color(0xFF2563EB),
    width: regular,
  );

  static BorderSide get errorBorder => const BorderSide(
    color: Color(0xFFBA1A1A),
    width: regular,
  );

  static BorderSide get successBorder => const BorderSide(
    color: Color(0xFF16A34A),
    width: thin,
  );

  static Border get card => const Border.fromBorderSide(BorderSide(
    color: Color(0xFFE2E8F0),
    width: thin,
  ));

  static Border get highlight => const Border.fromBorderSide(BorderSide(
    color: Color(0xFF2563EB),
    width: regular,
  ));
}
