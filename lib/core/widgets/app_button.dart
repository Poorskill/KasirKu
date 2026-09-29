import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

enum ButtonVariant { primary, secondary, danger, outline }

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final double? width;
  final double height;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.width,
    this.height = AppDimensions.minTouchTarget,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    BorderSide borderSide = BorderSide.none;

    switch (variant) {
      case ButtonVariant.primary:
        bg = AppColors.primary;
        fg = Colors.white;
      case ButtonVariant.secondary:
        bg = AppColors.secondaryBtnBg;
        fg = AppColors.textPrimary;
        borderSide = const BorderSide(color: AppColors.border, width: 1);
      case ButtonVariant.danger:
        bg = AppColors.dangerBg;
        fg = AppColors.danger;
      case ButtonVariant.outline:
        bg = Colors.transparent;
        fg = AppColors.primary;
        borderSide = const BorderSide(color: AppColors.primary, width: 1.5);
    }

    final child = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(fg),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: fg),
                const SizedBox(width: AppDimensions.spaceXs),
              ],
              Text(
                text,
                style: TextStyle(
                  color: fg,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );

    return SizedBox(
      width: width,
      height: height,
      child: Material(
        color: onPressed == null ? bg.withValues(alpha: 0.5) : bg,
        borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
          side: borderSide,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: (isLoading || onPressed == null) ? null : onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}
