import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../models/stock_movement.dart';
import '../../../models/transaction.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../inventory/presentation/stock_provider.dart';
import '../../products/presentation/products_provider.dart';
import '../../transactions/presentation/transactions_provider.dart';
import 'cart_provider.dart';
import 'receipt_dialog.dart';

class CheckoutDialog extends ConsumerStatefulWidget {
  const CheckoutDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const CheckoutDialog(),
    );
  }

  @override
  ConsumerState<CheckoutDialog> createState() => _CheckoutDialogState();
}

class _CheckoutDialogState extends ConsumerState<CheckoutDialog> {
  PaymentMethod _selectedMethod = PaymentMethod.cash;
  final _amountController = TextEditingController();
  String? _errorMessage;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    final cart = ref.read(cartNotifierProvider);
    _amountController.text = cart.total.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  double get _paidAmount => double.tryParse(_amountController.text) ?? 0.0;

  void _setAmount(double amount) {
    setState(() {
      _amountController.text = amount.toStringAsFixed(0);
      _errorMessage = null;
    });
  }

  Future<void> _processPayment() async {
    final cart = ref.read(cartNotifierProvider);
    final user = ref.read(currentUserProvider);
    final paid = _paidAmount;

    if (!cart.pricing.isPaymentValid(paid)) {
      setState(() {
        _errorMessage = 'Pembayaran tidak mencukupi';
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    final now = DateTime.now();
    final trxId =
        'TRX-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${(now.millisecondsSinceEpoch % 1000).toString().padLeft(3, '0')}';

    final transaction = TransactionRecord(
      id: trxId,
      cashierId: user?.id ?? 'cashier-01',
      cashierName: user?.name ?? 'Admin KasirKu',
      items: cart.items.map((i) => i.toTransactionItem()).toList(),
      subtotal: cart.subtotal,
      discount: cart.discount,
      tax: cart.taxAmount,
      total: cart.total,
      paymentMethod: _selectedMethod,
      paymentAmount: paid,
      change: cart.pricing.calculateChange(paid),
      createdAt: now,
      status: 'success',
    );

    // Save transaction
    final trxRepo = ref.read(transactionRepositoryProvider);
    await trxRepo.createTransaction(transaction);

    // Reduce stock and record movement for each product
    final prodRepo = ref.read(productRepositoryProvider);
    final stockRepo = ref.read(stockRepositoryProvider);
    for (final item in cart.items) {
      await prodRepo.adjustStock(item.product.id, item.quantity);
      final prev = item.product.stock;
      final next = (prev - item.quantity).clamp(0, 999999);
      await stockRepo.recordMovement(
        StockMovement(
          id: 'SM-${now.millisecondsSinceEpoch}-${item.product.id}',
          productId: item.product.id,
          productName: item.product.name,
          type: StockMovementType.sale,
          quantity: -item.quantity,
          previousStock: prev,
          newStock: next,
          reason: 'Penjualan kasir #$trxId',
          createdAt: now,
          createdBy: user?.name ?? 'Kasir',
        ),
      );
    }

    // Clear cart
    ref.read(cartNotifierProvider.notifier).clearCart();

    if (!mounted) return;
    Navigator.of(context).pop(); // close checkout dialog

    // Open Receipt dialog
    ReceiptDialog.show(
      context,
      transaction: transaction,
      onNewTransaction: () {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartNotifierProvider);
    final total = cart.total;
    final change = cart.pricing.calculateChange(_paidAmount);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
      ),
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 720),
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
                  const Text(
                    'Checkout Pembayaran',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Total Tagihan Banner
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusInput),
                        ),
                        child: Column(
                          children: [
                            if (cart.discount > 0 || cart.taxAmount > 0) ...[
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Subtotal',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary)),
                                  Text(CurrencyFormatter.format(cart.subtotal),
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                              if (cart.discount > 0) ...[
                                const SizedBox(height: 2),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Diskon',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.danger)),
                                    Text(
                                        '-${CurrencyFormatter.format(cart.discount)}',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.danger)),
                                  ],
                                ),
                              ],
                              if (cart.taxAmount > 0) ...[
                                const SizedBox(height: 2),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                        'Pajak PPN (${cart.taxRate.toStringAsFixed(0)}%)',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary)),
                                    Text(
                                        CurrencyFormatter.format(cart.taxAmount),
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ],
                              const Divider(height: 12),
                            ],
                            const Text(
                              'Total Pembayaran',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              CurrencyFormatter.format(total),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spaceSm),

                      // Payment Method Selector
                      const Text(
                        'Metode Pembayaran',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spaceXs),
                      Row(
                        children: [
                          _buildMethodOption(
                            method: PaymentMethod.cash,
                            icon: Icons.money_rounded,
                            label: 'Tunai',
                          ),
                          const SizedBox(width: 8),
                          _buildMethodOption(
                            method: PaymentMethod.qris,
                            icon: Icons.qr_code_rounded,
                            label: 'QRIS',
                          ),
                          const SizedBox(width: 8),
                          _buildMethodOption(
                            method: PaymentMethod.transfer,
                            icon: Icons.account_balance_rounded,
                            label: 'Transfer',
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.spaceSm),

                      // Amount Input
                      AppTextField(
                        label: 'Jumlah Pembayaran (Rp)',
                        hint: '0',
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        onChanged: (_) {
                          setState(() {
                            _errorMessage = null;
                          });
                        },
                      ),
                      const SizedBox(height: AppDimensions.spaceXs),

                      // Quick Cash Buttons
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _quickCashBtn('Uang Pas', total),
                          _quickCashBtn('50.000', 50000),
                          _quickCashBtn('100.000', 100000),
                          _quickCashBtn('200.000', 200000),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.spaceSm),

                      // Error message if any
                      if (_errorMessage != null)
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.dangerBg,
                            borderRadius:
                                BorderRadius.circular(AppDimensions.radiusInput),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded,
                                  size: 16, color: AppColors.danger),
                              const SizedBox(width: 8),
                              Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.danger,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: AppDimensions.spaceSm),

                      // Kembalian Display
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryBtnBg,
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusInput),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Kembalian',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              CurrencyFormatter.format(change),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: change > 0
                                    ? AppColors.success
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
                      text: 'Konfirmasi Bayar',
                      isLoading: _isProcessing,
                      onPressed: _processPayment,
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

  Widget _buildMethodOption({
    required PaymentMethod method,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _selectedMethod == method;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedMethod = method;
            if (method != PaymentMethod.cash) {
              final cart = ref.read(cartNotifierProvider);
              _amountController.text = cart.total.toStringAsFixed(0);
            }
          });
        },
        borderRadius: BorderRadius.circular(AppDimensions.radiusInput),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryLight : AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusInput),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 22,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color:
                      isSelected ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quickCashBtn(String label, double amount) {
    return InkWell(
      onTap: () => _setAmount(amount),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.secondaryBtnBg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
