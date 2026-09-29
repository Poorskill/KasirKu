import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

enum StockStatusType { inStock, lowStock, outOfStock }

class AppBadge extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;

  const AppBadge({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.icon,
  });

  factory AppBadge.stockStatus(StockStatusType status) {
    switch (status) {
      case StockStatusType.inStock:
        return const AppBadge(
          label: 'Tersedia',
          backgroundColor: AppColors.successBg,
          textColor: AppColors.success,
          icon: Icons.check_circle_outline,
        );
      case StockStatusType.lowStock:
        return const AppBadge(
          label: 'Menipis',
          backgroundColor: AppColors.warningBg,
          textColor: AppColors.warning,
          icon: Icons.warning_amber_rounded,
        );
      case StockStatusType.outOfStock:
        return const AppBadge(
          label: 'Habis',
          backgroundColor: AppColors.dangerBg,
          textColor: AppColors.danger,
          icon: Icons.cancel_outlined,
        );
    }
  }

  factory AppBadge.fromStock(int stock, int minStock) {
    if (stock <= 0) {
      return AppBadge.stockStatus(StockStatusType.outOfStock);
    } else if (stock <= minStock) {
      return AppBadge.stockStatus(StockStatusType.lowStock);
    } else {
      return AppBadge.stockStatus(StockStatusType.inStock);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
