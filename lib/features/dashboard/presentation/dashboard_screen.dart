import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/state_views.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../pos/presentation/receipt_dialog.dart';
import '../../products/presentation/products_provider.dart';
import '../../transactions/presentation/transactions_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final productsAsync = ref.watch(productsStreamProvider);
    final trxAsync = ref.watch(transactionsStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: productsAsync.when(
          loading: () => const LoadingWidget(message: 'Memuat data dashboard...'),
          error: (e, _) => ErrorStateWidget(message: e.toString()),
          data: (products) {
            return trxAsync.when(
              loading: () =>
                  const LoadingWidget(message: 'Memuat data penjualan...'),
              error: (e, _) => ErrorStateWidget(message: e.toString()),
              data: (transactions) {
                // Today's metrics
                final now = DateTime.now();
                final todayStart = DateTime(now.year, now.month, now.day);
                final todayTrx = transactions
                    .where((t) => !t.createdAt.isBefore(todayStart))
                    .toList();

                final todaySales =
                    todayTrx.fold(0.0, (sum, t) => sum + t.total);
                final todayCount = todayTrx.length;
                final totalProducts = products.length;
                final lowStockProducts =
                    products.where((p) => p.isLowStock || p.isOutOfStock).toList();

                return SingleChildScrollView(
                  padding: EdgeInsets.all(
                    context.isMobile
                        ? AppDimensions.spaceSm
                        : AppDimensions.spaceMd,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Greeting & Quick Action
                      _buildGreetingBar(context, user?.name ?? 'Admin'),
                      const SizedBox(height: AppDimensions.spaceMd),

                      // 4 KPI Cards
                      _buildKpiRow(
                        context,
                        todaySales: todaySales,
                        todayCount: todayCount,
                        totalProducts: totalProducts,
                        lowStockCount: lowStockProducts.length,
                      ),
                      const SizedBox(height: AppDimensions.spaceMd),

                      // Main Content Grid (Responsive)
                      if (context.isDesktop)
                        _buildDesktopContent(
                          context,
                          transactions: transactions,
                          lowStockProducts: lowStockProducts,
                        )
                      else
                        _buildMobileOrTabletContent(
                          context,
                          transactions: transactions,
                          lowStockProducts: lowStockProducts,
                        ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildGreetingBar(BuildContext context, String userName) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selamat datang kembali, $userName 👋',
              style: TextStyle(
                fontSize: context.isMobile ? 18 : 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Berikut ringkasan performa dan inventori toko hari ini',
              style: TextStyle(
                fontSize: context.isMobile ? 12 : 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        if (!context.isMobile)
          AppButton(
            text: 'Buka Kasir',
            icon: Icons.point_of_sale,
            onPressed: () => context.go('/pos'),
          ),
      ],
    );
  }

  Widget _buildKpiRow(
    BuildContext context, {
    required double todaySales,
    required int todayCount,
    required int totalProducts,
    required int lowStockCount,
  }) {
    final kpiCards = [
      _KpiCard(
        title: 'Penjualan Hari Ini',
        value: CurrencyFormatter.format(todaySales),
        subtitle: 'Omset kasir terkini',
        icon: Icons.payments_outlined,
        color: AppColors.primary,
        bgColor: AppColors.primaryLight,
        onTap: () => context.go('/transactions'),
      ),
      _KpiCard(
        title: 'Transaksi Hari Ini',
        value: todayCount.toString(),
        subtitle: 'Pesanan terbayar',
        icon: Icons.receipt_long_outlined,
        color: AppColors.success,
        bgColor: AppColors.successBg,
        onTap: () => context.go('/transactions'),
      ),
      _KpiCard(
        title: 'Total Produk',
        value: totalProducts.toString(),
        subtitle: 'Barang di inventori',
        icon: Icons.inventory_2_outlined,
        color: const Color(0xFF6366F1),
        bgColor: const Color(0xFFEEF2FF),
        onTap: () => context.go('/products'),
      ),
      _KpiCard(
        title: 'Produk Stok Menipis',
        value: lowStockCount.toString(),
        subtitle: 'Perlu restock segera',
        icon: Icons.warning_amber_rounded,
        color: AppColors.warning,
        bgColor: AppColors.warningBg,
        onTap: () => context.go('/inventory'),
      ),
    ];

    if (context.isMobile) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.45,
            children: kpiCards,
          );
        },
      );
    }

    return Row(
      children: kpiCards
          .map((card) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: card,
                ),
              ))
          .toList(),
    );
  }

  Widget _buildDesktopContent(
    BuildContext context, {
    required List transactions,
    required List lowStockProducts,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column (Chart + Recent Transactions)
        Expanded(
          flex: 7,
          child: Column(
            children: [
              _buildChartCard(),
              const SizedBox(height: AppDimensions.spaceMd),
              _buildRecentTransactionsCard(context, transactions),
            ],
          ),
        ),
        const SizedBox(width: AppDimensions.spaceMd),
        // Right Column (Low Stock Alerts & Quick Shortcuts)
        Expanded(
          flex: 5,
          child: Column(
            children: [
              _buildLowStockCard(context, lowStockProducts),
              const SizedBox(height: AppDimensions.spaceMd),
              _buildTopProductsCard(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileOrTabletContent(
    BuildContext context, {
    required List transactions,
    required List lowStockProducts,
  }) {
    return Column(
      children: [
        _buildChartCard(),
        const SizedBox(height: AppDimensions.spaceMd),
        _buildLowStockCard(context, lowStockProducts),
        const SizedBox(height: AppDimensions.spaceMd),
        _buildRecentTransactionsCard(context, transactions),
      ],
    );
  }

  Widget _buildChartCard() {
    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tren Penjualan 7 Hari Terakhir',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Pergerakan omset harian kasir',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Mingguan',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 50000,
                  getDrawingHorizontalLine: (value) => const FlLine(
                    color: AppColors.border,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 56,
                      getTitlesWidget: (val, _) {
                        return Text(
                          CurrencyFormatter.formatCompact(val),
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, _) {
                        const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
                        final idx = val.toInt() % 7;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            days[idx],
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: 250000,
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 110000),
                      FlSpot(1, 145000),
                      FlSpot(2, 95000),
                      FlSpot(3, 175000),
                      FlSpot(4, 210000),
                      FlSpot(5, 235000),
                      FlSpot(6, 185000),
                    ],
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primary.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactionsCard(
      BuildContext context, List transactions) {
    final recent = transactions.take(4).toList();

    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Transaksi Terakhir',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () => context.go('/transactions'),
                child: const Text('Lihat Semua', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const Divider(height: 1),
          if (recent.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Belum ada transaksi',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recent.length,
              separatorBuilder: (_, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final trx = recent[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.receipt_outlined,
                        size: 20, color: AppColors.primary),
                  ),
                  title: Text(
                    trx.id,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    '${DateFormatter.formatTime(trx.createdAt)} • ${trx.paymentMethod.label}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  trailing: Text(
                    CurrencyFormatter.format(trx.total),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  onTap: () => ReceiptDialog.show(
                    context,
                    transaction: trx,
                    onNewTransaction: () {},
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildLowStockCard(BuildContext context, List lowStockList) {
    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: AppColors.warning, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Peringatan Stok Menipis',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => context.go('/inventory'),
                child: const Text('Lihat Semua', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const Divider(height: 1),
          if (lowStockList.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Semua stok produk dalam kondisi aman',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.success, fontSize: 13),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: lowStockList.length.clamp(0, 4),
              separatorBuilder: (_, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final p = lowStockList[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.name,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Sisa: ${p.stock} (Min: ${p.minimumStock})',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AppBadge.fromStock(p.stock, p.minimumStock),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTopProductsCard() {
    final topList = [
      {'name': 'Kopi Susu Gula Aren', 'sold': '84 porsi', 'rev': 1512000},
      {'name': 'Mie Goreng Spesial', 'sold': '48 porsi', 'rev': 1056000},
      {'name': 'Es Teh Manis', 'sold': '76 cup', 'rev': 456000},
      {'name': 'Roti Bakar Cokelat Keju', 'sold': '28 porsi', 'rev': 420000},
    ];

    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Produk Terlaris',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          ...topList.map((item) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['name'] as String,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          item['sold'] as String,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(item['rev'] as num),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final VoidCallback? onTap;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.bgColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
