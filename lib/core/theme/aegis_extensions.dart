// ============================================================
// AegisRx Design System — Theme Extensions
// ============================================================
// ThemeExtension provides typed, context-accessible theme data
// beyond what Material ThemeData supports natively.
// Usage: Theme.of(context).extension<AegisThemeExt>()!
// ============================================================

import 'package:flutter/material.dart';
import 'aegis_colors.dart';
import 'aegis_tokens.dart';
import 'aegis_dimensions.dart';

// ── Risk Level Extension ──────────────────────────────────
@immutable
class AegisRiskTheme extends ThemeExtension<AegisRiskTheme> {
  const AegisRiskTheme({
    required this.low,
    required this.moderate,
    required this.high,
    required this.critical,
  });

  final Color low;
  final Color moderate;
  final Color high;
  final Color critical;

  Color forScore(int score) {
    if (score < 30) return low;
    if (score < 60) return moderate;
    if (score < 80) return high;
    return critical;
  }

  String labelForScore(int score) {
    if (score < 30) return 'LOW';
    if (score < 60) return 'MODERATE';
    if (score < 80) return 'HIGH';
    return 'CRITICAL';
  }

  @override
  AegisRiskTheme copyWith({
    Color? low,
    Color? moderate,
    Color? high,
    Color? critical,
  }) =>
      AegisRiskTheme(
        low: low ?? this.low,
        moderate: moderate ?? this.moderate,
        high: high ?? this.high,
        critical: critical ?? this.critical,
      );

  @override
  AegisRiskTheme lerp(AegisRiskTheme? other, double t) {
    if (other is! AegisRiskTheme) return this;
    return AegisRiskTheme(
      low:      Color.lerp(low, other.low, t)!,
      moderate: Color.lerp(moderate, other.moderate, t)!,
      high:     Color.lerp(high, other.high, t)!,
      critical: Color.lerp(critical, other.critical, t)!,
    );
  }

  static const defaultLight = AegisRiskTheme(
    low:      AegisTokens.riskLow,
    moderate: AegisTokens.riskModerate,
    high:     AegisTokens.riskHigh,
    critical: AegisTokens.riskCritical,
  );
}


// ── Portal Identity Extension ─────────────────────────────
// Provides portal-specific accent without changing global theme
@immutable
class AegisPortalTheme extends ThemeExtension<AegisPortalTheme> {
  const AegisPortalTheme({
    required this.accentColor,
    required this.accentSurface,
    required this.portalName,
    required this.portalIcon,
  });

  final Color accentColor;
  final Color accentSurface;
  final String portalName;
  final IconData portalIcon;

  @override
  AegisPortalTheme copyWith({
    Color? accentColor,
    Color? accentSurface,
    String? portalName,
    IconData? portalIcon,
  }) =>
      AegisPortalTheme(
        accentColor:   accentColor   ?? this.accentColor,
        accentSurface: accentSurface ?? this.accentSurface,
        portalName:    portalName    ?? this.portalName,
        portalIcon:    portalIcon    ?? this.portalIcon,
      );

  @override
  AegisPortalTheme lerp(AegisPortalTheme? other, double t) {
    if (other is! AegisPortalTheme) return this;
    return AegisPortalTheme(
      accentColor:   Color.lerp(accentColor, other.accentColor, t)!,
      accentSurface: Color.lerp(accentSurface, other.accentSurface, t)!,
      portalName:    other.portalName,
      portalIcon:    other.portalIcon,
    );
  }

  // Predefined portal themes
  static const patient = AegisPortalTheme(
    accentColor:   AegisColors.patientAccent,
    accentSurface: AegisColors.primarySurface,
    portalName:    'Patient',
    portalIcon:    Icons.person_outline_rounded,
  );

  static const doctor = AegisPortalTheme(
    accentColor:   AegisColors.doctorAccent,
    accentSurface: AegisColors.secondarySurface,
    portalName:    'Doctor',
    portalIcon:    Icons.medical_services_outlined,
  );

  static const pharmacy = AegisPortalTheme(
    accentColor:   AegisColors.pharmacyAccent,
    accentSurface: AegisColors.tertiarySurface,
    portalName:    'Pharmacy',
    portalIcon:    Icons.local_pharmacy_outlined,
  );
}


// ── Clinical Surface Extension ────────────────────────────
// Provides named surface levels for clinical data hierarchy
@immutable
class AegisSurfaceTheme extends ThemeExtension<AegisSurfaceTheme> {
  const AegisSurfaceTheme({
    required this.page,
    required this.card,
    required this.overlay,
    required this.badge,
    required this.input,
    required this.skeleton,
  });

  final Color page;
  final Color card;
  final Color overlay;
  final Color badge;
  final Color input;
  final Color skeleton;

  @override
  AegisSurfaceTheme copyWith({
    Color? page, Color? card, Color? overlay,
    Color? badge, Color? input, Color? skeleton,
  }) =>
      AegisSurfaceTheme(
        page:     page     ?? this.page,
        card:     card     ?? this.card,
        overlay:  overlay  ?? this.overlay,
        badge:    badge    ?? this.badge,
        input:    input    ?? this.input,
        skeleton: skeleton ?? this.skeleton,
      );

  @override
  AegisSurfaceTheme lerp(AegisSurfaceTheme? other, double t) {
    if (other is! AegisSurfaceTheme) return this;
    return AegisSurfaceTheme(
      page:     Color.lerp(page, other.page, t)!,
      card:     Color.lerp(card, other.card, t)!,
      overlay:  Color.lerp(overlay, other.overlay, t)!,
      badge:    Color.lerp(badge, other.badge, t)!,
      input:    Color.lerp(input, other.input, t)!,
      skeleton: Color.lerp(skeleton, other.skeleton, t)!,
    );
  }

  static const defaultLight = AegisSurfaceTheme(
    page:     AegisColors.background,
    card:     AegisColors.surface,
    overlay:  AegisColors.surfaceOverlay,
    badge:    AegisColors.surfaceDim,
    input:    AegisColors.surface,
    skeleton: AegisTokens.skeletonBase,
  );
}
