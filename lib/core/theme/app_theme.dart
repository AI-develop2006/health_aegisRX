// ============================================================
// AegisRx Design System — Main Theme Entry Point
// ============================================================
// Replaces the previous stub app_theme.dart.
// All portals (Patient, Doctor, Pharmacy) share this theme.
// Portal-specific identity is handled via ThemeExtensions.
//
// Usage in main.dart (already wired):
//   theme:     AegisTheme.light(),
//   darkTheme: AegisTheme.dark(),
//   themeMode: ThemeMode.system,
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'aegis_colors.dart';
import 'aegis_motion.dart';
import 'aegis_typography.dart';
import 'aegis_dimensions.dart';
import 'aegis_tokens.dart';
import 'aegis_extensions.dart';

// Public barrel — re-export all sub-files for convenience.
// Screens can do: import 'package:health_lock/core/theme/aegis_theme.dart';
// and get access to AegisColors, AegisTokens, AegisSpacing, etc.
export 'aegis_colors.dart';
export 'aegis_typography.dart';
export 'aegis_dimensions.dart';
export 'aegis_tokens.dart';
export 'aegis_extensions.dart';
export 'aegis_motion.dart';

class AegisTheme {
  AegisTheme._();

  // ─────────────────────────────────────────────────────────
  // LIGHT THEME — Clinical Precision
  // ─────────────────────────────────────────────────────────
  static ThemeData light() {
    final colorScheme = _lightColorScheme();
    return _build(colorScheme, brightness: Brightness.light);
  }

  // ─────────────────────────────────────────────────────────
  // DARK THEME — Clinical Dark Mode (future-ready)
  // ─────────────────────────────────────────────────────────
  static ThemeData dark() {
    final colorScheme = _darkColorScheme();
    return _build(colorScheme, brightness: Brightness.dark);
  }

  // ─────────────────────────────────────────────────────────
  // ColorScheme Builders
  // ─────────────────────────────────────────────────────────
  static ColorScheme _lightColorScheme() => const ColorScheme(
    brightness:         Brightness.light,
    // Primary — Royal Blue
    primary:            AegisColors.primary,
    onPrimary:          AegisColors.onPrimary,
    primaryContainer:   AegisColors.primarySurface,
    onPrimaryContainer: AegisColors.primaryDark,
    // Secondary — Medical Teal
    secondary:          AegisColors.secondary,
    onSecondary:        AegisColors.onSecondary,
    secondaryContainer: AegisColors.secondarySurface,
    onSecondaryContainer: AegisColors.secondaryDark,
    // Tertiary — AI/Blockchain Violet
    tertiary:           AegisColors.tertiary,
    onTertiary:         AegisColors.onTertiary,
    tertiaryContainer:  AegisColors.tertiarySurface,
    onTertiaryContainer: Color(0xFF3B0764),
    // Error — Medical Danger Red
    error:              AegisColors.danger,
    onError:            Color(0xFFFFFFFF),
    errorContainer:     AegisColors.dangerLight,
    onErrorContainer:   AegisColors.dangerDark,
    // Surfaces
    surface:            AegisColors.surface,
    onSurface:          AegisColors.textPrimary,
    surfaceContainerHighest: AegisColors.background,
    onSurfaceVariant:   AegisColors.textSecondary,
    // Others
    outline:            AegisColors.border,
    outlineVariant:     AegisColors.divider,
    inverseSurface:     AegisColors.inverseSurface,
    onInverseSurface:   AegisColors.textInverse,
    shadow:             Color(0x1A0B1C30),
    scrim:              Color(0x80000000),
  );

  static ColorScheme _darkColorScheme() => const ColorScheme(
    brightness:         Brightness.dark,
    primary:            Color(0xFF93C5FD),  // Blue 300
    onPrimary:          Color(0xFF003B8F),
    primaryContainer:   Color(0xFF1D4ED8),
    onPrimaryContainer: Color(0xFFDBEAFE),
    secondary:          Color(0xFF5EEAD4),  // Teal 300
    onSecondary:        Color(0xFF003B35),
    secondaryContainer: Color(0xFF0F766E),
    onSecondaryContainer: Color(0xFFCCFBF1),
    tertiary:           Color(0xFFC4B5FD),  // Violet 300
    onTertiary:         Color(0xFF2E1065),
    tertiaryContainer:  Color(0xFF5B21B6),
    onTertiaryContainer: Color(0xFFEDE9FE),
    error:              Color(0xFFFFB4AB),
    onError:            Color(0xFF690005),
    errorContainer:     Color(0xFF93000A),
    onErrorContainer:   Color(0xFFFFDAD6),
    surface:            Color(0xFF0F172A),
    onSurface:          Color(0xFFE2E8F0),
    surfaceContainerHighest: Color(0xFF1E293B),
    onSurfaceVariant:   Color(0xFF94A3B8),
    outline:            Color(0xFF334155),
    outlineVariant:     Color(0xFF1E293B),
    inverseSurface:     Color(0xFFCBD5E1),
    onInverseSurface:   Color(0xFF0F172A),
    shadow:             Color(0xFF000000),
    scrim:              Color(0xFF000000),
  );

