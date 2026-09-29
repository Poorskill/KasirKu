import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/pricing_calculator.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../tables/presentation/tables_provider.dart';
import '../cart_provider.dart';

class CartView extends ConsumerWidget {
  final VoidCallback onCheckout;

  const CartView({super.key, required this.onCheckout});

  void _showTableSelector(BuildContext context, WidgetRef ref) {
    final tables = ref.read(tablesStreamProvider).value ?? [];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: AppColors.surface,
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.spaceMd),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Pilih Meja untuk Pesanan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        ref
                            .read(cartNotifierProvider.notifier)
                            .setSelectedTable(null);
                        Navigator.pop(sheetCtx);
                      },
                      child: const Text('Tanpa Meja'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (tables.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text('Belum ada data meja di restoran.'),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: tables.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, idx) {
                        final tbl = tables[idx];
                        final isAvailable = tbl.isAvailable;
                        final isOccupied = tbl.isOccupied;

                        Color statusColor = AppColors.success;
                        if (isOccupied) statusColor = AppColors.primary;
                        if (tbl.isReserved) statusColor = AppColors.warning;

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isAvailable
                                ? AppColors.successBg
                                : AppColors.primaryLight,
                            child: Text(
                              tbl.tableNumber,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          title: Text(
                            'Meja ${tbl.tableNumber} • ${tbl.name}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            'Kapasitas: ${tbl.capacity} Orang • Status: ${tbl.status.label}',
                            style: TextStyle(
                              fontSize: 12,
                              color: statusColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          onTap: () {
                            ref
                                .read(cartNotifierProvider.notifier)
                                .setSelectedTable(tbl);
                            Navigator.pop(sheetCtx);
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

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

          // Order Type Selector (Dine-in vs Takeaway)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.restaurant_rounded, size: 14),
                            SizedBox(width: 6),
                            Text('Dine-in (Meja)'),
                          ],
                        ),
                        selected: cart.isDineIn,
                        onSelected: (_) => ref
                            .read(cartNotifierProvider.notifier)
                            .setOrderType(PosOrderType.dineIn),
                        backgroundColor: AppColors.surface,
                        selectedColor: AppColors.primaryLight,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: cart.isDineIn ? FontWeight.w700 : FontWeight.w500,
                          color: cart.isDineIn ? AppColors.primary : AppColors.textSecondary,
                        ),
                        showCheckmark: false,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shopping_bag_outlined, size: 14),
                            SizedBox(width: 6),
                            Text('Takeaway'),
                          ],
                        ),
                        selected: cart.isTakeaway,
                        onSelected: (_) => ref
                            .read(cartNotifierProvider.notifier)
                            .setOrderType(PosOrderType.takeaway),
                        backgroundColor: AppColors.surface,
                        selectedColor: AppColors.primaryLight,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: cart.isTakeaway ? FontWeight.w700 : FontWeight.w500,
                          color: cart.isTakeaway ? AppColors.primary : AppColors.textSecondary,
                        ),
                        showCheckmark: false,
                      ),
                    ),
                  ],
                ),
                if (cart.isDineIn) ...[
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () => _showTableSelector(context, ref),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: cart.selectedTable != null
                            ? AppColors.primaryLight
                            : AppColors.secondaryBtnBg,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
                        border: Border.all(
                          color: cart.selectedTable != null
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.table_restaurant_rounded,
                                size: 16,
                                color: cart.selectedTable != null
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                cart.selectedTable != null
                                    ? 'Meja ${cart.selectedTable!.tableNumber} (${cart.selectedTable!.name})'
                                    : 'Pilih Meja Resto...',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: cart.selectedTable != null
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: cart.selectedTable != null
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          Icon(
                            Icons.arrow_drop_down,
                            size: 18,
                            color: cart.selectedTable != null
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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
