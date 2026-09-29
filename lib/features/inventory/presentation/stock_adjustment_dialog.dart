import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../models/product.dart';
import '../../../models/stock_movement.dart';
import '../../auth/presentation/auth_provider.dart';
import 'stock_provider.dart';

class StockAdjustmentDialog extends ConsumerStatefulWidget {
  final Product product;

  const StockAdjustmentDialog({super.key, required this.product});

  static Future<void> show(BuildContext context, {required Product product}) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StockAdjustmentDialog(product: product),
    );
  }

  @override
  ConsumerState<StockAdjustmentDialog> createState() =>
      _StockAdjustmentDialogState();
}

class _StockAdjustmentDialogState extends ConsumerState<StockAdjustmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _qtyController = TextEditingController(text: '1');
  final _reasonController = TextEditingController();
  StockMovementType _selectedType = StockMovementType.stockIn;

  @override
  void dispose() {
    _qtyController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  int get _parsedQty => int.tryParse(_qtyController.text) ?? 0;

  int get _delta {
    switch (_selectedType) {
      case StockMovementType.stockIn:
        return _parsedQty.abs();
      case StockMovementType.stockOut:
        return -_parsedQty.abs();
      case StockMovementType.adjustment:
        // Target stock adjustment
        return _parsedQty - widget.product.stock;
      case StockMovementType.sale:
        return -_parsedQty.abs();
    }
  }

  int get _projectedStock {
    if (_selectedType == StockMovementType.adjustment) {
      return _parsedQty.clamp(0, 999999);
    }
    return (widget.product.stock + _delta).clamp(0, 999999);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(currentUserProvider);
    final delta = _delta;

    final ok = await ref
        .read(stockAdjustmentControllerProvider.notifier)
        .adjustStock(
          product: widget.product,
          type: _selectedType,
          quantityDelta: delta,
          reason: _reasonController.text.trim(),
          userName: user?.name ?? 'Admin',
        );

    if (ok && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Penyesuaian stok berhasil disimpan'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final curProduct = widget.product;
    final actionState = ref.watch(stockAdjustmentControllerProvider);
    final isLoading = actionState.isLoading;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
      ),
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 680),
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
                  const Row(
                    children: [
                      Icon(Icons.inventory_rounded, color: AppColors.primary, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Atur & Sesuaikan Stok',
                        style: TextStyle(
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
              const Divider(height: 1),
              const SizedBox(height: AppDimensions.spaceSm),

              Expanded(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Product Summary Box
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryBtnBg,
                            borderRadius:
                                BorderRadius.circular(AppDimensions.radiusInput),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      curProduct.name,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      'SKU: ${curProduct.sku}',
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
                                  const Text(
                                    'Stok Saat Ini',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    '${curProduct.stock} unit',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppDimensions.spaceSm),

                        // Movement Type
                        const Text(
                          'Jenis Penyesuaian',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _buildTypeChip(
                              type: StockMovementType.stockIn,
                              label: 'Masuk (+)',
                              icon: Icons.add_circle_outline,
                              color: AppColors.success,
                            ),
                            const SizedBox(width: 8),
                            _buildTypeChip(
                              type: StockMovementType.stockOut,
                              label: 'Keluar (-)',
                              icon: Icons.remove_circle_outline,
                              color: AppColors.danger,
                            ),
                            const SizedBox(width: 8),
                            _buildTypeChip(
                              type: StockMovementType.adjustment,
                              label: 'Opname (=)',
                              icon: Icons.edit_note,
                              color: AppColors.warning,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDimensions.spaceSm),

                        // Quantity Input
                        AppTextField(
                          label: _selectedType == StockMovementType.adjustment
                              ? 'Stok Fisik Sebenarnya (Hasil Opname) *'
                              : 'Jumlah Barang *',
                          hint: '1',
                          controller: _qtyController,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() {}),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Wajib diisi';
                            final n = int.tryParse(v);
                            if (n == null) return 'Format angka tidak valid';
                            if (n <= 0 && _selectedType != StockMovementType.adjustment) {
                              return 'Jumlah harus lebih dari 0';
                            }
                            if (n < 0) return 'Stok tidak boleh negatif';
                            if (_selectedType == StockMovementType.stockOut &&
                                n > curProduct.stock) {
                              return 'Jumlah keluar melebihi stok yang ada';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppDimensions.spaceSm),

                        // Reason Input
                        AppTextField(
                          label: 'Alasan Penyesuaian *',
                          hint: _selectedType == StockMovementType.stockIn
                              ? 'Contoh: Restock supplier baru'
                              : (_selectedType == StockMovementType.stockOut
                                  ? 'Contoh: Barang rusak / expired'
                                  : 'Contoh: Koreksi selisih opname fisik bulanan'),
                          controller: _reasonController,
                          maxLines: 2,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Alasan wajib diisi';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppDimensions.spaceMd),

                        // Projected Calculation Preview
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius:
                                BorderRadius.circular(AppDimensions.radiusInput),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Proyeksi Stok Akhir',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    '${curProduct.stock}  →  $_projectedStock unit',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _delta > 0
                                      ? '+$_delta'
                                      : '$_delta',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: _delta > 0
                                        ? AppColors.success
                                        : (_delta < 0
                                            ? AppColors.danger
                                            : AppColors.textSecondary),
                                  ),
                                ),
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
                children: [
                  Expanded(
                    child: AppButton(
                      text: 'Batal',
                      variant: ButtonVariant.secondary,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spaceSm),
                  Expanded(
                    child: AppButton(
                      text: 'Simpan Stok',
                      isLoading: isLoading,
                      onPressed: _submit,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip({
    required StockMovementType type,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedType == type;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedType = type;
            if (_selectedType == StockMovementType.adjustment) {
              _qtyController.text = widget.product.stock.toString();
            } else {
              _qtyController.text = '1';
            }
          });
        },
        borderRadius: BorderRadius.circular(AppDimensions.radiusInput),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.1) : AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusInput),
            border: Border.all(
              color: isSelected ? color : AppColors.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 18, color: isSelected ? color : AppColors.textSecondary),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? color : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