  // ─────────────────────────────────────────────────────────
  // Core ThemeData Builder
  // ─────────────────────────────────────────────────────────
  static ThemeData _build(ColorScheme cs, {required Brightness brightness}) {
    final isLight = brightness == Brightness.light;

    // Status bar style
    final systemOverlay = SystemUiOverlayStyle(
      statusBarBrightness:          isLight ? Brightness.light : Brightness.dark,
      statusBarIconBrightness:      isLight ? Brightness.dark  : Brightness.light,
      statusBarColor:               Colors.transparent,
      systemNavigationBarColor:     isLight ? AegisColors.surface : const Color(0xFF0F172A),
      systemNavigationBarIconBrightness: isLight ? Brightness.dark : Brightness.light,
    );

    return ThemeData(
      useMaterial3:        true,
      brightness:          brightness,
      colorScheme:         cs,
      scaffoldBackgroundColor: isLight ? AegisColors.background : const Color(0xFF0B1120),

      // ── Typography ─────────────────────────────────────
      textTheme: AegisTypography.textTheme.apply(
        bodyColor:    cs.onSurface,
        displayColor: cs.onSurface,
      ),
      fontFamily: GoogleFonts.inter().fontFamily,

      // ── AppBar ─────────────────────────────────────────
      appBarTheme: AppBarTheme(
        systemOverlayStyle: systemOverlay,
        backgroundColor:    cs.surface,
        foregroundColor:    cs.onSurface,
        elevation:          0,
        scrolledUnderElevation: 1,
        shadowColor:        cs.shadow,
        surfaceTintColor:   Colors.transparent,
        iconTheme:          IconThemeData(color: cs.onSurface, size: AegisIconSize.base),
        titleTextStyle:     AegisTypography.headlineMedium.copyWith(color: cs.onSurface),
        centerTitle:        false,
        shape: const Border(
          bottom: BorderSide(color: AegisColors.border, width: 1),
        ),
      ),

      // ── Card ───────────────────────────────────────────
      cardTheme: CardThemeData(
        color:         cs.surface,
        elevation:     0,
        shadowColor:   Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AegisRadius.card,
          side: BorderSide(color: AegisColors.border, width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: AegisSpacing.sm),
      ),

      // ── Elevated Button ────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor:   cs.primary,
          foregroundColor:   cs.onPrimary,
          disabledBackgroundColor: AegisTokens.btnPrimaryDisabled,
          elevation:         0,
          shadowColor:       Colors.transparent,
          minimumSize:       const Size(0, AegisTokens.btnHeight),
          shape:             AegisRadius.buttonShape,
          padding: const EdgeInsets.symmetric(
            horizontal: AegisSpacing.lg,
            vertical: AegisSpacing.md,
          ),
          textStyle: AegisTypography.labelLarge.copyWith(letterSpacing: 0.2),
        ),
      ),

