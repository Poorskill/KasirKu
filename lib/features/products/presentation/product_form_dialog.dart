import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_product_image.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../models/category.dart';
import '../../../models/product.dart';
import 'products_provider.dart';

class ProductFormDialog extends ConsumerStatefulWidget {
  final Product? productToEdit;

  const ProductFormDialog({super.key, this.productToEdit});

  static Future<void> show(BuildContext context, {Product? product}) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ProductFormDialog(productToEdit: product),
    );
  }

  @override
  ConsumerState<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends ConsumerState<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _skuController;
  late TextEditingController _priceController;
  late TextEditingController _costPriceController;
  late TextEditingController _stockController;
  late TextEditingController _minStockController;
  late TextEditingController _descController;
  late TextEditingController _imageUrlController;
  String _selectedCategory = 'cat-makanan';
  bool _isActive = true;

  bool get isEditing => widget.productToEdit != null;

  @override
  void initState() {
    super.initState();
    final p = widget.productToEdit;
    _nameController = TextEditingController(text: p?.name ?? '');
    _skuController = TextEditingController(text: p?.sku ?? _generateSku());
    _priceController =
        TextEditingController(text: p != null ? p.price.toStringAsFixed(0) : '');
    _costPriceController = TextEditingController(
        text: p != null ? p.costPrice.toStringAsFixed(0) : '');
    _stockController =
        TextEditingController(text: p != null ? p.stock.toString() : '10');
    _minStockController = TextEditingController(
        text: p != null ? p.minimumStock.toString() : '5');
    _descController = TextEditingController(text: p?.description ?? '');
    _imageUrlController = TextEditingController(text: p?.imageUrl ?? '');
    _isActive = p?.isActive ?? true;
    if (p != null && p.categoryId.isNotEmpty) {
      _selectedCategory = p.categoryId;
    }
  }

  String _generateSku() {
    final rand = DateTime.now().millisecondsSinceEpoch % 1000;
    return 'PRD-${rand.toString().padLeft(3, '0')}';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _priceController.dispose();
    _costPriceController.dispose();
    _stockController.dispose();
    _minStockController.dispose();
    _descController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();
    final product = Product(
      id: widget.productToEdit?.id ?? 'prod-${now.millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      sku: _skuController.text.trim().toUpperCase(),
      categoryId: _selectedCategory,
      price: double.tryParse(_priceController.text) ?? 0.0,
      costPrice: double.tryParse(_costPriceController.text) ?? 0.0,
      stock: int.tryParse(_stockController.text) ?? 0,
      minimumStock: int.tryParse(_minStockController.text) ?? 5,
      imageUrl: _imageUrlController.text.trim().isEmpty
          ? null
          : _imageUrlController.text.trim(),
      description: _descController.text.trim(),
      isActive: _isActive,
      createdAt: widget.productToEdit?.createdAt ?? now,
      updatedAt: now,
    );

    bool ok;
    if (isEditing) {
      ok = await ref
          .read(productControllerProvider.notifier)
          .updateProduct(product);
    } else {
      ok = await ref.read(productControllerProvider.notifier).addProduct(product);
    }

    if (ok && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing ? 'Produk berhasil diubah' : 'Produk berhasil ditambahkan',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final actionState = ref.watch(productControllerProvider);
    final isLoading = actionState.isLoading;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
      ),
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spaceMd),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusInput),
                        ),
                        child: const Icon(
                          Icons.inventory_2_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spaceSm),
                      Text(
                        isEditing ? 'Edit Produk' : 'Tambah Produk Baru',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spaceSm),
              const Divider(height: 1),
              const SizedBox(height: AppDimensions.spaceSm),

              // Scrollable Form
              Expanded(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Nama Produk
                        AppTextField(
                          label: 'Nama Produk *',
                          hint: 'Contoh: Kopi Susu Gula Aren',
                          controller: _nameController,
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                        ),
                        const SizedBox(height: AppDimensions.spaceSm),

                        // SKU & Kategori
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isNarrow = constraints.maxWidth < 400;
                            if (isNarrow) {
                              return Column(
                                children: [
                                  AppTextField(
                                    label: 'Kode SKU *',
                                    hint: 'KOP-001',
                                    controller: _skuController,
                                    validator: (v) =>
                                        (v == null || v.trim().isEmpty)
                                            ? 'Wajib diisi'
                                            : null,
                                  ),
                                  const SizedBox(height: AppDimensions.spaceSm),
                                  _buildCategoryDropdown(categoriesAsync),
                                ],
                              );
                            }
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: AppTextField(
                                    label: 'Kode SKU *',
                                    hint: 'KOP-001',
                                    controller: _skuController,
                                    validator: (v) =>
                                        (v == null || v.trim().isEmpty)
                                            ? 'Wajib diisi'
                                            : null,
                                  ),
                                ),
                                const SizedBox(width: AppDimensions.spaceSm),
                                Expanded(
                                  child: _buildCategoryDropdown(categoriesAsync),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: AppDimensions.spaceSm),

                        // Harga Jual & Harga Modal
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isNarrow = constraints.maxWidth < 400;
                            if (isNarrow) {
                              return Column(
                                children: [
                                  AppTextField(
                                    label: 'Harga Jual (Rp) *',
                                    hint: '18000',
                                    controller: _priceController,
                                    keyboardType: TextInputType.number,
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) {
                                        return 'Wajib diisi';
                                      }
                                      if (double.tryParse(v) == null) {
                                        return 'Format angka salah';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: AppDimensions.spaceSm),
                                  AppTextField(
                                    label: 'Harga Modal (Rp)',
                                    hint: '8000',
                                    controller: _costPriceController,
                                    keyboardType: TextInputType.number,
                                  ),
                                ],
                              );
                            }
                            return Row(
                              children: [
                                Expanded(
                                  child: AppTextField(
                                    label: 'Harga Jual (Rp) *',
                                    hint: '18000',
                                    controller: _priceController,
                                    keyboardType: TextInputType.number,
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) {
                                        return 'Wajib diisi';
                                      }
                                      if (double.tryParse(v) == null) {
                                        return 'Format angka salah';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: AppDimensions.spaceSm),
                                Expanded(
                                  child: AppTextField(
                                    label: 'Harga Modal (Rp)',
                                    hint: '8000',
                                    controller: _costPriceController,
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: AppDimensions.spaceSm),

                        // Stok & Minimum Stok
                        Row(
                          children: [
                            Expanded(
                              child: AppTextField(
                                label: 'Jumlah Stok *',
                                hint: '25',
                                controller: _stockController,
                                keyboardType: TextInputType.number,
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) {
                                        return 'Wajib diisi';
                                      }
                                      final numVal = double.tryParse(v);
                                      if (numVal == null) {
                                        return 'Format angka salah';
                                      }
                                      if (numVal <= 0) {
                                        return 'Harga harus > 0';
                                      }
                                      return null;
                                    },
                              ),
                            ),
                            const SizedBox(width: AppDimensions.spaceSm),
                            Expanded(
                              child: AppTextField(
                                label: 'Minimum Stok (Peringatan)',
                                hint: '5',
                                controller: _minStockController,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDimensions.spaceSm),

                        // Foto Produk URL + Preview
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            AppProductImage(
                              imageUrl: _imageUrlController.text.trim().isEmpty
                                  ? null
                                  : _imageUrlController.text.trim(),
                              width: 52,
                              height: 52,
                              borderRadius: 8,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: AppTextField(
                                label: 'URL Foto Produk (Opsional)',
                                hint: 'https://images.unsplash.com/...',
                                controller: _imageUrlController,
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDimensions.spaceSm),

                        // Deskripsi
                        AppTextField(
                          label: 'Deskripsi Produk',
                          hint: 'Keterangan bahan, rasa, porsi, dsb.',
                          controller: _descController,
                          maxLines: 2,
                        ),
                        const SizedBox(height: AppDimensions.spaceSm),

                        // Status Aktif Toggle
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius:
                                BorderRadius.circular(AppDimensions.radiusInput),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Status Produk Aktif',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    _isActive
                                        ? 'Dapat dicari dan dijual di kasir'
                                        : 'Disembunyikan dari katalog kasir',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              Switch(
                                value: _isActive,
                                activeThumbColor: AppColors.primary,
                                onChanged: (val) =>
                                    setState(() => _isActive = val),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppDimensions.spaceSm),
              const Divider(height: 1),
              const SizedBox(height: AppDimensions.spaceSm),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppButton(
                    text: 'Batal',
                    variant: ButtonVariant.secondary,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: AppDimensions.spaceSm),
                  AppButton(
                    text: isEditing ? 'Simpan Perubahan' : 'Tambah Produk',
                    isLoading: isLoading,
                    onPressed: _save,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown(AsyncValue<List<ProductCategory>> asyncCats) {
    final cats = asyncCats.asData?.value.where((c) => c.id != 'all').toList() ??
        const [
          ProductCategory(id: 'cat-makanan', name: 'Makanan'),
          ProductCategory(id: 'cat-minuman', name: 'Minuman'),
          ProductCategory(id: 'cat-snack', name: 'Snack / Camilan'),
        ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kategori *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppDimensions.spaceXs),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusInput),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: cats.any((c) => c.id == _selectedCategory)
                  ? _selectedCategory
                  : cats.first.id,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textSecondary),
              items: cats.map((cat) {
                return DropdownMenuItem<String>(
                  value: cat.id,
                  child: Text(cat.name),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedCategory = val);
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}
