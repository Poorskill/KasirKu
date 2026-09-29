import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/state_views.dart';
import '../../../models/transaction.dart';
import '../../pos/presentation/receipt_dialog.dart';
import 'transactions_provider.dart';

class TransactionHistoryScreen extends ConsumerWidget {
  const TransactionHistoryScreen({super.key});

  void _exportCsv(BuildContext context, List<TransactionRecord> records) {
    final buffer = StringBuffer();
    buffer.writeln('ID Transaksi,Waktu,Kasir,Metode,Subtotal,Diskon,Pajak,Total,Status');
    for (final t in records) {
      buffer.writeln(
        '${t.id},"${t.createdAt.toIso8601String()}",${t.cashierName},${t.paymentMethod.label},${t.subtotal},${t.discount},${t.tax},${t.total},${t.status}',
      );
    }
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    final dateStr = DateTime.now().toString().split(' ').first;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('File kasirku_transactions_$dateStr.csv berhasil disalin ke clipboard!'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trxAsync = ref.watch(transactionsStreamProvider);
    final filtered = ref.watch(filteredTransactionsProvider);
    final dateRange = ref.watch(transactionDateFilterProvider);
    final paymentFilter = ref.watch(transactionPaymentFilterProvider);
    final search = ref.watch(transactionSearchQueryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: trxAsync.when(
          loading: () =>
              const LoadingWidget(message: 'Memuat riwayat transaksi...'),
          error: (err, _) => ErrorStateWidget(
            message: err.toString(),
            onRetry: () => ref.refresh(transactionsStreamProvider),
          ),
          data: (allTrx) {
            final now = DateTime.now();
            final todayStart = DateTime(now.year, now.month, now.day);
            final todayTrx = allTrx
                .where((t) => !t.createdAt.isBefore(todayStart))
                .toList();

            final totalSales =
                allTrx.fold(0.0, (sum, t) => sum + t.total);
            final todaySales =
                todayTrx.fold(0.0, (sum, t) => sum + t.total);

            return SingleChildScrollView(
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
                            'Riwayat Transaksi',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Daftar pesanan kasir, bukti pembayaran, dan rincian struk',
                            style: TextStyle(
                              fontSize: context.isMobile ? 12 : 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      AppButton(
                        text: 'Export CSV',
                        icon: Icons.download_rounded,
                        variant: ButtonVariant.secondary,
                        height: 38,
                        onPressed: () => _exportCsv(context, filtered),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.spaceMd),

                  // Summary metrics
                  _buildSummaryCards(
                    context,
                    totalSales: totalSales,
                    totalCount: allTrx.length,
                    todaySales: todaySales,
                    todayCount: todayTrx.length,
                  ),
                  const SizedBox(height: AppDimensions.spaceMd),

                  // Filters card
                  AppCard(
                    padding: const EdgeInsets.all(AppDimensions.spaceSm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppTextField(
                          hint: 'Cari ID transaksi, kasir, atau menu...',
                          prefixIcon: const Icon(Icons.search,
                              size: 20, color: AppColors.textSecondary),
                          onChanged: (val) {
                            ref
                                .read(transactionSearchQueryProvider.notifier)
                                .state = val;
                          },
                        ),
                        const SizedBox(height: AppDimensions.spaceSm),
                        // Date Filter Chips
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _dateChip(
                                label: 'Semua Waktu',
                                range: DateFilterRange.all,
                                current: dateRange,
                                onSelect: () => ref
                                    .read(transactionDateFilterProvider.notifier)
                                    .state = DateFilterRange.all,
                              ),
                              _dateChip(
                                label: 'Hari Ini',
                                range: DateFilterRange.today,
                                current: dateRange,
                                onSelect: () => ref
                                    .read(transactionDateFilterProvider.notifier)
                                    .state = DateFilterRange.today,
                              ),
                              _dateChip(
                                label: 'Minggu Ini',
                                range: DateFilterRange.thisWeek,
                                current: dateRange,
                                onSelect: () => ref
                                    .read(transactionDateFilterProvider.notifier)
                                    .state = DateFilterRange.thisWeek,
                              ),
                              _dateChip(
                                label: 'Bulan Ini',
                                range: DateFilterRange.thisMonth,
                                current: dateRange,
                                onSelect: () => ref
                                    .read(transactionDateFilterProvider.notifier)
                                    .state = DateFilterRange.thisMonth,
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 1,
                                height: 24,
                                color: AppColors.border,
                              ),
                              const SizedBox(width: 8),
                              // Payment Chips
                              _paymentChip(
                                label: 'Semua Metode',
                                val: 'all',
                                current: paymentFilter,
                                onSelect: () => ref
                                    .read(transactionPaymentFilterProvider
                                        .notifier)
                                    .state = 'all',
                              ),
                              _paymentChip(
                                label: 'Tunai',
                                val: 'cash',
                                current: paymentFilter,
                                onSelect: () => ref
                                    .read(transactionPaymentFilterProvider
                                        .notifier)
                                    .state = 'cash',
                              ),
                              _paymentChip(
                                label: 'QRIS',
                                val: 'qris',
                                current: paymentFilter,
                                onSelect: () => ref
                                    .read(transactionPaymentFilterProvider
                                        .notifier)
                                    .state = 'qris',
                              ),
                              _paymentChip(
                                label: 'Transfer',
                                val: 'transfer',
                                current: paymentFilter,
                                onSelect: () => ref
                                    .read(transactionPaymentFilterProvider
                                        .notifier)
                                    .state = 'transfer',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spaceMd),

                  // Transactions Table / List
                  if (filtered.isEmpty)
                    EmptyStateWidget(
                      title: 'Tidak ada transaksi',
                      description: search.isEmpty
                          ? 'Belum ada transaksi pada periode atau filter yang dipilih.'
                          : 'Tidak ada transaksi yang cocok dengan kata kunci "$search".',
                    )
                  else
                    context.isMobile
                        ? _buildMobileList(context, filtered)
                        : _buildDesktopTable(context, filtered),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryCards(
    BuildContext context, {
    required double totalSales,
    required int totalCount,
    required double todaySales,
    required int todayCount,
  }) {
    final cards = [
      _SummaryCard(
        label: 'Penjualan Hari Ini',
        value: CurrencyFormatter.format(todaySales),
        subtext: '$todayCount transaksi',
        icon: Icons.today_outlined,
        color: AppColors.primary,
        bgColor: AppColors.primaryLight,
      ),
      _SummaryCard(
        label: 'Total Omset',
        value: CurrencyFormatter.format(totalSales),
        subtext: '$totalCount total transaksi',
        icon: Icons.account_balance_wallet_outlined,
        color: AppColors.success,
        bgColor: AppColors.successBg,
      ),
    ];

    if (context.isMobile) {
      return Column(
        children: cards
            .map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: c,
                ))
            .toList(),
      );
    }

    return Row(
      children: cards
          .map((c) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: c,
                ),
              ))
          .toList(),
    );
  }

  Widget _buildDesktopTable(
    BuildContext context,
    List<TransactionRecord> list,
  ) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: AppColors.secondaryBtnBg,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: const Row(
              children: [
                Expanded(flex: 3, child: Text('ID TRANSAKSI', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary))),
                Expanded(flex: 3, child: Text('WAKTU', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary))),
                Expanded(flex: 2, child: Text('KASIR', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary))),
                Expanded(flex: 2, child: Text('METODE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary))),
                Expanded(flex: 2, child: Text('TOTAL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary))),
                SizedBox(width: 90, child: Text('AKSI', textAlign: TextAlign.right, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary))),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: list.length,
            separatorBuilder: (_, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final trx = list[index];
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            trx.id,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '${trx.items.length} macam produk',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        DateFormatter.formatDateTime(trx.createdAt),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        trx.cashierName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            trx.paymentMethod.label,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        CurrencyFormatter.format(trx.total),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 90,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => ReceiptDialog.show(
                            context,
                            transaction: trx,
                            onNewTransaction: () {},
                          ),
                          icon: const Icon(Icons.receipt_outlined, size: 16),
                          label: const Text('Struk',
                              style: TextStyle(fontSize: 12)),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMobileList(
    BuildContext context,
    List<TransactionRecord> list,
  ) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      separatorBuilder: (_, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final trx = list[index];
        return AppCard(
          padding: const EdgeInsets.all(AppDimensions.spaceSm),
          onTap: () => ReceiptDialog.show(
            context,
            transaction: trx,
            onNewTransaction: () {},
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    trx.id,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      trx.paymentMethod.label,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                DateFormatter.formatDateTime(trx.createdAt),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${trx.items.length} jenis item',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(trx.total),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _dateChip({
    required String label,
    required DateFilterRange range,
    required DateFilterRange current,
    required VoidCallback onSelect,
  }) {
    final isSelected = range == current;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onSelect(),
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primaryLight,
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? AppColors.primary : AppColors.textPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
          side: BorderSide(
              color: isSelected ? AppColors.primary : AppColors.border),
        ),
        showCheckmark: false,
      ),
    );
  }

  Widget _paymentChip({
    required String label,
    required String val,
    required String current,
    required VoidCallback onSelect,
  }) {
    final isSelected = val == current;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onSelect(),
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.secondaryBtnBg,
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
          side: BorderSide(
              color: isSelected ? AppColors.textPrimary : AppColors.border),
        ),
        showCheckmark: false,
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final String subtext;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.subtext,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.spaceSm),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 24, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtext,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
