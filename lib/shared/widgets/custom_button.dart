import 'package:flutter/material.dart';
import 'package:health_lock/core/constants/app_colors.dart';

class CustomButton extends StatefulWidget {
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
    this.backgroundColor = AppColors.patientBlue, // Default to primary Patient Blue
    this.borderColor = Colors.transparent,
    this.textColor = Colors.white,
    this.height = 48.0,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null;

    // Disabled state treatment
    final activeBg = isEnabled
        ? widget.backgroundColor
        : AppColors.surfaceMuted;
    final activeBorder = isEnabled
        ? widget.borderColor
        : AppColors.borderWhite;
    final activeText = isEnabled
        ? widget.textColor
        : AppColors.textFaint;

    // Custom shadow: 30% opacity of the background color if solid CTA
    final List<BoxShadow>? shadows = isEnabled &&
            widget.backgroundColor != Colors.transparent &&
            widget.backgroundColor != AppColors.cardSurface
        ? [
            BoxShadow(
              color: widget.backgroundColor.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ]
        : null;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onPressed,
          onTapDown: (_) => _controller.forward(),
          onTapUp: (_) => _controller.reverse(),
          onTapCancel: () => _controller.reverse(),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: widget.height,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            decoration: BoxDecoration(
              color: activeBg,
              borderRadius: BorderRadius.circular(12),
              border: activeBorder != Colors.transparent
                  ? Border.all(color: activeBorder, width: 1.0)
                  : null,
              boxShadow: shadows,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, size: 16, color: activeText),
                  const SizedBox(width: 8),
                ],
                Text(
                  widget.text,
                  style: TextStyle(
                    color: activeText,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