      // ── Outlined Button ────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: cs.primary,
          side:            BorderSide(color: cs.primary, width: AegisBorders.regular),
          minimumSize:     const Size(0, AegisTokens.btnHeight),
          shape:           AegisRadius.buttonShape,
          padding: const EdgeInsets.symmetric(
            horizontal: AegisSpacing.lg,
            vertical: AegisSpacing.md,
          ),
          textStyle: AegisTypography.labelLarge,
        ),
      ),

      // ── Text Button ────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: cs.primary,
          minimumSize: const Size(AegisSpacing.xxl, AegisTokens.btnHeightSm),
          shape: AegisRadius.buttonShape,
          padding: const EdgeInsets.symmetric(
            horizontal: AegisSpacing.base,
            vertical: AegisSpacing.sm,
          ),
          textStyle: AegisTypography.labelLarge,
        ),
      ),

      // ── Input Decoration ───────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled:         true,
        fillColor:      cs.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AegisSpacing.inputPaddingH,
          vertical:   AegisSpacing.inputPaddingV,
        ),
        border: OutlineInputBorder(
          borderRadius: AegisRadius.input,
          borderSide:   AegisBorders.defaultBorder,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AegisRadius.input,
          borderSide:   AegisBorders.defaultBorder,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AegisRadius.input,
          borderSide:   AegisBorders.focusBorder,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AegisRadius.input,
          borderSide:   AegisBorders.errorBorder,
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AegisRadius.input,
          borderSide:   AegisBorders.errorBorder,
        ),
        labelStyle:         AegisTypography.bodyMedium.copyWith(color: AegisColors.textSecondary),
        floatingLabelStyle: AegisTypography.labelMedium.copyWith(color: cs.primary),
        hintStyle:          AegisTypography.bodyMedium.copyWith(color: AegisColors.textTertiary),
        errorStyle:         AegisTypography.labelSmall.copyWith(color: AegisColors.danger),
        prefixIconColor:    AegisColors.textTertiary,
        suffixIconColor:    AegisColors.textTertiary,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
      ),

      // ── Chip ───────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor:    AegisTokens.chipNeutralBg,
        labelStyle:         AegisTypography.labelMedium.copyWith(color: AegisTokens.chipNeutralFg),
        side:               BorderSide.none,
        shape:              RoundedRectangleBorder(borderRadius: AegisRadius.chip),
        padding: const EdgeInsets.symmetric(
          horizontal: AegisTokens.chipPaddingH,
          vertical:   AegisTokens.chipPaddingV,
        ),
      ),

      // ── Bottom Sheet ───────────────────────────────────
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor:    AegisColors.surface,
        elevation:          0,
        shadowColor:        Colors.transparent,
        surfaceTintColor:   Colors.transparent,
        modalElevation:     0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AegisRadius.xxl),
          ),
        ),
      ),

      // ── Dialog ─────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor:  cs.surface,
        surfaceTintColor: Colors.transparent,
        elevation:        0,
        shape: RoundedRectangleBorder(borderRadius: AegisRadius.card),
        titleTextStyle: AegisTypography.headlineSmall.copyWith(color: cs.onSurface),
        contentTextStyle: AegisTypography.bodyMedium.copyWith(color: AegisColors.textSecondary),
      ),

      // ── Snack Bar ──────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AegisColors.inverseSurface,
        contentTextStyle: AegisTypography.bodySmall.copyWith(color: AegisColors.textInverse),
        shape: RoundedRectangleBorder(borderRadius: AegisRadius.button),
        behavior: SnackBarBehavior.floating,
        elevation: AegisElevation.toast,
      ),

      // ── Navigation Bar ─────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor:        cs.surface,
        indicatorColor:         AegisColors.primarySurface,
        indicatorShape:         const StadiumBorder(),
        labelTextStyle:         WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AegisTypography.labelSmall.copyWith(color: cs.primary);
          }
          return AegisTypography.labelSmall.copyWith(color: AegisColors.textTertiary);
        }),
        iconTheme:              WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: cs.primary, size: AegisIconSize.md);
          }
          return IconThemeData(color: AegisColors.textTertiary, size: AegisIconSize.md);
        }),
        elevation:              0,
        shadowColor:            Colors.transparent,
        surfaceTintColor:       Colors.transparent,
      ),

      // ── Divider ────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color:     AegisColors.divider,
        thickness: 1,
        space:     1,
      ),

      // ── List Tile ──────────────────────────────────────
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AegisSpacing.base,
          vertical:   AegisSpacing.xs,
        ),
        iconColor:  AegisColors.textSecondary,
        titleTextStyle:    AegisTypography.titleSmall.copyWith(color: cs.onSurface),
        subtitleTextStyle: AegisTypography.bodySmall.copyWith(color: AegisColors.textSecondary),
        shape: RoundedRectangleBorder(borderRadius: AegisRadius.input),
      ),

      // ── Progress Indicator ─────────────────────────────
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color:               cs.primary,
        circularTrackColor:  AegisColors.primarySurface,
        linearTrackColor:    AegisColors.primarySurface,
        linearMinHeight:     4,
      ),

      // ── Switch ─────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return cs.primary;
          return AegisColors.textTertiary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AegisColors.primarySurface;
          return AegisColors.divider;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),

      // ── Icon ───────────────────────────────────────────
      iconTheme: IconThemeData(
        color: cs.onSurface,
        size:  AegisIconSize.base,
      ),

      // ── Theme Extensions ───────────────────────────────
      extensions: const [
        AegisRiskTheme.defaultLight,
        AegisSurfaceTheme.defaultLight,
      ],
    );
  }
}

// ── Backwards compatibility shims ────────────────────────
// These keep the existing main.dart calls working without changes.
ThemeData buildLightTheme() => AegisTheme.light();
ThemeData buildDarkTheme()  => AegisTheme.light(); // dark parity future-ready
ThemeData buildAppTheme()   => AegisTheme.light();
