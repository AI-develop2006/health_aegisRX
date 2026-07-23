// ─────────────────────────────────────────────────────────────
// AegisRx Shared Widget — CustomButton
// Migrated to AegisRx Design System
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:health_lock/core/theme/design_system.dart';

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
    this.backgroundColor = AegisColors.primary,
    this.borderColor = Colors.transparent,
    this.textColor = AegisColors.onPrimary,
    this.height = AegisTokens.btnHeight,
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
      duration: AegisMotion.fastest,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(CurvedAnimation(parent: _controller, curve: AegisMotion.standard));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null;

    final activeBg = isEnabled
        ? widget.backgroundColor
        : AegisTokens.btnPrimaryDisabled;
    final activeBorder = isEnabled
        ? widget.borderColor
        : AegisColors.border;
    final activeText = isEnabled
        ? widget.textColor
        : AegisColors.textDisabled;

    final hasShadow = isEnabled &&
        widget.backgroundColor != Colors.transparent &&
        widget.backgroundColor != AegisColors.surface;

    final List<BoxShadow>? shadows = hasShadow
        ? [
            BoxShadow(
              color: widget.backgroundColor.withValues(alpha: 0.28),
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
          borderRadius: AegisRadius.button,
          child: Container(
            height: widget.height,
            padding: const EdgeInsets.symmetric(horizontal: AegisSpacing.base),
            decoration: BoxDecoration(
              color: activeBg,
              borderRadius: AegisRadius.button,
              border: activeBorder != Colors.transparent
                  ? Border.all(color: activeBorder, width: AegisBorders.thin)
                  : null,
              boxShadow: shadows,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, size: AegisIconSize.sm, color: activeText),
                  const SizedBox(width: AegisSpacing.sm),
                ],
                Text(
                  widget.text,
                  style: AegisTypography.labelLarge.copyWith(color: activeText),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
