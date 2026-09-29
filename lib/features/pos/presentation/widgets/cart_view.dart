import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/pricing_calculator.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../cart_provider.dart';

class CartView extends ConsumerWidget {
  final VoidCallback onCheckout;

  const CartView({super.key, required this.onCheckout});

  void _showDiscountDialog(BuildContext context, WidgetRef ref) {
    final cart = ref.read(cartNotifierProvider);
    DiscountType selectedType = cart.discountType;
    final controller = TextEditingController(
      text: cart.discountValue > 0 ? cart.discountValue.toStringAsFixed(0) : '',
    );

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
              ),
              backgroundColor: AppColors.surface,
              title: const Text(
                'Atur Diskon Pesanan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Nominal (Rp)'),
                          selected: selectedType == DiscountType.fixed,
                          onSelected: (_) => setDialogState(
                              () => selectedType = DiscountType.fixed),
                          backgroundColor: AppColors.surface,
                          selectedColor: AppColors.primaryLight,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: selectedType == DiscountType.fixed
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: selectedType == DiscountType.fixed
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                          showCheckmark: false,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Persen (%)'),
                          selected: selectedType == DiscountType.percentage,
                          onSelected: (_) => setDialogState(
                              () => selectedType = DiscountType.percentage),
                          backgroundColor: AppColors.surface,
                          selectedColor: AppColors.primaryLight,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: selectedType == DiscountType.percentage
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: selectedType == DiscountType.percentage
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                          showCheckmark: false,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: selectedType == DiscountType.fixed
                        ? 'Nominal Potongan (Rp)'
                        : 'Persentase Diskon (0-100%)',
                    hint: selectedType == DiscountType.fixed ? '10000' : '10',
                    controller: controller,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                  ),
                ],
              ),
              actions: [
                if (cart.discountValue > 0)
                  TextButton(
                    onPressed: () {
                      ref.read(cartNotifierProvider.notifier).setDiscount(
                            type: DiscountType.fixed,
                            value: 0,
                          );
                      Navigator.of(dialogCtx).pop();
                    },
                    child: const Text('Hapus Diskon',
                        style: TextStyle(color: AppColors.danger)),
                  ),
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: const Text('Batal',
                      style: TextStyle(color: AppColors.textSecondary)),
                ),
                AppButton(
                  text: 'Terapkan',
                  height: 38,
                  onPressed: () {
                    final val = double.tryParse(controller.text) ?? 0.0;
                    ref.read(cartNotifierProvider.notifier).setDiscount(
                          type: selectedType,
                          value: val,
                        );
                    Navigator.of(dialogCtx).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartNotifierProvider);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(left: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shopping_cart_outlined,
                        size: 20, color: AppColors.primary),
                    const SizedBox(width: 8),
                    const Text(
                      'Keranjang',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (cart.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
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
                    ],
                  ],
                ),
                if (cart.isNotEmpty)
                  TextButton.icon(
                    onPressed: () =>
                        ref.read(cartNotifierProvider.notifier).clearCart(),
                    icon: const Icon(Icons.delete_sweep_outlined,
                        size: 16, color: AppColors.danger),
                    label: const Text(
                      'Kosongkan',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.danger,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Items list or empty state
          Expanded(
            child: cart.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppDimensions.spaceMd),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: AppColors.secondaryBtnBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.remove_shopping_cart_outlined,
                              size: 28,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Keranjang Masih Kosong',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Pilih produk dari katalog untuk menambahkan ke pesanan.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(AppDimensions.spaceSm),
                    itemCount: cart.items.length,
                    separatorBuilder: (_, index) => const Divider(height: 16),
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.product.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  CurrencyFormatter.format(item.product.price),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Qty adjustment buttons
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.secondaryBtnBg,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                InkWell(
                                  onTap: () => ref
                                      .read(cartNotifierProvider.notifier)
                                      .decrementItem(item.product.id),
                                  borderRadius: const BorderRadius.horizontal(
                                      left: Radius.circular(7)),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 6),
                                    child: Icon(Icons.remove, size: 16),
                                  ),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 8),
                                  child: Text(
                                    '${item.quantity}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: item.quantity < item.product.stock
                                      ? () => ref
                                          .read(cartNotifierProvider.notifier)
                                          .incrementItem(item.product.id)
                                      : null,
                                  borderRadius: const BorderRadius.horizontal(
                                      right: Radius.circular(7)),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 6),
                                    child: Icon(
                                      Icons.add,
                                      size: 16,
                                      color: item.quantity < item.product.stock
                                          ? AppColors.textPrimary
                                          : AppColors.textMuted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Subtotal
                          SizedBox(
                            width: 76,
                            child: Text(
                              CurrencyFormatter.format(item.subtotal),
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),

          // Footer summary & checkout button
          if (cart.isNotEmpty) ...[
            const Divider(height: 1),
            Container(
              padding: const EdgeInsets.all(AppDimensions.spaceSm),
              decoration: const BoxDecoration(
                color: AppColors.surface,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Subtotal',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        CurrencyFormatter.format(cart.subtotal),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Discount row + button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: () => _showDiscountDialog(context, ref),
                        child: Row(
                          children: [
                            Text(
                              cart.discount > 0
                                  ? (cart.discountType == DiscountType.percentage
                                      ? 'Diskon (${cart.discountValue.toStringAsFixed(0)}%)'
                                      : 'Diskon (Rp)')
                                  : 'Tambah Diskon',
                              style: TextStyle(
                                fontSize: 13,
                                color: cart.discount > 0
                                    ? AppColors.danger
                                    : AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.edit_outlined,
                                size: 14,
                                color: cart.discount > 0
                                    ? AppColors.danger
                                    : AppColors.primary),
                          ],
                        ),
                      ),
                      Text(
                        cart.discount > 0
                            ? '-${CurrencyFormatter.format(cart.discount)}'
                            : 'Rp 0',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: cart.discount > 0
                              ? AppColors.danger
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),

                  // Tax row if tax > 0
                  if (cart.taxAmount > 0) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Pajak PPN (${cart.taxRate.toStringAsFixed(0)}%)',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          CurrencyFormatter.format(cart.taxAmount),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Tagihan',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        CurrencyFormatter.format(cart.total),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  AppButton(
                    text: 'Bayar Sekarang',
                    icon: Icons.payments_outlined,
                    width: double.infinity,
                    onPressed: onCheckout,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
