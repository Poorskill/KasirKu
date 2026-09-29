import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../models/restaurant_order.dart';
import '../../../models/restaurant_table.dart';
import '../../orders/presentation/orders_provider.dart';
import 'widgets/call_waiter_dialog.dart';

class CustomerOrderTrackingScreen extends ConsumerWidget {
  final String orderId;
  final RestaurantTable table;
  final VoidCallback onReorder;

  const CustomerOrderTrackingScreen({
    super.key,
    required this.orderId,
    required this.table,
    required this.onReorder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersStreamProvider);

    final currentOrder = ordersAsync.maybeWhen(
      data: (list) {
        final matches = list.where((o) => o.id == orderId);
        return matches.isNotEmpty ? matches.first : null;
      },
      orElse: () => null,
    );

    final status = currentOrder?.orderStatus ?? OrderStatus.paid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Status Pesanan Meja ${table.tableNumber}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.room_service_rounded, color: AppColors.warning),
            tooltip: 'Panggil Pelayan',
            onPressed: () => CallWaiterDialog.show(context, table: table),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.spaceMd),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Success Banner
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: AppColors.successBg,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.success,
                          size: 36,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Pembayaran Berhasil Diverifikasi!',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currentOrder?.orderNumber ?? 'Pesanan',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Pesanan Anda sedang diteruskan langsung ke layar Dapur & Kasir.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Order State Timeline Tracker
                AppCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Progres Pesanan Realtime',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 16),
                      _buildTimelineStep(
                        title: 'Pembayaran Lunas',
                        subtitle: 'Transaksi terverifikasi via QRIS / Bank Transfer',
                        isDone: true,
                        isActive: status == OrderStatus.paid,
                      ),
                      _buildTimelineStep(
                        title: 'Pesanan Diterima Kasir',
                        subtitle: 'Tiket pesanan dikonfirmasi oleh staf restoran',
                        isDone: _stepIndex(status) >= 1,
                        isActive: status == OrderStatus.confirmed,
                      ),
                      _buildTimelineStep(
                        title: 'Sedang Dimasak di Dapur',
                        subtitle: 'Koki sedang menyiapkan makanan Anda dengan higienis',
                        isDone: _stepIndex(status) >= 2,
                        isActive: status == OrderStatus.preparing,
                      ),
                      _buildTimelineStep(
                        title: 'Siap Diantar ke Meja',
                        subtitle: 'Makanan telah siap di counter saji',
                        isDone: _stepIndex(status) >= 3,
                        isActive: status == OrderStatus.ready,
                      ),
                      _buildTimelineStep(
                        title: 'Disajikan & Selesai',
                        subtitle: 'Selamat menikmati hidangan KasirKu!',
                        isDone: _stepIndex(status) >= 4,
                        isActive: status == OrderStatus.served ||
                            status == OrderStatus.completed,
                        isLast: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Order Items Summary
                if (currentOrder != null)
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Rincian Menu',
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w700),
                            ),
                            Text(
                              DateFormatter.formatTime(currentOrder.createdAt),
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        const Divider(height: 16),
                        ...currentOrder.items.map((item) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${item.quantity}x ',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700)),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(item.productName,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600)),
                                      if (item.modifiers.isNotEmpty)
                                        Text(
                                          item.modifiers
                                              .map((m) => m.optionName)
                                              .join(', '),
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textSecondary),
                                        ),
                                      if (item.note.isNotEmpty)
                                        Text('Note: ${item.note}',
                                            style: const TextStyle(
                                                fontSize: 11,
                                                fontStyle: FontStyle.italic,
                                                color: AppColors.textSecondary)),
                                    ],
                                  ),
                                ),
                                Text(
                                  CurrencyFormatter.format(item.subtotal),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          );
                        }),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Pembayaran',
                                style: TextStyle(fontWeight: FontWeight.w700)),
                            Text(
                              CurrencyFormatter.format(currentOrder.total),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 20),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        text: 'Panggil Pelayan',
                        icon: Icons.room_service_outlined,
                        variant: ButtonVariant.secondary,
                        height: 48,
                        onPressed: () => CallWaiterDialog.show(context, table: table),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppButton(
                        text: '+ Tambah Pesanan',
                        icon: Icons.add_circle_outline,
                        height: 48,
                        onPressed: onReorder,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _stepIndex(OrderStatus s) {
    switch (s) {
      case OrderStatus.paid:
        return 0;
      case OrderStatus.confirmed:
        return 1;
      case OrderStatus.preparing:
        return 2;
      case OrderStatus.ready:
        return 3;
      case OrderStatus.served:
      case OrderStatus.completed:
        return 4;
      default:
        return 0;
    }
  }

  Widget _buildTimelineStep({
    required String title,
    required String subtitle,
    required bool isDone,
    required bool isActive,
    bool isLast = false,
  }) {
    Color iconColor;
    Color iconBg;

    if (isActive) {
      iconColor = Colors.white;
      iconBg = AppColors.primary;
    } else if (isDone) {
      iconColor = AppColors.success;
      iconBg = AppColors.successBg;
    } else {
      iconColor = AppColors.textMuted;
      iconBg = AppColors.secondaryBtnBg;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isDone ? Icons.check : Icons.circle,
                size: isDone ? 16 : 8,
                color: iconColor,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 38,
                color: isDone ? AppColors.success : AppColors.border,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isActive || isDone ? FontWeight.w700 : FontWeight.w500,
                    color: isActive
                        ? AppColors.primary
                        : (isDone ? AppColors.textPrimary : AppColors.textSecondary),
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
