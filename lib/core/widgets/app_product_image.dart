import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppProductImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final double borderRadius;
  final IconData fallbackIcon;
  final Color? backgroundColor;

  const AppProductImage({
    super.key,
    this.imageUrl,
    this.width,
    this.height,
    this.borderRadius = 8.0,
    this.fallbackIcon = Icons.restaurant_menu_rounded,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final hasUrl = imageUrl != null && imageUrl!.trim().isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        width: width,
        height: height,
        color: backgroundColor ?? AppColors.primaryLight,
        child: hasUrl
            ? Image.network(
                imageUrl!.trim(),
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        color: AppColors.primary,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => _fallbackWidget(),
              )
            : _fallbackWidget(),
      ),
    );
  }

  Widget _fallbackWidget() {
    return Center(
      child: Icon(
        fallbackIcon,
        size: (height != null && height! <= 50) ? 22 : 36,
        color: AppColors.primary,
      ),
    );
  }
}
