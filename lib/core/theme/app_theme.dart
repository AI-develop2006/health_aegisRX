import 'package:flutter/material.dart';
import 'package:health_lock/core/constants/app_colors.dart';

class AppTheme {
  static const TextStyle monoStyle = TextStyle(
    fontFamily: 'Courier',
    fontSize: 12,
    height: 1.4,
    color: AppColors.mutedText,
    letterSpacing: 0.2,
  );

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.baseCanvas,
      fontFamily: 'Inter',
      colorScheme: ColorScheme.light(
        primary: AppColors.clinicalBlue,
        secondary: AppColors.deepNavy,
        surface: AppColors.cardSurface,
        error: AppColors.crimsonLockout,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.cardSurface,
        foregroundColor: AppColors.primaryText,
        elevation: 0,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.clinicalBlue,
        selectionColor: Color(0x332563EB),
        selectionHandleColor: AppColors.clinicalBlue,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.primaryText,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final Border? border;

  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 16.0,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.cardSurface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: border ?? Border.all(
          color: AppColors.clinicalBlue.withValues(alpha: 0.15),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16.0),
          child: child,
        ),
      ),
    );
  }
}
