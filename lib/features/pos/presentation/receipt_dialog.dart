import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_button.dart';
import '../../../models/transaction.dart';

class ReceiptDialog extends StatelessWidget {
  final TransactionRecord transaction;
  final VoidCallback onNewTransaction;

  const ReceiptDialog({
    super.key,
    required this.transaction,
    required this.onNewTransaction,
  });

  static Future<void> show(
    BuildContext context, {
    required TransactionRecord transaction,
    required VoidCallback onNewTransaction,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ReceiptDialog(
        transaction: transaction,
        onNewTransaction: onNewTransaction,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
      ),
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 750),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spaceMd),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success badge icon
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: AppColors.successBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.success,
                  size: 32,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Transaksi Berhasil!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                transaction.id,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),

              // Thermal Receipt simulation card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusInput),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Store details
                        const Text(
                          'KasirKu UMKM Store',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Jl. Malioboro No. 45, Yogyakarta\nTelp: 0812-3456-7890',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _dottedLine(),
                        const SizedBox(height: 8),

                        // Metadata
                        _metaRow('Waktu',
                            DateFormatter.formatDateTime(transaction.createdAt)),
                        _metaRow('Kasir', transaction.cashierName),
                        _metaRow('Layanan', transaction.isDineIn
                            ? (transaction.tableNumber != null
                                ? 'Dine-in (Meja ${transaction.tableNumber})'
                                : 'Dine-in')
                            : 'Takeaway'),
                        _metaRow('Metode', transaction.paymentMethod.label),
                        const SizedBox(height: 8),
                        _dottedLine(),
                        const SizedBox(height: 8),

                        // Purchased Items
                        ...transaction.items.map((item) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.productName,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        '${item.quantity} x ${CurrencyFormatter.format(item.price)}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  CurrencyFormatter.format(item.subtotal),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),

                        const SizedBox(height: 6),
                        _dottedLine(),
                        const SizedBox(height: 8),

                        // Calculations
                        _calcRow('Subtotal',
                            CurrencyFormatter.format(transaction.subtotal)),
                        if (transaction.discount > 0)
                          _calcRow('Diskon',
                              '-${CurrencyFormatter.format(transaction.discount)}',
                              isDiscount: true),
                        _calcRow('Total',
                            CurrencyFormatter.format(transaction.total),
                            isBold: true),
                        _calcRow('Bayar',
                            CurrencyFormatter.format(transaction.paymentAmount)),
                        _calcRow('Kembalian',
                            CurrencyFormatter.format(transaction.change)),

                        const SizedBox(height: 12),
                        _dottedLine(),
                        const SizedBox(height: 10),

                        // Footer note
                        const Text(
                          'Terima kasih atas kunjungan Anda!\nBarang yang sudah dibeli tidak dapat ditukar.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppDimensions.spaceSm),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text: 'Cetak Struk',
                      variant: ButtonVariant.secondary,
                      icon: Icons.print_outlined,
                      height: 42,
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Mengirim struk ke printer...'),
                            backgroundColor: AppColors.primary,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AppButton(
                      text: 'Bagikan',
                      variant: ButtonVariant.secondary,
                      icon: Icons.share_outlined,
                      height: 42,
                      onPressed: () {
                        final itemsTxt = transaction.items.map((i) => '${i.productName} (${i.quantity}x) = ${CurrencyFormatter.format(i.subtotal)}').join('\n');
                        final receiptText = '''
================================
     KASIRKU UMKM STORE
  Jl. Malioboro No. 45, Yogyakarta
================================
ID Transaksi: ${transaction.id}
Waktu: ${DateFormatter.formatDateTime(transaction.createdAt)}
Kasir: ${transaction.cashierName}
Layanan: ${transaction.isDineIn ? (transaction.tableNumber != null ? 'Dine-in (Meja ${transaction.tableNumber})' : 'Dine-in') : 'Takeaway'}
Metode: ${transaction.paymentMethod.label}
--------------------------------
$itemsTxt
--------------------------------
Subtotal: ${CurrencyFormatter.format(transaction.subtotal)}
Diskon: ${CurrencyFormatter.format(transaction.discount)}
Pajak: ${CurrencyFormatter.format(transaction.tax)}
TOTAL: ${CurrencyFormatter.format(transaction.total)}
Bayar: ${CurrencyFormatter.format(transaction.paymentAmount)}
Kembalian: ${CurrencyFormatter.format(transaction.change)}
================================
Terima kasih atas kunjungan Anda!
''';
                        Clipboard.setData(ClipboardData(text: receiptText));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Rincian struk lengkap disalin ke clipboard!'),
                            backgroundColor: AppColors.primary,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              AppButton(
                text: 'Transaksi Baru',
                width: double.infinity,
                height: 44,
                onPressed: () {
                  Navigator.of(context).pop();
                  onNewTransaction();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
          Text(value,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _calcRow(String label, String value,
      {bool isBold = false, bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isBold ? 13 : 11,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: isDiscount ? AppColors.danger : AppColors.textPrimary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isBold ? 14 : 11,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
              color: isDiscount
                  ? AppColors.danger
                  : (isBold ? AppColors.primary : AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dottedLine() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = (constraints.maxWidth / 6).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            count,
            (_) => Container(
              width: 3,
              height: 1,
              color: AppColors.border,
            ),
          ),
        );
      },
    );
  }
}
