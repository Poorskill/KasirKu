import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_button.dart';
import '../../../models/restaurant_order.dart';
import '../../orders/presentation/orders_provider.dart';

class KitchenScreen extends ConsumerStatefulWidget {
  const KitchenScreen({super.key});

  @override
  ConsumerState<KitchenScreen> createState() => _KitchenScreenState();
}

class _KitchenScreenState extends ConsumerState<KitchenScreen> {
  String _stationFilter = 'all'; // 'all', 'kitchen', 'bar'

  @override
  Widget build(BuildContext context) {
    final activeOrders = ref.watch(kitchenOrdersProvider);

    // Apply station filter if needed
    final filtered = activeOrders.where((o) {
      if (_stationFilter == 'kitchen') {
        return o.items.any((i) =>
            !i.productName.toLowerCase().contains('teh') &&
            !i.productName.toLowerCase().contains('kopi') &&
            !i.productName.toLowerCase().contains('mineral'));
      } else if (_stationFilter == 'bar') {
        return o.items.any((i) =>
            i.productName.toLowerCase().contains('teh') ||
            i.productName.toLowerCase().contains('kopi') ||
            i.productName.toLowerCase().contains('mineral'));
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark utilitarian kitchen screen
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.warning,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.outdoor_grill_rounded,
                  size: 20, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kitchen Display System (KDS)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Layar Antrean Masak Koki & Barista',
                  style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Station Toggle
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            child: Row(
              children: [
                _stationChip('Semua Station', 'all'),
                const SizedBox(width: 6),
                _stationChip('Dapur Makanan', 'kitchen'),
                const SizedBox(width: 6),
                _stationChip('Bar Minuman', 'bar'),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: filtered.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.done_all_rounded,
                            size: 48, color: AppColors.success),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Semua Pesanan Sudah Siap!',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Tidak ada antrean memasak di dapur saat ini.',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                      ),
                    ],
                  ),
                ),
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount = 1;
                  if (constraints.maxWidth > 1100) {
                    crossAxisCount = 4;
                  } else if (constraints.maxWidth > 750) {
                    crossAxisCount = 3;
                  } else if (constraints.maxWidth > 480) {
                    crossAxisCount = 2;
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 0.88,
                    ),
                    itemBuilder: (context, index) {
                      final order = filtered[index];
                      return _KitchenTicketCard(order: order);
                    },
                  );
                },
              ),
      ),
    );
  }

  Widget _stationChip(String label, String value) {
    final isSelected = _stationFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _stationFilter = value),
      backgroundColor: const Color(0xFF334155),
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: Colors.white,
      ),
      showCheckmark: false,
    );
  }
}

class _KitchenTicketCard extends ConsumerWidget {
  final RestaurantOrder order;

  const _KitchenTicketCard({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPreparing = order.orderStatus == OrderStatus.preparing;
    final isReady = order.orderStatus == OrderStatus.ready;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPreparing
              ? AppColors.warning
              : (isReady ? AppColors.success : const Color(0xFF334155)),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Meja + Order ID + Timer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isPreparing
                  ? AppColors.warning.withValues(alpha: 0.15)
                  : const Color(0xFF334155),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'MEJA ${order.tableNumber}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      order.orderNumber,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Text(
                  DateFormatter.formatTime(order.createdAt),
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),

          // Items list for chefs
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: order.items.length,
              separatorBuilder: (_, index) =>
                  const Divider(color: Color(0xFF334155), height: 12),
              itemBuilder: (context, idx) {
                final item = order.items[idx];
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${item.quantity}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.productName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          if (item.modifiers.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              item.modifiers.map((m) => m.optionName).join(' • '),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF38BDF8),
                              ),
                            ),
                          ],
                          if (item.note.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF451A03),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'NOTE: ${item.note}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFFDBA74),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Footer Action Button
          Padding(
            padding: const EdgeInsets.all(12),
            child: !isPreparing && !isReady
                ? AppButton(
                    text: 'MULAI MASAK',
                    icon: Icons.outdoor_grill_rounded,
                    height: 44,
                    onPressed: () {
                      ref
                          .read(orderControllerProvider.notifier)
                          .updateStatus(order.id, OrderStatus.preparing);
                    },
                  )
                : (isPreparing
                    ? AppButton(
                        text: 'SIAP DISAJIKAN ✓',
                        icon: Icons.check_circle_rounded,
                        variant: ButtonVariant.primary,
                        height: 44,
                        onPressed: () {
                          ref
                              .read(orderControllerProvider.notifier)
                              .updateStatus(order.id, OrderStatus.ready);
                        },
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.successBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'MENUNGGU WAITER 🛵',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.success,
                          ),
                        ),
                      )),
          ),
        ],
      ),
    );
  }
}
