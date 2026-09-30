import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../models/online_payment.dart';
import '../../../../models/restaurant_order.dart';
import '../../../../models/restaurant_table.dart';
import '../../../orders/presentation/orders_provider.dart';
import '../../../settings/presentation/settings_provider.dart';
import '../customer_order_provider.dart';

class OnlinePaymentDialog extends ConsumerStatefulWidget {
  final RestaurantTable table;
  final ValueChanged<RestaurantOrder> onPaymentSuccess;

  const OnlinePaymentDialog({
    super.key,
    required this.table,
    required this.onPaymentSuccess,
  });

  static Future<void> show(
    BuildContext context, {
    required RestaurantTable table,
    required ValueChanged<RestaurantOrder> onPaymentSuccess,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => OnlinePaymentDialog(
        table: table,
        onPaymentSuccess: onPaymentSuccess,
      ),
    );
  }

  @override
  ConsumerState<OnlinePaymentDialog> createState() => _OnlinePaymentDialogState();
}

class _OnlinePaymentDialogState extends ConsumerState<OnlinePaymentDialog> {
  OnlinePaymentMethod _method = OnlinePaymentMethod.qris;
  bool _isCreatingOrder = true;
  bool _isVerifying = false;
  RestaurantOrder? _createdOrder;
  OnlinePayment? _createdPayment;

  @override
  void initState() {
    super.initState();
    _createPendingOrder();
  }

  Future<void> _createPendingOrder() async {
    final cart = ref.read(customerCartNotifierProvider);
    final settings = ref.read(currentStoreSettingsProvider);
    final taxRate = settings.taxRate;
    final taxAmount = (cart.subtotal * (taxRate / 100)).roundToDouble();
    final grandTotal = cart.subtotal + taxAmount;

    final now = DateTime.now();
    final randomSuffix = (now.millisecondsSinceEpoch % 1000).toString().padLeft(3, '0');
    final orderId = 'ord-${now.millisecondsSinceEpoch % 100000}';
    final orderNum = 'ORD-${widget.table.tableNumber}-$randomSuffix';
    final paymentId = 'pay-${now.millisecondsSinceEpoch % 100000}';

    final orderItems = cart.items
        .map((i) => RestaurantOrderItem.fromCustomerCartItem(i))
        .toList();

    final order = RestaurantOrder(
      id: orderId,
      tableId: widget.table.id,
      tableSessionId: widget.table.currentSessionId,
      tableNumber: widget.table.tableNumber,
      orderNumber: orderNum,
      customerName: cart.customerName.isEmpty ? 'Pelanggan Meja ${widget.table.tableNumber}' : cart.customerName,
      items: orderItems,
      subtotal: cart.subtotal,
      discount: 0,
      tax: taxAmount,
      total: grandTotal,
      paymentStatus: 'pending',
      orderStatus: OrderStatus.pendingPayment,
      source: OrderSource.tableQr,
      createdAt: now,
      updatedAt: now,
    );

    final payment = OnlinePayment(
      id: paymentId,
      orderId: orderId,
      tableId: widget.table.id,
      tableNumber: widget.table.tableNumber,
      customerName: order.customerName,
      amount: order.total,
      method: _method,
      status: OnlinePaymentStatus.pending,
      paymentReference: '00020101021226590014ID.LINKAJA.WWW01189360091800000000005204581253033605802ID5914KASIRKU_STORE6010YOGYAKARTA6304$orderNum',
      createdAt: now,
    );

    final repo = ref.read(orderRepositoryProvider);
    await repo.createOrder(order);
    await repo.createPayment(payment);

    if (mounted) {
      setState(() {
        _createdOrder = order;
        _createdPayment = payment;
        _isCreatingOrder = false;
      });
    }
  }

  Future<void> _verifyPayment() async {
    if (_createdPayment == null) return;
    setState(() => _isVerifying = true);

    // Call payment verification service
    final ok = await ref
        .read(orderControllerProvider.notifier)
        .verifyPayment(_createdPayment!.id);

    if (ok && mounted) {
      final updatedOrder = _createdOrder!.copyWith(
        paymentStatus: 'paid',
        orderStatus: OrderStatus.paid,
      );

      // Clear customer cart
      ref.read(customerCartNotifierProvider.notifier).clearCart();

      Navigator.of(context).pop();
      widget.onPaymentSuccess(updatedOrder);
    } else {
      if (mounted) {
        setState(() => _isVerifying = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pembayaran belum terdeteksi. Silakan coba lagi setelah transfer.'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCreatingOrder) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        ),
        backgroundColor: AppColors.surface,
        child: const Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 16),
              Text('Menyiapkan Tagihan Pembayaran...',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
    }

    final total = _createdOrder?.total ?? 0.0;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
      ),
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spaceMd),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pembayaran Online',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Meja ${widget.table.tableNumber} • ${_createdOrder?.orderNumber}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
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
                const SizedBox(height: 16),

                // Amount Banner
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Bayar',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        CurrencyFormatter.format(total),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Payment Method Selector
                const Text('Pilih Metode Pembayaran:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text('QRIS')),
                        selected: _method == OnlinePaymentMethod.qris,
                        onSelected: (_) =>
                            setState(() => _method = OnlinePaymentMethod.qris),
                        selectedColor: AppColors.primaryLight,
                        backgroundColor: AppColors.surface,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: _method == OnlinePaymentMethod.qris
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: _method == OnlinePaymentMethod.qris
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                        showCheckmark: false,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text('Virtual Account')),
                        selected: _method != OnlinePaymentMethod.qris,
                        onSelected: (_) =>
                            setState(() => _method = OnlinePaymentMethod.vaBca),
                        selectedColor: AppColors.primaryLight,
                        backgroundColor: AppColors.surface,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: _method != OnlinePaymentMethod.qris
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: _method != OnlinePaymentMethod.qris
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                        showCheckmark: false,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Method Body
                if (_method == OnlinePaymentMethod.qris) ...[
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: QrImageView(
                        data: _createdPayment?.paymentReference ?? 'QRIS_DATA',
                        version: QrVersions.auto,
                        size: 160,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Scan QRIS dengan GoPay, OVO, Dana, ShopeePay, atau BCA Mobile',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryBtnBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Nomor Virtual Account BCA:',
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        const SelectableText(
                          '80777 0812 3456 7890',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text('Atas Nama: KASIRKU DINING',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Verify Button
                AppButton(
                  text: 'Verifikasi Pembayaran Saya',
                  icon: Icons.check_circle_outline_rounded,
                  height: 48,
                  isLoading: _isVerifying,
                  onPressed: _verifyPayment,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Sistem otomatis memverifikasi webhook pembayaran dari payment gateway.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
