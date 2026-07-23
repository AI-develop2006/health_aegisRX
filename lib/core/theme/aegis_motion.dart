// ============================================================
// AegisRx Design System — Motion & Animation Guidelines
// ============================================================
// Principle: Motion should feel clinical — purposeful, fast,
// and never gratuitous. Easing curves express intent.
// ============================================================

import 'package:flutter/material.dart';

class AegisMotion {
  AegisMotion._();

  // ── Duration Scale ─────────────────────────────────────────
  static const Duration instant   = Duration(milliseconds: 0);
  static const Duration fastest   = Duration(milliseconds: 80);
  static const Duration fast      = Duration(milliseconds: 150);
  static const Duration moderate  = Duration(milliseconds: 250);
  static const Duration normal    = Duration(milliseconds: 350);
  static const Duration slow      = Duration(milliseconds: 500);
  static const Duration deliberate= Duration(milliseconds: 700);

  // ── Easing Curves ─────────────────────────────────────────
  // Standard: Default transitions (in & out)
  static const Curve standard    = Curves.easeInOut;

  // Decelerate: Elements entering the screen from off-screen
  static const Curve decelerate  = Curves.easeOutCubic;

  // Accelerate: Elements leaving the screen
  static const Curve accelerate  = Curves.easeInCubic;

  // Emphasized: High-attention transitions (danger alerts, success confirms)
  static const Curve emphasized  = Curves.easeOutBack;

  // Spring: Playful physical bounce for success states
  static const Curve spring      = Curves.elasticOut;

  // ── Transition Presets ─────────────────────────────────────
  // Fade + Slight Slide (page enter)
  static Route<T> fadeSlideRoute<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: normal,
      reverseTransitionDuration: fast,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final fade = CurvedAnimation(parent: animation, curve: decelerate);
        final slide = Tween<Offset>(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: decelerate));
        return FadeTransition(
          opacity: fade,
          child: SlideTransition(position: slide, child: child),
        );
      },
    );
  }

  // ── Stagger helpers ───────────────────────────────────────
  /// Returns interval for staggered list items.
  /// [index] = item index, [total] = total items in list.
  static Interval staggerInterval(int index, {int total = 8}) {
    final step = 1.0 / total.clamp(1, 20);
    final begin = (index * step).clamp(0.0, 0.9);
    final end   = (begin + step * 2).clamp(0.0, 1.0);
    return Interval(begin, end, curve: decelerate);
  }
}


// ── Icon Size System ──────────────────────────────────────
class AegisIconSize {
  AegisIconSize._();

  static const double xs   = 14.0; // inline text icons
  static const double sm   = 16.0; // chip icons
  static const double md   = 20.0; // list tile leading
  static const double base = 24.0; // navigation bar, appbar icons
  static const double lg   = 28.0; // section header icons
  static const double xl   = 32.0; // feature icons in cards
  static const double xxl  = 40.0; // empty state icons
  static const double hero = 64.0; // splash, onboarding illustrations
}
