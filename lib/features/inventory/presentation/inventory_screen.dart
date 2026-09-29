import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/state_views.dart';
import '../../../models/product.dart';
import '../../../models/stock_movement.dart';
import '../../products/presentation/products_provider.dart';
import 'stock_adjustment_dialog.dart';
import 'stock_provider.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsStreamProvider);
    final movementsAsync = ref.watch(stockMovementsStreamProvider);
    final filteredMovements = ref.watch(filteredStockMovementsProvider);
    final selectedType = ref.watch(stockMovementTypeFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(
            context.isMobile ? AppDimensions.spaceSm : AppDimensions.spaceMd,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              const Text(
                'Manajemen Inventori & Stok',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Text(
                'Peringatan stok menipis, penyesuaian opname fisik, dan log riwayat mutasi barang',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppDimensions.spaceMd),

              // Tab Bar Container
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
                  border: Border.all(color: AppColors.border),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.primary,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondary,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.warning_amber_rounded, size: 18),
                      text: 'Peringatan Stok Menipis',
                    ),
                    Tab(
                      icon: Icon(Icons.history_rounded, size: 18),
                      text: 'Riwayat Mutasi Stok',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.spaceMd),

              // Tab Views
              SizedBox(
                height: 640,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Low stock alert
                    productsAsync.when(
                      loading: () => const LoadingWidget(message: 'Memeriksa stok...'),
                      error: (e, _) => ErrorStateWidget(message: e.toString()),
                      data: (products) {
                        final lowStockList = products
                            .where((p) => p.isLowStock || p.isOutOfStock)
                            .toList();

                        if (lowStockList.isEmpty) {
                          return const EmptyStateWidget(
                            title: 'Semua Stok Aman!',
                            description: 'Tidak ada produk yang berada di bawah batas minimum stok saat ini.',
                            icon: Icons.check_circle_outline,
                          );
                        }

                        return _buildLowStockView(context, lowStockList);
                      },
                    ),

                    // Tab 2: Stock movements history
                    movementsAsync.when(
                      loading: () => const LoadingWidget(message: 'Memuat mutasi stok...'),
                      error: (e, _) => ErrorStateWidget(message: e.toString()),
                      data: (_) {
                        return _buildMovementHistoryView(
                          context,
                          filteredMovements,
                          selectedType,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLowStockView(BuildContext context, List<Product> list) {
    return ListView.separated(
      itemCount: list.length,
      separatorBuilder: (_, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final product = list[index];
        return AppCard(
          padding: const EdgeInsets.all(AppDimensions.spaceSm),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: product.isOutOfStock ? AppColors.dangerBg : AppColors.warningBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  product.isOutOfStock ? Icons.cancel_outlined : Icons.warning_amber_rounded,
                  color: product.isOutOfStock ? AppColors.danger : AppColors.warning,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'SKU: ${product.sku}  •  Min. Stok: ${product.minimumStock}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AppBadge.fromStock(product.stock, product.minimumStock),
                  const SizedBox(height: 6),
                  Text(
                    'Sisa: ${product.stock} unit',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: product.isOutOfStock ? AppColors.danger : AppColors.warning,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              AppButton(
                text: 'Atur Stok',
                icon: Icons.edit_note,
                variant: ButtonVariant.primary,
                height: 38,
                onPressed: () => StockAdjustmentDialog.show(context, product: product),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMovementHistoryView(
    BuildContext context,
    List<StockMovement> movements,
    String selectedType,
  ) {
    return Column(
      children: [
        // Filter bar
        AppCard(
          padding: const EdgeInsets.all(AppDimensions.spaceSm),
          child: Column(
            children: [
              AppTextField(
                hint: 'Cari mutasi barang, alasan, atau user...',
                prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textSecondary),
                onChanged: (val) {
                  ref.read(stockMovementSearchProvider.notifier).state = val;
                },
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _typeFilterChip('Semua', 'all', selectedType),
                    _typeFilterChip('Masuk (Restock)', 'stockIn', selectedType),
                    _typeFilterChip('Keluar', 'stockOut', selectedType),
                    _typeFilterChip('Opname', 'adjustment', selectedType),
                    _typeFilterChip('Penjualan', 'sale', selectedType),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.spaceSm),

        // List / Table
        Expanded(
          child: movements.isEmpty
              ? const EmptyStateWidget(
                  title: 'Tidak ada riwayat mutasi',
                  description: 'Belum ada log pergerakan stok untuk filter ini.',
                )
              : ListView.separated(
                  itemCount: movements.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final m = movements[index];
                    Color typeColor;
                    switch (m.type) {
                      case StockMovementType.stockIn:
                        typeColor = AppColors.success;
                      case StockMovementType.stockOut:
                        typeColor = AppColors.danger;
                      case StockMovementType.sale:
                        typeColor = AppColors.primary;
                      case StockMovementType.adjustment:
                        typeColor = AppColors.warning;
                    }

                    return AppCard(
                      padding: const EdgeInsets.all(AppDimensions.spaceSm),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: typeColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              m.type.label,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: typeColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  m.productName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  'Alasan: ${m.reason} • Oleh: ${m.createdBy}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${m.quantity > 0 ? "+" : ""}${m.quantity} unit',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: m.quantity >= 0 ? AppColors.success : AppColors.danger,
                                ),
                              ),
                              Text(
                                '${m.previousStock} → ${m.newStock}  •  ${DateFormatter.formatShortDate(m.createdAt)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _typeFilterChip(String label, String value, String current) {
    final isSelected = value == current;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {
          ref.read(stockMovementTypeFilterProvider.notifier).state = value;
        },
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primaryLight,
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? AppColors.primary : AppColors.textSecondary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
          side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
        ),
        showCheckmark: false,
      ),
    );
  }
}
