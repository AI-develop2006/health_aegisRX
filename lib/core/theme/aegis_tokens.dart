// ============================================================
// AegisRx Design System — Component Tokens
// ============================================================
// Semantic component-level decisions that reference primitive
// tokens. Screens should consume these, not raw hex values.
// ============================================================

import 'package:flutter/material.dart';
import 'aegis_colors.dart';
import 'aegis_dimensions.dart';

class AegisTokens {
  AegisTokens._();

  // ── App Bar ───────────────────────────────────────────────
  static const Color appBarBackground   = AegisColors.surface;
  static const Color appBarForeground   = AegisColors.textPrimary;
  static const double appBarElevation   = 0.0;
  static const double appBarBorderWidth = 1.0;
  static const Color appBarBorderColor  = AegisColors.border;

  // ── Primary Button ────────────────────────────────────────
  static const Color btnPrimaryBg       = AegisColors.primary;
  static const Color btnPrimaryFg       = AegisColors.onPrimary;
  static const Color btnPrimaryHover    = AegisColors.primaryDark;
  static const Color btnPrimaryDisabled = Color(0xFFBFD3F7);
  static const double btnHeight         = 52.0;
  static const double btnHeightSm       = 40.0;
  static const double btnRadius         = AegisRadius.md;

  // ── Secondary Button (outlined) ───────────────────────────
  static const Color btnSecondaryBg     = Colors.transparent;
  static const Color btnSecondaryBorder = AegisColors.primary;
  static const Color btnSecondaryFg     = AegisColors.primary;

  // ── Danger Button ─────────────────────────────────────────
  static const Color btnDangerBg        = AegisColors.danger;
  static const Color btnDangerFg        = Color(0xFFFFFFFF);
  static const Color btnDangerHover     = AegisColors.dangerDark;

  // ── Ghost Button ──────────────────────────────────────────
  static const Color btnGhostFg         = AegisColors.textSecondary;
  static const Color btnGhostHoverBg    = AegisColors.surfaceDim;

  // ── Input Field ───────────────────────────────────────────
  static const Color inputBg            = AegisColors.surface;
  static const Color inputBorder        = AegisColors.border;
  static const Color inputBorderFocus   = AegisColors.primary;
  static const Color inputBorderError   = AegisColors.danger;
  static const Color inputLabel         = AegisColors.textSecondary;
  static const Color inputLabelFocus    = AegisColors.primary;
  static const Color inputText          = AegisColors.textPrimary;
  static const Color inputHint          = AegisColors.textTertiary;
  static const Color inputIconColor     = AegisColors.textTertiary;
  static const double inputRadius       = AegisRadius.sm;
  static const double inputBorderWidth  = 1.5;

  // ── Card ──────────────────────────────────────────────────
  static const Color cardBg             = AegisColors.surface;
  static const Color cardBorder         = AegisColors.border;
  static const double cardRadius        = AegisRadius.lg;
  static const double cardPaddingH      = AegisSpacing.cardPaddingH;
  static const double cardPaddingV      = AegisSpacing.cardPaddingV;

  // ── Chip / Badge ──────────────────────────────────────────
  static const double chipRadius        = AegisRadius.full;
  static const double chipPaddingH      = AegisSpacing.px12;
  static const double chipPaddingV      = AegisSpacing.px4;

  // Semantic chip colors
  static const Color chipSuccessBg      = AegisColors.successLight;
  static const Color chipSuccessFg      = AegisColors.successDark;
  static const Color chipDangerBg       = AegisColors.dangerLight;
  static const Color chipDangerFg       = AegisColors.dangerDark;
  static const Color chipWarningBg      = AegisColors.warningLight;
  static const Color chipWarningFg      = AegisColors.warningDark;
  static const Color chipInfoBg         = AegisColors.infoLight;
  static const Color chipInfoFg         = AegisColors.info;
  static const Color chipAiBg           = AegisColors.tertiarySurface;
  static const Color chipAiFg           = AegisColors.tertiary;
  static const Color chipNeutralBg      = Color(0xFFF1F5F9);
  static const Color chipNeutralFg      = AegisColors.textSecondary;

  // ── Bottom Sheet ──────────────────────────────────────────
  static const Color sheetBg           = AegisColors.surface;
  static const double sheetRadius      = AegisRadius.xxl;
  static const Color sheetHandle       = AegisColors.border;
  static const double sheetHandleW     = 40.0;
  static const double sheetHandleH     = 4.0;

  // ── Dialog ────────────────────────────────────────────────
  static const Color dialogBg          = AegisColors.surface;
  static const double dialogRadius     = AegisRadius.xl;
  static const double dialogPaddingH   = AegisSpacing.px24;
  static const double dialogPaddingV   = AegisSpacing.px20;

  // ── Divider ───────────────────────────────────────────────
  static const Color dividerColor      = AegisColors.divider;
  static const double dividerThickness = 1.0;

  // ── Navigation Bar ────────────────────────────────────────
  static const Color navBg             = AegisColors.surface;
  static const Color navSelected       = AegisColors.primary;
  static const Color navUnselected     = AegisColors.textTertiary;
  static const Color navIndicator      = AegisColors.primarySurface;

  // ── Risk / Status Indicator Colors ───────────────────────
  // Used by RiskGauge, AuditBadge, StatusBadge across portals
  static const Color riskLow           = AegisColors.success;
  static const Color riskModerate      = AegisColors.warning;
  static const Color riskHigh          = Color(0xFFEA580C); // Orange
  static const Color riskCritical      = AegisColors.danger;

  // ── AI & Blockchain Indicators ───────────────────────────
  static const Color aiIndicatorBg     = AegisColors.tertiarySurface;
  static const Color aiIndicatorFg     = AegisColors.tertiary;
  static const Color blockchainBadgeBg = Color(0xFFF0F9FF);
  static const Color blockchainBadgeFg = Color(0xFF0369A1);

  // ── Skeleton / Loading ────────────────────────────────────
  static const Color skeletonBase      = Color(0xFFE2E8F0);
  static const Color skeletonHighlight = Color(0xFFF8FAFC);

  // ── Toast / Snackbar ─────────────────────────────────────
  static const Color toastBg           = AegisColors.inverseSurface;
  static const Color toastFg           = AegisColors.textInverse;
  static const Color toastSuccessBg    = Color(0xFF14532D);
  static const Color toastErrorBg      = AegisColors.dangerDark;
}
