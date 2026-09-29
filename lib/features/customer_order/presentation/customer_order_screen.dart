import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_product_image.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/state_views.dart';
import '../../../models/product.dart';
import '../../../models/restaurant_table.dart';
import '../../products/presentation/products_provider.dart';
import 'customer_order_provider.dart';
import 'customer_order_tracking_screen.dart';
import 'widgets/call_waiter_dialog.dart';
import 'widgets/customer_cart_sheet.dart';
import 'widgets/online_payment_dialog.dart';
import 'widgets/product_modifier_sheet.dart';

class CustomerOrderScreen extends ConsumerStatefulWidget {
  final String storeId;
  final String tableToken;

  const CustomerOrderScreen({
    super.key,
    required this.storeId,
    required this.tableToken,
  });

  @override
  ConsumerState<CustomerOrderScreen> createState() =>
      _CustomerOrderScreenState();
}

class _CustomerOrderScreenState extends ConsumerState<CustomerOrderScreen> {
  String _selectedCategory = 'all';
  String _searchQuery = '';
  String? _activeOrderId;

  @override
  Widget build(BuildContext context) {
    final tableAsync =
        ref.watch(customerTableByTokenProvider(widget.tableToken));

    return tableAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 16),
              Text('Menghubungkan ke Meja Restoran...'),
            ],
          ),
        ),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.background,
        body: ErrorStateWidget(
          message: 'Meja tidak ditemukan atau kode QR telah kadaluwarsa.\nSilakan panggil pelayan untuk QR meja baru.',
        ),
      ),
      data: (table) {
        if (table == null) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: ErrorStateWidget(
              message: 'Token Meja Tidak Valid.\nSilakan scan ulang QR code yang tertera pada meja.',
            ),
          );
        }

        // If customer has an active order, show tracking view
        if (_activeOrderId != null) {
          return CustomerOrderTrackingScreen(
            orderId: _activeOrderId!,
            table: table,
            onReorder: () {
              setState(() => _activeOrderId = null);
            },
          );
        }

        return _buildCatalogView(context, table);
      },
    );
  }

  Widget _buildCatalogView(BuildContext context, RestaurantTable table) {
    final productsAsync = ref.watch(productsStreamProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final cart = ref.watch(customerCartNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.restaurant_rounded,
                    size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                const Text(
                  'KasirKu Dining',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            Text(
              'MEJA ${table.tableNumber} • ${table.name}',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ActionChip(
              avatar: const Icon(Icons.room_service_rounded,
                  size: 16, color: AppColors.warning),
              label: const Text('Panggil Pelayan'),
              labelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              backgroundColor: AppColors.warningBg,
              side: BorderSide.none,
              onPressed: () => CallWaiterDialog.show(context, table: table),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: 90, // space for floating bottom cart
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Search Bar
                    AppTextField(
                      hint: 'Cari menu makanan atau minuman...',
                      prefixIcon: const Icon(Icons.search,
                          size: 20, color: AppColors.textSecondary),
                      onChanged: (val) =>
                          setState(() => _searchQuery = val.trim().toLowerCase()),
                    ),
                    const SizedBox(height: 12),

                    // Categories Filter Chips
                    categoriesAsync.maybeWhen(
                      data: (cats) => SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: cats.map((cat) {
                            final isSelected = _selectedCategory == cat.id;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(cat.name),
                                selected: isSelected,
                                onSelected: (_) => setState(
                                    () => _selectedCategory = cat.id),
                                backgroundColor: AppColors.surface,
                                selectedColor: AppColors.primaryLight,
                                labelStyle: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.textPrimary,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppDimensions.radiusBadge),
                                  side: BorderSide(
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.border,
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
                    const SizedBox(height: 16),

                    // Product List / Grid
                    productsAsync.when(
                      loading: () =>
                          const LoadingWidget(message: 'Memuat menu lezat...'),
                      error: (e, _) => ErrorStateWidget(message: e.toString()),
                      data: (products) {
                        final availableProducts = products.where((p) {
                          if (!p.isActive) return false;
                          if (_selectedCategory != 'all' &&
                              p.categoryId != _selectedCategory) {
                            return false;
                          }
                          if (_searchQuery.isNotEmpty) {
                            final matchName =
                                p.name.toLowerCase().contains(_searchQuery);
                            final matchSku =
                                p.sku.toLowerCase().contains(_searchQuery);
                            if (!matchName && !matchSku) return false;
                          }
                          return true;
                        }).toList();

                        if (availableProducts.isEmpty) {
                          return const EmptyStateWidget(
                            title: 'Menu tidak ditemukan',
                            description:
                                'Coba ganti kategori atau kata kunci pencarian Anda.',
                          );
                        }

                        return LayoutBuilder(
                          builder: (context, constraints) {
                            int crossAxisCount = 2;
                            if (constraints.maxWidth > 500) {
                              crossAxisCount = 3;
                            }

                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: availableProducts.length,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.78,
                              ),
                              itemBuilder: (context, index) {
                                final p = availableProducts[index];
                                return _CustomerProductCard(
                                  product: p,
                                  onSelect: () =>
                                      ProductModifierSheet.show(context, product: p),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Floating Bottom Cart Bar
            if (cart.isNotEmpty)
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Material(
                  elevation: 6,
                  shadowColor: AppColors.primary.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(16),
                  color: AppColors.primary,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      CustomerCartSheet.show(
                        context,
                        table: table,
                        onProceedToPayment: () {
                          OnlinePaymentDialog.show(
                            context,
                            table: table,
                            onPaymentSuccess: (paidOrder) {
                              setState(() {
                                _activeOrderId = paidOrder.id;
                              });
                            },
                          );
                        },
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${cart.totalItemsCount}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'Lihat Keranjang',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                CurrencyFormatter.format(cart.subtotal),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.arrow_forward_ios_rounded,
                                  size: 14, color: Colors.white),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CustomerProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onSelect;

  const _CustomerProductCard({
    required this.product,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isSoldOut = product.isOutOfStock;

    return AppCard(
      padding: const EdgeInsets.all(10),
      onTap: isSoldOut ? null : onSelect,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                AppProductImage(
                  imageUrl: product.imageUrl,
                  borderRadius: 10,
                ),
                if (isSoldOut)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.danger,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'HABIS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
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

          // Price & Add Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                CurrencyFormatter.format(product.price),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isSoldOut
                      ? AppColors.secondaryBtnBg
                      : AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isSoldOut ? 'Habis' : '+ Tambah',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isSoldOut ? AppColors.textMuted : AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
