import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/state_views.dart';
import '../../../models/product.dart';
import 'product_form_dialog.dart';
import 'products_provider.dart';

class ProductListScreen extends ConsumerWidget {
  const ProductListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsStreamProvider);
    final filteredProducts = ref.watch(filteredProductsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final selectedCategory = ref.watch(selectedCategoryFilterProvider);
    final selectedStockFilter = ref.watch(productStockFilterProvider);
    final selectedActiveFilter = ref.watch(productActiveFilterProvider);
    final selectedSort = ref.watch(productSortProvider);
    final searchQuery = ref.watch(productSearchQueryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: productsAsync.when(
          loading: () => const LoadingWidget(message: 'Memuat data produk...'),
          error: (err, _) => ErrorStateWidget(
            message: err.toString(),
            onRetry: () => ref.refresh(productsStreamProvider),
          ),
          data: (allProducts) {
            final totalCount = allProducts.length;
            final availableCount =
                allProducts.where((p) => p.isAvailable).length;
            final lowStockCount =
                allProducts.where((p) => p.isLowStock).length;
            final outOfStockCount =
                allProducts.where((p) => p.isOutOfStock).length;

            return SingleChildScrollView(
              padding: EdgeInsets.all(
                context.isMobile
                    ? AppDimensions.spaceSm
                    : AppDimensions.spaceMd,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Bar
                  _buildHeader(context, ref),
                  const SizedBox(height: AppDimensions.spaceMd),

                  // Metrics Cards
                  _buildMetricsRow(
                    context,
                    ref,
                    totalCount: totalCount,
                    availableCount: availableCount,
                    lowStockCount: lowStockCount,
                    outOfStockCount: outOfStockCount,
                    currentStockFilter: selectedStockFilter,
                  ),
                  const SizedBox(height: AppDimensions.spaceMd),

                  // Filters & Search Bar Card
                  AppCard(
                    padding: const EdgeInsets.all(AppDimensions.spaceSm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: AppTextField(
                                hint: 'Cari nama produk atau SKU...',
                                prefixIcon: const Icon(Icons.search,
                                    size: 20, color: AppColors.textSecondary),
                                onChanged: (val) {
                                  ref
                                      .read(productSearchQueryProvider.notifier)
                                      .state = val;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDimensions.spaceSm),

                        // Filter Chips: Categories
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
                                          .read(selectedCategoryFilterProvider.notifier)
                                          .state = cat.id;
                                    },
                                    backgroundColor: AppColors.secondaryBtnBg,
                                    selectedColor: AppColors.primaryLight,
                                    labelStyle: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
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
                        const SizedBox(height: AppDimensions.spaceSm),

                        // Sub Filters: Stock, Active & Sort
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              // Stock Status Filter Chips
                              _buildStockChip(ref, 'Semua Stok', 'all', selectedStockFilter),
                              _buildStockChip(ref, 'Tersedia', 'inStock', selectedStockFilter),
                              _buildStockChip(ref, 'Stok Menipis', 'lowStock', selectedStockFilter),
                              _buildStockChip(ref, 'Habis', 'outOfStock', selectedStockFilter),

                              const SizedBox(width: 8),
                              Container(width: 1, height: 24, color: AppColors.border),
                              const SizedBox(width: 8),

                              // Active Status Dropdown / Chips
                              _buildActiveChip(ref, 'Aktif', 'active', selectedActiveFilter),
                              _buildActiveChip(ref, 'Non-aktif', 'inactive', selectedActiveFilter),
                              _buildActiveChip(ref, 'Semua Status', 'all', selectedActiveFilter),

                              const SizedBox(width: 8),
                              Container(width: 1, height: 24, color: AppColors.border),
                              const SizedBox(width: 8),

                              // Sort Dropdown
                              DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: selectedSort,
                                  icon: const Icon(Icons.sort, size: 18, color: AppColors.textSecondary),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                  items: const [
                                    DropdownMenuItem(value: 'nameAsc', child: Text('Urut: Nama (A-Z)')),
                                    DropdownMenuItem(value: 'priceAsc', child: Text('Urut: Harga Terendah')),
                                    DropdownMenuItem(value: 'priceDesc', child: Text('Urut: Harga Tertinggi')),
                                    DropdownMenuItem(value: 'stockAsc', child: Text('Urut: Stok Paling Sedikit')),
                                    DropdownMenuItem(value: 'stockDesc', child: Text('Urut: Stok Paling Banyak')),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) {
                                      ref.read(productSortProvider.notifier).state = val;
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spaceMd),

                  // Product Content List / Table
                  if (filteredProducts.isEmpty)
                    EmptyStateWidget(
                      title: searchQuery.isEmpty
                          ? 'Belum ada produk'
                          : 'Produk tidak ditemukan',
                      description: searchQuery.isEmpty
                          ? 'Tambahkan produk pertama untuk mulai menggunakan KasirKu.'
                          : 'Coba ubah kata kunci pencarian atau filter kategori/stok.',
                      actionLabel:
                          searchQuery.isEmpty ? 'Tambah Produk' : null,
                      onAction: searchQuery.isEmpty
                          ? () => ProductFormDialog.show(context)
                          : null,
                    )
                  else
                    context.isMobile
                        ? _buildMobileList(context, ref, filteredProducts)
                        : _buildDesktopTable(context, ref, filteredProducts),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: context.isMobile
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              onPressed: () => ProductFormDialog.show(context),
              icon: const Icon(Icons.add),
              label: const Text('Tambah Produk'),
            )
          : null,
    );
  }

  Widget _buildStockChip(WidgetRef ref, String label, String value, String current) {
    final isSelected = value == current;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {
          ref.read(productStockFilterProvider.notifier).state = value;
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
          side: BorderSide(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        showCheckmark: false,
      ),
    );
  }

  Widget _buildActiveChip(WidgetRef ref, String label, String value, String current) {
    final isSelected = value == current;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {
          ref.read(productActiveFilterProvider.notifier).state = value;
        },
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.secondaryBtnBg,
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
          side: BorderSide(
            color: isSelected ? AppColors.textPrimary : AppColors.border,
          ),
        ),
        showCheckmark: false,
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kelola Produk',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'Daftar barang inventori, harga, status aktif dan ketersediaan stok',
              style: TextStyle(
                fontSize: context.isMobile ? 12 : 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        if (!context.isMobile)
          AppButton(
            text: 'Tambah Produk',
            icon: Icons.add,
            onPressed: () => ProductFormDialog.show(context),
          ),
      ],
    );
  }

  Widget _buildMetricsRow(
    BuildContext context,
    WidgetRef ref, {
    required int totalCount,
    required int availableCount,
    required int lowStockCount,
    required int outOfStockCount,
    required String currentStockFilter,
  }) {
    final cards = [
      _MetricBadge(
        label: 'Total Produk',
        count: totalCount,
        icon: Icons.inventory_2_outlined,
        color: AppColors.primary,
        bgColor: AppColors.primaryLight,
        isSelected: currentStockFilter == 'all',
        onTap: () => ref.read(productStockFilterProvider.notifier).state = 'all',
      ),
      _MetricBadge(
        label: 'Tersedia',
        count: availableCount,
        icon: Icons.check_circle_outline,
        color: AppColors.success,
        bgColor: AppColors.successBg,
        isSelected: currentStockFilter == 'inStock',
        onTap: () => ref.read(productStockFilterProvider.notifier).state = 'inStock',
      ),
      _MetricBadge(
        label: 'Stok Menipis',
        count: lowStockCount,
        icon: Icons.warning_amber_rounded,
        color: AppColors.warning,
        bgColor: AppColors.warningBg,
        isSelected: currentStockFilter == 'lowStock',
        onTap: () => ref.read(productStockFilterProvider.notifier).state = 'lowStock',
      ),
      _MetricBadge(
        label: 'Habis',
        count: outOfStockCount,
        icon: Icons.cancel_outlined,
        color: AppColors.danger,
        bgColor: AppColors.dangerBg,
        isSelected: currentStockFilter == 'outOfStock',
        onTap: () => ref.read(productStockFilterProvider.notifier).state = 'outOfStock',
      ),
    ];

    if (context.isMobile) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2.1,
            children: cards,
          );
        },
      );
    }

    return Row(
      children: cards.map((c) => Expanded(child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: c,
      ))).toList(),
    );
  }

  Widget _buildDesktopTable(
    BuildContext context,
    WidgetRef ref,
    List<Product> products,
  ) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: AppColors.secondaryBtnBg,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: const Row(
              children: [
                Expanded(flex: 4, child: Text('PRODUK', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary))),
                Expanded(flex: 2, child: Text('SKU', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary))),
                Expanded(flex: 2, child: Text('HARGA JUAL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary))),
                Expanded(flex: 2, child: Text('STOK', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary))),
                Expanded(flex: 2, child: Text('STATUS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary))),
                SizedBox(width: 90, child: Text('AKSI', textAlign: TextAlign.right, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary))),
              ],
            ),
          ),
          // Table Rows
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: products.length,
            separatorBuilder: (_, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final product = products[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    // Product Icon + Name + Description + Inactive badge
                    Expanded(
                      flex: 4,
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: product.isActive ? AppColors.primaryLight : AppColors.secondaryBtnBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.shopping_bag_outlined,
                              color: product.isActive ? AppColors.primary : AppColors.textMuted,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        product.name,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: product.isActive ? AppColors.textPrimary : AppColors.textMuted,
                                        ),
                                      ),
                                    ),
                                    if (!product.isActive) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: AppColors.secondaryBtnBg,
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: AppColors.border),
                                        ),
                                        child: const Text(
                                          'Non-aktif',
                                          style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                if (product.description != null &&
                                    product.description!.isNotEmpty)
                                  Text(
                                    product.description!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // SKU
                    Expanded(
                      flex: 2,
                      child: Text(
                        product.sku,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    // Price
                    Expanded(
                      flex: 2,
                      child: Text(
                        CurrencyFormatter.format(product.price),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    // Stock
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${product.stock} unit',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    // Status Badge
                    Expanded(
                      flex: 2,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: AppBadge.fromStock(
                            product.stock, product.minimumStock),
                      ),
                    ),
                    // Actions
                    SizedBox(
                      width: 90,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined,
                                size: 18, color: AppColors.textSecondary),
                            tooltip: 'Edit',
                            onPressed: () => ProductFormDialog.show(context,
                                product: product),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded,
                                size: 18, color: AppColors.danger),
                            tooltip: 'Hapus / Nonaktifkan',
                            onPressed: () =>
                                _confirmDelete(context, ref, product),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMobileList(
    BuildContext context,
    WidgetRef ref,
    List<Product> products,
  ) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: products.length,
      separatorBuilder: (_, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final product = products[index];
        return AppCard(
          padding: const EdgeInsets.all(AppDimensions.spaceSm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: product.isActive ? AppColors.primaryLight : AppColors.secondaryBtnBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.shopping_bag_outlined,
                      color: product.isActive ? AppColors.primary : AppColors.textMuted,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                product.name,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: product.isActive ? AppColors.textPrimary : AppColors.textMuted,
                                ),
                              ),
                            ),
                            if (!product.isActive) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.secondaryBtnBg,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: const Text(
                                  'Non-aktif',
                                  style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'SKU: ${product.sku}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert,
                        color: AppColors.textSecondary),
                    onSelected: (val) {
                      if (val == 'edit') {
                        ProductFormDialog.show(context, product: product);
                      } else if (val == 'toggle') {
                        ref.read(productControllerProvider.notifier).toggleActive(product.id);
                      } else if (val == 'delete') {
                        _confirmDelete(context, ref, product);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'toggle',
                        child: Row(
                          children: [
                            Icon(product.isActive ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
                            const SizedBox(width: 8),
                            Text(product.isActive ? 'Nonaktifkan' : 'Aktifkan'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline,
                                size: 18, color: AppColors.danger),
                            SizedBox(width: 8),
                            Text('Hapus',
                                style: TextStyle(color: AppColors.danger)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        CurrencyFormatter.format(product.price),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        'Stok: ${product.stock} unit',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  AppBadge.fromStock(product.stock, product.minimumStock),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Product product) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
          ),
          backgroundColor: AppColors.surface,
          title: const Text(
            'Hapus / Nonaktifkan Produk?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          content: Text(
            'Pilih "Nonaktifkan" untuk menyembunyikan "${product.name}" dari transaksi kasir tanpa merusak riwayat transaksi terdahulu, atau "Hapus Permanen" jika produk belum pernah ditransaksikan.',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Batal',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
            AppButton(
              text: 'Nonaktifkan Saja',
              variant: ButtonVariant.secondary,
              height: 38,
              onPressed: () async {
                Navigator.of(dialogCtx).pop();
                final ok = await ref
                    .read(productControllerProvider.notifier)
                    .deleteProduct(product.id, permanent: false);
                if (ok && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Produk berhasil dinonaktifkan (disembunyikan dari kasir)'),
                      backgroundColor: AppColors.warning,
                    ),
                  );
                }
              },
            ),
            AppButton(
              text: 'Hapus Permanen',
              variant: ButtonVariant.danger,
              height: 38,
              onPressed: () async {
                Navigator.of(dialogCtx).pop();
                final ok = await ref
                    .read(productControllerProvider.notifier)
                    .deleteProduct(product.id, permanent: true);
                if (ok && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Produk berhasil dihapus secara permanen'),
                      backgroundColor: AppColors.danger,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
}

class _MetricBadge extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final bool isSelected;
  final VoidCallback? onTap;

  const _MetricBadge({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
    required this.bgColor,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: onTap,
      border: isSelected ? BorderSide(color: color, width: 2) : null,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  count.toString(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? color : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
