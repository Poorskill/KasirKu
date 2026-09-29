import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/state_views.dart';
import '../../../models/product.dart';
import '../../products/presentation/products_provider.dart';
import 'cart_provider.dart';
import 'checkout_dialog.dart';
import 'widgets/cart_view.dart';

class PosScreen extends ConsumerWidget {
  const PosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = context.isMobile;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: isMobile ? _buildMobilePos(context, ref) : _buildWidePos(context, ref),
      ),
    );
  }

  Widget _buildWidePos(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        // Left: Product Catalog
        Expanded(
          flex: 6,
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.spaceMd),
            child: _ProductCatalog(
              onProductSelected: (p) =>
                  ref.read(cartNotifierProvider.notifier).addItem(p),
            ),
          ),
        ),
        // Right: Cart Panel (Fixed width 360-400px)
        SizedBox(
          width: 380,
          child: CartView(
            onCheckout: () => CheckoutDialog.show(context),
          ),
        ),
      ],
    );
  }

  Widget _buildMobilePos(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartNotifierProvider);

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppDimensions.spaceSm,
            right: AppDimensions.spaceSm,
            top: AppDimensions.spaceSm,
            bottom: 80, // space for floating cart
          ),
          child: _ProductCatalog(
            onProductSelected: (p) =>
                ref.read(cartNotifierProvider.notifier).addItem(p),
          ),
        ),

        // Floating Cart Bar on Mobile
        if (cart.isNotEmpty)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Material(
              elevation: 4,
              shadowColor: AppColors.primary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
              color: AppColors.primary,
              child: InkWell(
                onTap: () => _openMobileCartSheet(context),
                borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.shopping_cart,
                              color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${cart.totalItemsCount}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Item di keranjang',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            CurrencyFormatter.format(cart.total),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.keyboard_arrow_up,
                              color: Colors.white, size: 20),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _openMobileCartSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusSheet),
        ),
      ),
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return CartView(
              onCheckout: () {
                Navigator.of(sheetContext).pop();
                CheckoutDialog.show(context);
              },
            );
          },
        );
      },
    );
  }
}

class _ProductCatalog extends ConsumerWidget {
  final ValueChanged<Product> onProductSelected;

  const _ProductCatalog({required this.onProductSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsStreamProvider);
    final filtered = ref.watch(activeProductsForPosProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final selectedCategory = ref.watch(posCategoryFilterProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Title & Search
        Row(
          children: [
            const Expanded(
              child: Text(
                'Menu Kasir / POS',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spaceSm),

        // Search Bar
        AppTextField(
          hint: 'Cari produk di kasir...',
          prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textSecondary),
          onChanged: (val) {
            ref.read(posSearchQueryProvider.notifier).state = val;
          },
        ),
        const SizedBox(height: AppDimensions.spaceSm),

        // Category Filter Chips
        categoriesAsync.maybeWhen(
          data: (cats) => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: cats.map((cat) {
                final isSelected = selectedCategory == cat.id;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(cat.name),
                    selected: isSelected,
                    onSelected: (_) {
                      ref
                          .read(posCategoryFilterProvider.notifier)
                          .state = cat.id;
                    },
                    backgroundColor: AppColors.surface,
                    selectedColor: AppColors.primaryLight,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusBadge),
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : AppColors.border,
                      ),
                    ),
                    showCheckmark: false,
                  ),
                );
              }).toList(),
            ),
          ),
          orElse: () => const SizedBox.shrink(),
        ),
        const SizedBox(height: AppDimensions.spaceSm),

        // Catalog Grid
        Expanded(
          child: productsAsync.when(
            loading: () =>
                const LoadingWidget(message: 'Memuat menu kasir...'),
            error: (e, _) => ErrorStateWidget(message: e.toString()),
            data: (_) {
              if (filtered.isEmpty) {
                return const EmptyStateWidget(
                  title: 'Produk tidak ditemukan',
                  description: 'Coba pilih kategori lain atau kata kunci pencarian berbeda.',
                );
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount = 2; // mobile default
                  if (constraints.maxWidth > 800) {
                    crossAxisCount = 4;
                  } else if (constraints.maxWidth > 550) {
                    crossAxisCount = 3;
                  }

                  return GridView.builder(
                    itemCount: filtered.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.82,
                    ),
                    itemBuilder: (context, index) {
                      final product = filtered[index];
                      return _ProductGridCard(
                        product: product,
                        onAdd: () => onProductSelected(product),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ProductGridCard extends StatelessWidget {
  final Product product;
  final VoidCallback onAdd;

  const _ProductGridCard({
    required this.product,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final isOutOfStock = product.isOutOfStock;

    return AppCard(
      padding: const EdgeInsets.all(12),
      onTap: isOutOfStock ? null : onAdd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail / Icon Header
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: isOutOfStock
                    ? AppColors.dangerBg.withValues(alpha: 0.3)
                    : AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Icon(
                  Icons.restaurant_menu_rounded,
                  size: 32,
                  color: isOutOfStock ? AppColors.danger : AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Name
          Text(
            product.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),

          // Stock Badge
          Row(
            children: [
              AppBadge.fromStock(product.stock, product.minimumStock),
            ],
          ),
          const SizedBox(height: 6),

          // Price & Add Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                CurrencyFormatter.format(product.price),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isOutOfStock
                      ? AppColors.secondaryBtnBg
                      : AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isOutOfStock ? Icons.block : Icons.add,
                  size: 18,
                  color:
                      isOutOfStock ? AppColors.textMuted : Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
