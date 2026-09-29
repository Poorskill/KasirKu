import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../models/restaurant_table.dart';
import '../customer_order_provider.dart';

class CustomerCartSheet extends ConsumerStatefulWidget {
  final RestaurantTable table;
  final VoidCallback onProceedToPayment;

  const CustomerCartSheet({
    super.key,
    required this.table,
    required this.onProceedToPayment,
  });

  static Future<void> show(
    BuildContext context, {
    required RestaurantTable table,
    required VoidCallback onProceedToPayment,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => CustomerCartSheet(
        table: table,
        onProceedToPayment: onProceedToPayment,
      ),
    );
  }

  @override
  ConsumerState<CustomerCartSheet> createState() => _CustomerCartSheetState();
}

class _CustomerCartSheetState extends ConsumerState<CustomerCartSheet> {
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final curName = ref.read(customerCartNotifierProvider).customerName;
    _nameController.text = curName;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(customerCartNotifierProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle Bar
            Container(
              width: 38,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Sheet Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.shopping_bag_outlined,
                          color: AppColors.primary, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'Pesanan Meja ${widget.table.tableNumber}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  if (cart.isNotEmpty)
                    TextButton(
                      onPressed: () => ref
                          .read(customerCartNotifierProvider.notifier)
                          .clearCart(),
                      child: const Text('Kosongkan',
                          style: TextStyle(color: AppColors.danger, fontSize: 12)),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Items List
            Expanded(
              child: cart.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: const BoxDecoration(
                                color: AppColors.secondaryBtnBg,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.remove_shopping_cart_outlined,
                                  size: 36, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Keranjang Pesanan Kosong',
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Pilih menu makanan dan minuman favorit Anda di atas.',
                              style: TextStyle(
                                  fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Customer Name Input
                        AppTextField(
                          label: 'Nama Pelanggan (Untuk Pemanggilan) *',
                          hint: 'Contoh: Kak Budi',
                          controller: _nameController,
                          prefixIcon: const Icon(Icons.person_outline,
                              size: 18, color: AppColors.textSecondary),
                          onChanged: (val) {
                            ref
                                .read(customerCartNotifierProvider.notifier)
                                .setCustomerName(val.trim());
                          },
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Daftar Menu:',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),

                        // Item Rows
                        ...cart.items.map((item) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.product.name,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          Text(
                                            CurrencyFormatter.format(
                                                item.unitPrice),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Qty Control
                                    Row(
                                      children: [
                                        InkWell(
                                          onTap: () => ref
                                              .read(customerCartNotifierProvider
                                                  .notifier)
                                              .decrementQuantity(item.id),
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: AppColors.surface,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              border: Border.all(
                                                  color: AppColors.border),
                                            ),
                                            child: const Icon(Icons.remove,
                                                size: 14),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10),
                                          child: Text(
                                            '${item.quantity}',
                                            style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w800),
                                          ),
                                        ),
                                        InkWell(
                                          onTap: item.quantity <
                                                  item.product.stock
                                              ? () => ref
                                                  .read(
                                                      customerCartNotifierProvider
                                                          .notifier)
                                                  .incrementQuantity(item.id)
                                              : null,
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: AppColors.surface,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              border: Border.all(
                                                  color: AppColors.border),
                                            ),
                                            child: const Icon(Icons.add,
                                                size: 14),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                // Modifiers
                                if (item.selectedModifiers.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 4,
                                    runSpacing: 4,
                                    children: item.selectedModifiers.map((m) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.surface,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          border: Border.all(
                                              color: AppColors.border),
                                        ),
                                        child: Text(
                                          '${m.optionName}${m.extraPrice > 0 ? " (+${CurrencyFormatter.format(m.extraPrice)})" : ""}',
                                          style: const TextStyle(
                                              fontSize: 10,
                                              color: AppColors.textSecondary),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                                // Notes
                                if (item.note.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Catatan: "${item.note}"',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontStyle: FontStyle.italic,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
            ),

            // Sticky Bottom Checkout Button
            if (cart.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Pembayaran',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            CurrencyFormatter.format(cart.subtotal),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      AppButton(
                        text: 'Lanjut ke Pembayaran Online',
                        icon: Icons.payment_rounded,
                        width: double.infinity,
                        height: 48,
                        onPressed: () {
                          if (_nameController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Silakan masukkan nama pemesan terlebih dahulu'),
                                backgroundColor: AppColors.warning,
                              ),
                            );
                            return;
                          }
                          ref
                              .read(customerCartNotifierProvider.notifier)
                              .setCustomerName(_nameController.text.trim());
                          Navigator.pop(context);
                          widget.onProceedToPayment();
                        },
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
