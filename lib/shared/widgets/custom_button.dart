import 'package:flutter/material.dart';
import 'package:health_lock/core/constants/app_colors.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final double height;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.backgroundColor = AppColors.cardSurface,
    this.borderColor = AppColors.borderWhite,
    this.textColor = AppColors.primaryText,
    this.height = 48.0,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;
    final activeBg = isEnabled ? backgroundColor : AppColors.darkRimGray;
    final activeBorder = isEnabled ? borderColor : AppColors.borderWhite.withValues(alpha: 0.5);
    final activeText = isEnabled ? textColor : AppColors.mutedText.withValues(alpha: 0.5);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          decoration: BoxDecoration(
            color: activeBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: activeBorder, width: 1.0),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: activeText),
                const SizedBox(width: 8),
              ],
              Text(
                text,
                style: TextStyle(
                  color: activeText,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
