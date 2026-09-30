import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/state_views.dart';
import '../../../models/restaurant_order.dart';
import 'orders_provider.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(ordersStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ordersAsync.when(
          loading: () =>
              const LoadingWidget(message: 'Memuat antrean pesanan...'),
          error: (e, _) => ErrorStateWidget(message: e.toString()),
          data: (allOrders) {
            final newOrders = allOrders
                .where((o) => o.orderStatus == OrderStatus.paid)
                .toList();
            final preparingOrders = allOrders
                .where((o) =>
                    o.orderStatus == OrderStatus.confirmed ||
                    o.orderStatus == OrderStatus.preparing)
                .toList();
            final readyOrders = allOrders
                .where((o) => o.orderStatus == OrderStatus.ready)
                .toList();
            final completedOrders = allOrders
                .where((o) =>
                    o.orderStatus == OrderStatus.served ||
                    o.orderStatus == OrderStatus.completed)
                .toList();

            return Padding(
              padding: EdgeInsets.all(
                context.isMobile
                    ? AppDimensions.spaceSm
                    : AppDimensions.spaceMd,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Papan Pesanan Restoran',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Manajemen antrean pesanan dari QR meja, kasir, dan pelayan',
                            style: TextStyle(
                              fontSize: context.isMobile ? 12 : 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      if (newOrders.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.dangerBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.danger),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.notifications_active_rounded,
                                  size: 16, color: AppColors.danger),
                              const SizedBox(width: 6),
                              Text(
                                '${newOrders.length} Pesanan Baru!',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.danger,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.spaceMd),

                  // Kanban Tabs
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusButton),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      indicatorColor: AppColors.primary,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: AppColors.textSecondary,
                      labelStyle: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13),
                      tabs: [
                        Tab(text: 'Semua (${allOrders.length})'),
                        Tab(text: 'Baru Masuk (${newOrders.length})'),
                        Tab(text: 'Dimasak (${preparingOrders.length})'),
                        Tab(text: 'Siap Diantar (${readyOrders.length})'),
                        Tab(text: 'Selesai (${completedOrders.length})'),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spaceMd),

                  // Tab Views
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildOrdersGrid(allOrders),
                        _buildOrdersGrid(newOrders),
                        _buildOrdersGrid(preparingOrders),
                        _buildOrdersGrid(readyOrders),
                        _buildOrdersGrid(completedOrders),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildOrdersGrid(List<RestaurantOrder> orders) {
    if (orders.isEmpty) {
      return const EmptyStateWidget(
        title: 'Tidak ada pesanan',
        description: 'Belum ada tiket pesanan pada status ini.',
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 1;
        if (constraints.maxWidth > 1024) {
          crossAxisCount = 3;
        } else if (constraints.maxWidth > 640) {
          crossAxisCount = 2;
        }

        return GridView.builder(
          itemCount: orders.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.05,
          ),
          itemBuilder: (context, index) {
            final order = orders[index];
            return _OrderCard(order: order);
          },
        );
      },
    );
  }
}

class _OrderCard extends ConsumerWidget {
  final RestaurantOrder order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Color statusBg;
    Color statusFg;

    switch (order.orderStatus) {
      case OrderStatus.paid:
        statusBg = AppColors.dangerBg;
        statusFg = AppColors.danger;
      case OrderStatus.confirmed:
      case OrderStatus.preparing:
        statusBg = AppColors.warningBg;
        statusFg = AppColors.warning;
      case OrderStatus.ready:
        statusBg = AppColors.primaryLight;
        statusFg = AppColors.primary;
      case OrderStatus.served:
      case OrderStatus.completed:
        statusBg = AppColors.successBg;
        statusFg = AppColors.success;
      case OrderStatus.cancelled:
      case OrderStatus.refunded:
        statusBg = AppColors.secondaryBtnBg;
        statusFg = AppColors.textSecondary;
      case OrderStatus.pendingPayment:
        statusBg = AppColors.secondaryBtnBg;
        statusFg = AppColors.textMuted;
    }

