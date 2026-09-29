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
import '../../../models/table_session.dart';
import '../../orders/presentation/orders_provider.dart';
import 'tables_provider.dart';

class TableSessionBillDialog extends ConsumerStatefulWidget {
  final RestaurantTable table;

  const TableSessionBillDialog({super.key, required this.table});

  static Future<void> show(BuildContext context, {required RestaurantTable table}) {
    return showDialog(
      context: context,
      builder: (context) => TableSessionBillDialog(table: table),
    );
  }

  @override
  ConsumerState<TableSessionBillDialog> createState() => _TableSessionBillDialogState();
}

class _TableSessionBillDialogState extends ConsumerState<TableSessionBillDialog> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(ordersStreamProvider);
    final sessionsAsync = ref.watch(tableSessionsStreamProvider);

    final allOrders = ordersAsync.value ?? [];
    final allSessions = sessionsAsync.value ?? [];

    // Find active session for table
    final session = allSessions.cast<TableSession?>().firstWhere(
          (s) =>
              s != null &&
              (s.id == widget.table.currentSessionId ||
                  (s.tableId == widget.table.id && s.status == SessionStatus.open)),
          orElse: () => null,
        );

    // Find relevant orders for table / session
    final tableOrders = allOrders.where((o) {
      if (o.orderStatus == OrderStatus.cancelled) return false;
      if (session != null && o.tableSessionId == session.id) return true;
      return o.tableId == widget.table.id || o.tableNumber == widget.table.tableNumber;
    }).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    double totalAmount = tableOrders.fold(0.0, (sum, o) => sum + o.total);
    double paidAmount = tableOrders
        .where((o) => o.isPaid || o.orderStatus == OrderStatus.paid)
        .fold(0.0, (sum, o) => sum + o.total);

    if (tableOrders.isEmpty && session != null) {
      totalAmount = session.totalAmount;
      paidAmount = session.paidAmount;
    }

    final outstanding = (totalAmount - paidAmount).clamp(0.0, double.infinity);
    final isFullyPaid = outstanding <= 0.0;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
      ),
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 760),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spaceMd),
          child: Column(
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
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.receipt_long_rounded,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tagihan Sesi Meja ${widget.table.tableNumber}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            widget.table.name,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
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

              // Session Info Card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.secondaryBtnBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Sesi: ${session?.id ?? widget.table.currentSessionId ?? 'Aktif'}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      session != null
                          ? 'Mulai: ${DateFormatter.formatTime(session.startedAt)}'
                          : 'Status: ${widget.table.status.label}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.spaceSm),

              // Orders List
              const Text(
                'Daftar Pesanan Meja:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),

              Expanded(
                child: tableOrders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.receipt_outlined,
                              size: 40,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Belum ada pesanan yang tercatat untuk sesi meja ini.',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            if (totalAmount > 0) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Total Sesi: ${CurrencyFormatter.format(totalAmount)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: tableOrders.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final order = tableOrders[index];
                          final orderNum = index + 1;
                          final orderIsPaid =
                              order.isPaid || order.orderStatus == OrderStatus.paid;

                          return AppCard(
                            padding: const EdgeInsets.all(12),
                            border: BorderSide(
                              color: orderIsPaid ? AppColors.border : AppColors.warning,
                              width: 1,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryLight,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            'Order #$orderNum',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '#${order.orderNumber}',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '(${order.customerName})',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: orderIsPaid
                                            ? AppColors.successBg
                                            : AppColors.warningBg,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        orderIsPaid ? 'Lunas' : 'Belum Lunas',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: orderIsPaid
                                              ? AppColors.success
                                              : AppColors.warning,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Items summary
                                ...order.items.map((item) => Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 2),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '${item.quantity}x ${item.productName}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            CurrencyFormatter.format(item.subtotal),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )),

                                const SizedBox(height: 6),
                                const Divider(height: 1),
                                const SizedBox(height: 6),

                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Subtotal: ${CurrencyFormatter.format(order.subtotal)}'
                                      '${order.tax > 0 ? ' + Pajak: ${CurrencyFormatter.format(order.tax)}' : ''}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                    Text(
                                      CurrencyFormatter.format(order.total),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),

                                // Pay order button if unpaid
                                if (!orderIsPaid) ...[
                                  const SizedBox(height: 6),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: AppButton(
                                      text: 'Lunasi Order Ini',
                                      variant: ButtonVariant.secondary,
                                      height: 32,
                                      icon: Icons.check_circle_outline,
                                      onPressed: () async {
                                        await ref
                                            .read(orderControllerProvider.notifier)
                                            .markOrderPaid(order.id);
                                      },
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
              ),

              const SizedBox(height: AppDimensions.spaceSm),
              const Divider(height: 1),
              const SizedBox(height: AppDimensions.spaceSm),

              // Total & Outstanding Summary Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isFullyPaid ? AppColors.successBg : AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Seluruh Pesanan Sesi',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          CurrencyFormatter.format(totalAmount),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Sudah Dibayar (Lunas)',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          CurrencyFormatter.format(paidAmount),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Sisa Tagihan (Outstanding)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          CurrencyFormatter.format(outstanding),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isFullyPaid ? AppColors.success : AppColors.danger,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.spaceSm),

              // Bottom Actions
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text: 'Tutup Dialog',
                      variant: ButtonVariant.secondary,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  if (!isFullyPaid) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: AppButton(
                        text: 'Lunasi Semua Sisa',
                        icon: Icons.payments_outlined,
                        variant: ButtonVariant.secondary,
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          for (final o in tableOrders) {
                            if (!o.isPaid) {
                              await ref
                                  .read(orderControllerProvider.notifier)
                                  .markOrderPaid(o.id);
                            }
                          }
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Seluruh pesanan meja telah ditandai lunas.'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(width: 8),
                  Expanded(
                    child: AppButton(
                      text: 'Tutup Meja',
                      icon: Icons.check_circle_rounded,
                      variant: ButtonVariant.primary,
                      isLoading: _isProcessing,
                      onPressed: () => _handleCloseTable(
                        context,
                        session: session,
                        totalAmount: totalAmount,
                        paidAmount: paidAmount,
                        isFullyPaid: isFullyPaid,
                        outstanding: outstanding,
                      ),
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

  Future<void> _handleCloseTable(
    BuildContext context, {
    required TableSession? session,
    required double totalAmount,
    required double paidAmount,
    required bool isFullyPaid,
    required double outstanding,
  }) async {
    if (!isFullyPaid) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
          ),
          backgroundColor: AppColors.surface,
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.warning),
              SizedBox(width: 8),
              Text('Tagihan Belum Lunas'),
            ],
          ),
          content: Text(
            'Sesi Meja ${widget.table.tableNumber} masih memiliki sisa tagihan sebesar '
            '${CurrencyFormatter.format(outstanding)}. '
            'Harap selesaikan pembayaran terlebih dahulu sebelum menutup meja.',
          ),
          actions: [
            AppButton(
              text: 'Mengerti',
              height: 38,
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      );
      return;
    }

    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        ),
        backgroundColor: AppColors.surface,
        title: Text('Tutup Meja ${widget.table.tableNumber}?'),
        content: const Text(
          'Seluruh tagihan telah lunas. Sesi meja ini akan ditutup '
          'dan status meja akan kembali menjadi "Tersedia".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          AppButton(
            text: 'Ya, Tutup Meja',
            height: 38,
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);
    final ok = await ref.read(tableControllerProvider.notifier).closeTable(
          widget.table.id,
          sessionId: session?.id ?? widget.table.currentSessionId,
          totalAmount: totalAmount,
          paidAmount: paidAmount,
        );

    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (ok) {
      nav.pop(); // close dialog
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Sesi Meja ${widget.table.tableNumber} berhasil ditutup. Meja kini Tersedia.',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Gagal menutup meja. Silakan coba lagi.'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }
}
