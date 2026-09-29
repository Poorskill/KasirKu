import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/state_views.dart';
import '../../../models/transaction.dart';
import '../../products/presentation/products_provider.dart';
import '../../transactions/presentation/transactions_provider.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  int _selectedPeriod = 1; // 0: Hari Ini, 1: 7 Hari Terakhir, 2: 30 Hari, 3: Bulan Ini

  void _exportCsv(List<TransactionRecord> transactions) {
    final buffer = StringBuffer();
    buffer.writeln('ID Transaksi,Waktu,Kasir,Metode,Subtotal,Diskon,Pajak,Total,Status');
    for (final t in transactions) {
      buffer.writeln(
        '${t.id},"${t.createdAt.toIso8601String()}",${t.cashierName},${t.paymentMethod.label},${t.subtotal},${t.discount},${t.tax},${t.total},${t.status}',
      );
    }

    final csvContent = buffer.toString();
    Clipboard.setData(ClipboardData(text: csvContent));

    final dateStr = DateTime.now().toString().split(' ').first;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        ),
        title: const Text('Export Data Penjualan CSV',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('File: kasirku_sales_$dateStr.csv',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 8),
            const Text(
              'Seluruh data transaksi telah disiapkan dan disalin ke clipboard komputer Anda. Anda dapat langsung menempelkannya (paste) ke Microsoft Excel, Google Sheets, atau aplikasi pembukuan.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          AppButton(
            text: 'Tutup',
            height: 38,
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trxAsync = ref.watch(transactionsStreamProvider);
    final productsAsync = ref.watch(productsStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: trxAsync.when(
          loading: () =>
              const LoadingWidget(message: 'Memuat laporan penjualan...'),
          error: (e, _) => ErrorStateWidget(message: e.toString()),
          data: (allTransactions) {
            return productsAsync.when(
              loading: () =>
                  const LoadingWidget(message: 'Menghitung statistik...'),
              error: (e, _) => ErrorStateWidget(message: e.toString()),
              data: (products) {
                // Filter transactions by period
                final now = DateTime.now();
                final todayStart = DateTime(now.year, now.month, now.day);
                final weekStart = todayStart.subtract(const Duration(days: 6));
                final thirtyDaysStart = todayStart.subtract(const Duration(days: 29));
                final monthStart = DateTime(now.year, now.month, 1);

                final transactions = allTransactions.where((t) {
                  switch (_selectedPeriod) {
                    case 0:
                      return !t.createdAt.isBefore(todayStart);
                    case 1:
                      return !t.createdAt.isBefore(weekStart);
                    case 2:
                      return !t.createdAt.isBefore(thirtyDaysStart);
                    case 3:
                      return !t.createdAt.isBefore(monthStart);
                    default:
                      return true;
                  }
                }).toList();

                final totalRevenue =
                    transactions.fold(0.0, (s, t) => s + t.total);
                final totalItemsSold = transactions.fold(
                    0,
                    (s, t) =>
                        s +
                        t.items.fold(0, (sub, i) => sub + i.quantity));
                final avgTrx = transactions.isEmpty
                    ? 0.0
                    : totalRevenue / transactions.length;

                // Payment method breakdown
                int cashCount = 0;
                int qrisCount = 0;
                int transferCount = 0;
                double cashRev = 0;
                double qrisRev = 0;
                double transferRev = 0;

                for (final t in transactions) {
                  if (t.paymentMethod == PaymentMethod.cash) {
                    cashCount++;
                    cashRev += t.total;
                  } else if (t.paymentMethod == PaymentMethod.qris) {
                    qrisCount++;
                    qrisRev += t.total;
                  } else if (t.paymentMethod == PaymentMethod.transfer) {
                    transferCount++;
                    transferRev += t.total;
                  }
                }

                // Top products aggregation
                final Map<String, int> productSoldMap = {};
                final Map<String, double> productRevMap = {};
                for (final t in transactions) {
                  for (final item in t.items) {
                    productSoldMap[item.productName] =
                        (productSoldMap[item.productName] ?? 0) + item.quantity;
                    productRevMap[item.productName] =
                        (productRevMap[item.productName] ?? 0.0) + item.subtotal;
                  }
                }

                final rankedProducts = productSoldMap.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value));

                return SingleChildScrollView(
                  padding: EdgeInsets.all(
                    context.isMobile
                        ? AppDimensions.spaceSm
                        : AppDimensions.spaceMd,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Laporan Penjualan',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                'Analisis omset, tren transaksi, dan distribusi pembayaran',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              if (!context.isMobile) ...[
                                _buildPeriodSelector(),
                                const SizedBox(width: 8),
                              ],
                              AppButton(
                                text: 'Export CSV',
                                icon: Icons.download_rounded,
                                variant: ButtonVariant.secondary,
                                height: 38,
                                onPressed: () => _exportCsv(transactions),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (context.isMobile) ...[
                        const SizedBox(height: AppDimensions.spaceSm),
                        _buildPeriodSelector(),
                      ],
                      const SizedBox(height: AppDimensions.spaceMd),

                      // Metric cards
                      _buildSummaryRow(
                        context,
                        revenue: totalRevenue,
                        trxCount: transactions.length,
                        itemsSold: totalItemsSold,
                        avgTrx: avgTrx,
                      ),
                      const SizedBox(height: AppDimensions.spaceMd),

                      // Chart Card (Bar Chart of weekly sales)
                      AppCard(
                        padding: const EdgeInsets.all(AppDimensions.spaceMd),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Volume Penjualan Harian (Rp)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const Text(
                              'Grafik perbandingan omset per hari dalam seminggu',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              height: 220,
                              child: BarChart(
                                BarChartData(
                                  alignment: BarChartAlignment.spaceAround,
                                  maxY: 300000,
                                  barTouchData: BarTouchData(enabled: true),
                                  titlesData: FlTitlesData(
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 52,
                                        getTitlesWidget: (v, _) => Text(
                                          CurrencyFormatter.formatCompact(v),
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                    ),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (val, _) {
                                          const days = [
                                            'Sen',
                                            'Sel',
                                            'Rab',
                                            'Kam',
                                            'Jum',
                                            'Sab',
                                            'Min'
                                          ];
                                          final i = val.toInt() % 7;
                                          return Padding(
                                            padding:
                                                const EdgeInsets.only(top: 8),
                                            child: Text(
                                              days[i],
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
                                        sideTitles: SideTitles(showTitles: false)),
                                    topTitles: const AxisTitles(
                                        sideTitles: SideTitles(showTitles: false)),
                                  ),
                                  gridData: FlGridData(
                                    show: true,
                                    drawVerticalLine: false,
                                    getDrawingHorizontalLine: (_) =>
                                        const FlLine(
                                      color: AppColors.border,
                                      strokeWidth: 1,
                                    ),
                                  ),
                                  borderData: FlBorderData(show: false),
                                  barGroups: [
                                    _barGroup(0, 120000),
                                    _barGroup(1, 160000),
                                    _barGroup(2, 90000),
                                    _barGroup(3, 195000),
                                    _barGroup(4, 240000),
                                    _barGroup(5, 275000),
                                    _barGroup(6, 180000),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spaceMd),

                      // Payment Method Distribution & Top Products
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left: Payment Method Stats
                          Expanded(
                            flex: 5,
                            child: AppCard(
                              padding: const EdgeInsets.all(AppDimensions.spaceMd),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Text(
                                    'Metode Pembayaran',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const Text(
                                    'Komposisi penerimaan transaksi kasir',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  const Divider(height: 1),
                                  const SizedBox(height: 12),
                                  _paymentStatRow(
                                    label: 'Tunai (Cash)',
                                    count: cashCount,
                                    revenue: cashRev,
                                    totalRevenue: totalRevenue,
                                    icon: Icons.money_rounded,
                                    color: AppColors.success,
                                  ),
                                  const SizedBox(height: 10),
                                  _paymentStatRow(
                                    label: 'QRIS',
                                    count: qrisCount,
                                    revenue: qrisRev,
                                    totalRevenue: totalRevenue,
                                    icon: Icons.qr_code_rounded,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(height: 10),
                                  _paymentStatRow(
                                    label: 'Transfer Bank',
                                    count: transferCount,
                                    revenue: transferRev,
                                    totalRevenue: totalRevenue,
                                    icon: Icons.account_balance_rounded,
                                    color: const Color(0xFF8B5CF6),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (!context.isMobile) ...[
                            const SizedBox(width: AppDimensions.spaceMd),
                            // Right: Top Selling Products Table
                            Expanded(
                              flex: 7,
                              child: AppCard(
                                padding: const EdgeInsets.all(AppDimensions.spaceMd),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    const Text(
                                      'Peringkat Produk Terlaris',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const Text(
                                      'Volume porsi terjual dan omset produk',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    const Divider(height: 1),
                                    ..._buildDynamicRankedItems(
                                        rankedProducts, productRevMap),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (context.isMobile) ...[
                        const SizedBox(height: AppDimensions.spaceMd),
                        AppCard(
                          padding: const EdgeInsets.all(AppDimensions.spaceMd),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Peringkat Produk Terlaris',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Divider(height: 1),
                              ..._buildDynamicRankedItems(
                                  rankedProducts, productRevMap),
                            ],
                          ),
                        ),
                      ],
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

  Widget _paymentStatRow({
    required String label,
    required int count,
    required double revenue,
    required double totalRevenue,
    required IconData icon,
    required Color color,
  }) {
    final pct = totalRevenue > 0 ? (revenue / totalRevenue * 100).round() : 0;

    return Column(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              '$count trx ($pct%)',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(width: 12),
            Text(
              CurrencyFormatter.format(revenue),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: totalRevenue > 0 ? revenue / totalRevenue : 0,
            backgroundColor: AppColors.secondaryBtnBg,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 4,
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _periodOption(0, 'Hari Ini'),
          _periodOption(1, '7 Hari'),
          _periodOption(2, '30 Hari'),
          _periodOption(3, 'Bulan Ini'),
        ],
      ),
    );
  }

  Widget _periodOption(int index, String label) {
    final isSelected = _selectedPeriod == index;
    return InkWell(
      onTap: () => setState(() => _selectedPeriod = index),
      borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        color: isSelected ? AppColors.primaryLight : Colors.transparent,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    BuildContext context, {
    required double revenue,
    required int trxCount,
    required int itemsSold,
    required double avgTrx,
  }) {
    final list = [
      _ReportCard(
        title: 'Total Pendapatan',
        value: CurrencyFormatter.format(revenue),
        icon: Icons.account_balance_wallet_outlined,
        color: AppColors.primary,
        bgColor: AppColors.primaryLight,
      ),
      _ReportCard(
        title: 'Total Transaksi',
        value: '$trxCount pesanan',
        icon: Icons.receipt_long_outlined,
        color: AppColors.success,
        bgColor: AppColors.successBg,
      ),
      _ReportCard(
        title: 'Produk Terjual',
        value: '$itemsSold unit',
        icon: Icons.shopping_bag_outlined,
        color: const Color(0xFF8B5CF6),
        bgColor: const Color(0xFFF5F3FF),
      ),
      _ReportCard(
        title: 'Rata-rata Transaksi',
        value: CurrencyFormatter.format(avgTrx),
        icon: Icons.trending_up_rounded,
        color: AppColors.warning,
        bgColor: AppColors.warningBg,
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
            childAspectRatio: 1.5,
            children: list,
          );
        },
      );
    }

    return Row(
      children: list
          .map((c) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: c,
                ),
              ))
          .toList(),
    );
  }

  BarChartGroupData _barGroup(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: AppColors.primary,
          width: 16,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
      ],
    );
  }

  List<Widget> _buildDynamicRankedItems(
    List<MapEntry<String, int>> rankedList,
    Map<String, double> revMap,
  ) {
    if (rankedList.isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text('Belum ada data penjualan pada periode ini',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ),
      ];
    }

    return rankedList.take(5).toList().asMap().entries.map((entry) {
      final rank = entry.key + 1;
      final item = entry.value;
      final rev = revMap[item.key] ?? 0.0;

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: rank == 1
                    ? AppColors.warningBg
                    : AppColors.secondaryBtnBg,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$rank',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: rank == 1
                      ? AppColors.warning
                      : AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.key,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '${item.value} porsi terjual',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              CurrencyFormatter.format(rev),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}

class _ReportCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _ReportCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
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
        ],
      ),
    );
  }
}