    return AppCard(
      padding: const EdgeInsets.all(14),
      border: BorderSide(
        color: order.orderStatus == OrderStatus.paid
            ? AppColors.danger
            : AppColors.border,
        width: order.orderStatus == OrderStatus.paid ? 1.5 : 1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Card Header: Table + Time + Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'MEJA ${order.tableNumber}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    order.orderNumber,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  order.orderStatus.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusFg,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pemesan: ${order.customerName}',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary),
              ),
              Text(
                DateFormatter.formatTime(order.createdAt),
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),

          // Items list
          Expanded(
            child: ListView.builder(
              itemCount: order.items.length,
              itemBuilder: (context, idx) {
                final item = order.items[idx];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${item.quantity}x ',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w800),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.productName,
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            if (item.modifiers.isNotEmpty)
                              Text(
                                item.modifiers.map((m) => m.optionName).join(', '),
                                style: const TextStyle(
                                    fontSize: 10, color: AppColors.textSecondary),
                              ),
                            if (item.note.isNotEmpty)
                              Text(
                                'Note: "${item.note}"',
                                style: const TextStyle(
                                    fontSize: 10,
                                    fontStyle: FontStyle.italic,
                                    color: AppColors.warning),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          const SizedBox(height: 8),

          // Total & Action Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total (Lunas)',
                      style: TextStyle(
                          fontSize: 10, color: AppColors.textSecondary)),
                  Text(
                    CurrencyFormatter.format(order.total),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              _buildActionButton(context, ref),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, WidgetRef ref) {
    switch (order.orderStatus) {
      case OrderStatus.paid:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppButton(
              text: 'Terima',
              icon: Icons.check,
              height: 36,
              onPressed: () {
                ref
                    .read(orderControllerProvider.notifier)
                    .updateStatus(order.id, OrderStatus.confirmed);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Pesanan ${order.orderNumber} diterima dan diteruskan ke Dapur'),
                    backgroundColor: AppColors.primary,
                  ),
                );
              },
            ),
            const SizedBox(width: 6),
            SizedBox(
              height: 36,
              child: IconButton(
                icon: const Icon(Icons.cancel_outlined, size: 18, color: AppColors.danger),
                tooltip: 'Batalkan Pesanan',
                onPressed: () {
                  ref
                      .read(orderControllerProvider.notifier)
                      .cancelOrder(order.id, reason: 'Ditolak kasir');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Pesanan ${order.orderNumber} dibatalkan'),
                      backgroundColor: AppColors.danger,
                    ),
                  );
                },
              ),
            ),
          ],
        );
      case OrderStatus.confirmed:
        return AppButton(
          text: 'Mulai Masak',
          icon: Icons.restaurant,
          variant: ButtonVariant.secondary,
          height: 36,
          onPressed: () => ref
              .read(orderControllerProvider.notifier)
              .updateStatus(order.id, OrderStatus.preparing),
        );
      case OrderStatus.preparing:
        return AppButton(
          text: 'Tandai Siap',
          icon: Icons.check_circle_outline,
          variant: ButtonVariant.secondary,
          height: 36,
          onPressed: () => ref
              .read(orderControllerProvider.notifier)
              .updateStatus(order.id, OrderStatus.ready),
        );
      case OrderStatus.ready:
        return AppButton(
          text: 'Sajikan ke Meja',
          icon: Icons.room_service,
          variant: ButtonVariant.primary,
          height: 36,
          onPressed: () => ref
              .read(orderControllerProvider.notifier)
              .updateStatus(order.id, OrderStatus.served),
        );
      case OrderStatus.served:
        return AppButton(
          text: 'Selesaikan',
          icon: Icons.done_all,
          variant: ButtonVariant.secondary,
          height: 36,
          onPressed: () => ref
              .read(orderControllerProvider.notifier)
              .updateStatus(order.id, OrderStatus.completed),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
