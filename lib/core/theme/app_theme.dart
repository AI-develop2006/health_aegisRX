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

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.baseCanvas,
      fontFamily: 'Inter',
      colorScheme: const ColorScheme.light(
        primary: AppColors.patientBlue,
        secondary: AppColors.patientBlueDark,
        surface: AppColors.cardSurface,
        error: AppColors.statusCritical,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.cardSurface,
        foregroundColor: AppColors.primaryText,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.primaryText),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.patientBlue,
        selectionColor: Color(0x332563EB),
        selectionHandleColor: AppColors.patientBlue,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.primaryText,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Fallback property for backward compatibility
  static ThemeData get darkTheme => lightTheme;
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
          color: AppColors.borderWhite,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16.0),
        child: child,
      ),
    );
  }
}
