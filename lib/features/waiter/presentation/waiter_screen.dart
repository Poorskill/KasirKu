import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/state_views.dart';
import '../../../models/restaurant_order.dart';
import '../../../models/waiter_call.dart';
import '../../customer_order/presentation/customer_order_provider.dart';
import '../../orders/presentation/orders_provider.dart';

class WaiterScreen extends ConsumerStatefulWidget {
  const WaiterScreen({super.key});

  @override
  ConsumerState<WaiterScreen> createState() => _WaiterScreenState();
}

class _WaiterScreenState extends ConsumerState<WaiterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final callsAsync = ref.watch(waiterCallsStreamProvider);
    final readyOrders = ref.watch(waiterReadyOrdersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(
            context.isMobile ? AppDimensions.spaceSm : AppDimensions.spaceMd,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              const Text(
                'Monitor Pelayan & Layanan Meja',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Text(
                'Antrean makanan siap antar dari dapur dan panggilan bantuan pelanggan dari meja',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppDimensions.spaceMd),

              // Tab Bar
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
                  border: Border.all(color: AppColors.border),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.primary,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondary,
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13),
                  tabs: [
                    Tab(
                      icon: const Icon(Icons.room_service_rounded, size: 18),
                      text: 'Siap Diantar (${readyOrders.length})',
                    ),
                    callsAsync.maybeWhen(
                      data: (calls) {
                        final pending = calls
                            .where((c) => c.status == WaiterCallStatus.pending)
                            .length;
                        return Tab(
                          icon: const Icon(Icons.notifications_active_rounded,
                              size: 18),
                          text: 'Panggilan Meja ($pending)',
                        );
                      },
                      orElse: () => const Tab(
                        icon: Icon(Icons.notifications_none_rounded, size: 18),
                        text: 'Panggilan Meja',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.spaceMd),

              // Tab Views
              SizedBox(
                height: 640,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Orders ready to serve
                    _buildReadyOrdersView(context, readyOrders),

                    // Tab 2: Call Waiter live queue
                    callsAsync.when(
                      loading: () =>
                          const LoadingWidget(message: 'Memuat panggilan meja...'),
                      error: (e, _) => ErrorStateWidget(message: e.toString()),
                      data: (calls) => _buildWaiterCallsView(context, calls),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadyOrdersView(
      BuildContext context, List<RestaurantOrder> readyOrders) {
    if (readyOrders.isEmpty) {
      return const EmptyStateWidget(
        title: 'Tidak ada makanan siap antar',
        description: 'Semua pesanan yang siap saji telah selesai diantar ke meja.',
        icon: Icons.check_circle_outline,
      );
    }

    return ListView.separated(
      itemCount: readyOrders.length,
      separatorBuilder: (_, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final order = readyOrders[index];
        return AppCard(
          padding: const EdgeInsets.all(16),
          border: const BorderSide(color: AppColors.primary, width: 1.5),
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
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'MEJA ${order.tableNumber}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        order.orderNumber,
                        style: const TextStyle(
                          fontSize: 14,
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
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'SIAP SAJI 🍽️',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 10),

              // Items to serve
              ...order.items.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Text(
                        '${item.quantity}x ',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                      Expanded(
                        child: Text(
                          '${item.productName}${item.modifiers.isNotEmpty ? " (${item.modifiers.map((m) => m.optionName).join(', ')})" : ""}',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 12),

              // Serve action button
              AppButton(
                text: 'Tandai Sudah Disajikan ke Meja ${order.tableNumber} ✓',
                icon: Icons.done_all_rounded,
                height: 44,
                onPressed: () {
                  ref
                      .read(orderControllerProvider.notifier)
                      .updateStatus(order.id, OrderStatus.served);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Pesanan ${order.orderNumber} telah disajikan ke Meja ${order.tableNumber}'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWaiterCallsView(
      BuildContext context, List<WaiterCall> calls) {
    if (calls.isEmpty) {
      return const EmptyStateWidget(
        title: 'Tidak ada panggilan meja',
        description: 'Saat ini belum ada pelanggan yang meminta bantuan pelayan.',
        icon: Icons.notifications_none_rounded,
      );
    }

    return ListView.separated(
      itemCount: calls.length,
      separatorBuilder: (_, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final call = calls[index];
        final isPending = call.status == WaiterCallStatus.pending;

        return AppCard(
          padding: const EdgeInsets.all(14),
          border: isPending
              ? const BorderSide(color: AppColors.warning, width: 1.5)
              : null,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isPending ? AppColors.warningBg : AppColors.secondaryBtnBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.room_service_rounded,
                  color: isPending ? AppColors.warning : AppColors.textSecondary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                            'MEJA ${call.tableNumber}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          call.type,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    if (call.message.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Pesan: "${call.message}"',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                    Text(
                      DateFormatter.formatTime(call.createdAt),
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              if (isPending)
                AppButton(
                  text: 'Selesai Layani',
                  icon: Icons.check,
                  height: 38,
                  onPressed: () {
                    ref.read(waiterRepositoryProvider).updateWaiterCallStatus(
                          call.id,
                          WaiterCallStatus.resolved,
                        );
                  },
                )
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.successBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Selesai ✓',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.success,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
