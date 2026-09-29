import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/state_views.dart';
import '../../../models/restaurant_table.dart';
import '../../auth/presentation/auth_provider.dart';
import 'reservation_dialog.dart';
import 'table_form_dialog.dart';
import 'table_qr_dialog.dart';
import 'table_session_bill_dialog.dart';
import 'tables_provider.dart';

class TablesScreen extends ConsumerWidget {
  const TablesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tablesAsync = ref.watch(tablesStreamProvider);
    final filteredTables = ref.watch(filteredTablesProvider);
    final selectedFilter = ref.watch(selectedTableFilterProvider);
    final search = ref.watch(tableSearchQueryProvider);
    final user = ref.watch(currentUserProvider);
    final isAdmin = user?.isAdmin ?? true;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: tablesAsync.when(
          loading: () =>
              const LoadingWidget(message: 'Memuat data denah meja...'),
          error: (e, _) => ErrorStateWidget(message: e.toString()),
          data: (allTables) {
            final availableCount =
                allTables.where((t) => t.status == TableStatus.available).length;
            final occupiedCount =
                allTables.where((t) => t.status == TableStatus.occupied).length;
            final reservedCount =
                allTables.where((t) => t.status == TableStatus.reserved).length;
            final cleaningCount =
                allTables.where((t) => t.status == TableStatus.cleaning).length;

            return SingleChildScrollView(
              padding: EdgeInsets.all(
                context.isMobile ? AppDimensions.spaceSm : AppDimensions.spaceMd,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Manajemen Meja & QR Resto',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Denah meja realtime, QR code ordering, dan status reservasi',
                            style: TextStyle(
                              fontSize: context.isMobile ? 12 : 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          AppButton(
                            text: context.isMobile ? 'Reservasi' : 'Reservasi Meja',
                            icon: Icons.event_seat_rounded,
                            variant: ButtonVariant.secondary,
                            onPressed: () => ReservationDialog.show(context),
                          ),
                          if (isAdmin && !context.isMobile) ...[
                            const SizedBox(width: 8),
                            AppButton(
                              text: 'Tambah Meja',
                              icon: Icons.add,
                              onPressed: () => TableFormDialog.show(context),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.spaceMd),

                  // Summary metrics
                  _buildSummaryMetrics(
                    context,
                    ref,
                    totalCount: allTables.length,
                    availableCount: availableCount,
                    occupiedCount: occupiedCount,
                    reservedCount: reservedCount,
                    cleaningCount: cleaningCount,
                    currentFilter: selectedFilter,
                  ),
                  const SizedBox(height: AppDimensions.spaceMd),

                  // Search & Filter Card
                  AppCard(
                    padding: const EdgeInsets.all(AppDimensions.spaceSm),
                    child: Column(
                      children: [
                        AppTextField(
                          hint: 'Cari nomor meja atau lokasi...',
                          prefixIcon: const Icon(Icons.search,
                              size: 18, color: AppColors.textSecondary),
                          onChanged: (v) => ref
                              .read(tableSearchQueryProvider.notifier)
                              .state = v,
                        ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _filterChip(ref, 'Semua Meja', 'all', selectedFilter),
                              _filterChip(ref, 'Tersedia ($availableCount)', 'available', selectedFilter),
                              _filterChip(ref, 'Terisi ($occupiedCount)', 'occupied', selectedFilter),
                              _filterChip(ref, 'Dipesan ($reservedCount)', 'reserved', selectedFilter),
                              _filterChip(ref, 'Dibersihkan ($cleaningCount)', 'cleaning', selectedFilter),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spaceMd),

                  // Grid of Tables
                  if (filteredTables.isEmpty)
                    EmptyStateWidget(
                      title: search.isEmpty
                          ? 'Belum ada meja'
                          : 'Meja tidak ditemukan',
                      description: search.isEmpty
                          ? 'Tambahkan meja restoran pertama untuk mengaktifkan QR order.'
                          : 'Coba ubah kata kunci pencarian atau filter status meja.',
                      actionLabel: search.isEmpty && isAdmin ? 'Tambah Meja' : null,
                      onAction: search.isEmpty && isAdmin
                          ? () => TableFormDialog.show(context)
                          : null,
                    )
                  else
                    LayoutBuilder(
                      builder: (context, constraints) {
                        int crossAxisCount = 2;
                        if (constraints.maxWidth > 1024) {
                          crossAxisCount = 4;
                        } else if (constraints.maxWidth > 640) {
                          crossAxisCount = 3;
                        }

                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredTables.length,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.15,
                          ),
                          itemBuilder: (context, index) {
                            final table = filteredTables[index];
                            return _TableGridCard(
                              table: table,
                              isAdmin: isAdmin,
                              onTap: () => _showTableDetails(context, ref, table, isAdmin),
                            );
                          },
                        );
                      },
                    ),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: (context.isMobile && isAdmin)
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Tambah Meja'),
              onPressed: () => TableFormDialog.show(context),
            )
          : null,
    );
  }

  Widget _buildSummaryMetrics(
    BuildContext context,
    WidgetRef ref, {
    required int totalCount,
    required int availableCount,
    required int occupiedCount,
    required int reservedCount,
    required int cleaningCount,
    required String currentFilter,
  }) {
    final list = [
      _MetricTile(
        title: 'Tersedia',
        count: availableCount,
        color: AppColors.success,
        bgColor: AppColors.successBg,
        isSelected: currentFilter == 'available',
        onTap: () => ref.read(selectedTableFilterProvider.notifier).state = 'available',
      ),
      _MetricTile(
        title: 'Terisi (Makan)',
        count: occupiedCount,
        color: AppColors.primary,
        bgColor: AppColors.primaryLight,
        isSelected: currentFilter == 'occupied',
        onTap: () => ref.read(selectedTableFilterProvider.notifier).state = 'occupied',
      ),
      _MetricTile(
        title: 'Dipesan (Reserved)',
        count: reservedCount,
        color: AppColors.warning,
        bgColor: AppColors.warningBg,
        isSelected: currentFilter == 'reserved',
        onTap: () => ref.read(selectedTableFilterProvider.notifier).state = 'reserved',
      ),
      _MetricTile(
        title: 'Dibersihkan',
        count: cleaningCount,
        color: const Color(0xFF8B5CF6),
        bgColor: const Color(0xFFF5F3FF),
        isSelected: currentFilter == 'cleaning',
        onTap: () => ref.read(selectedTableFilterProvider.notifier).state = 'cleaning',
      ),
    ];

    if (context.isMobile) {
      return GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 2.2,
        children: list,
      );
    }

    return Row(
      children: list.map((item) => Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: item,
        ),
      )).toList(),
    );
  }

  Widget _filterChip(WidgetRef ref, String label, String value, String current) {
    final isSelected = value == current;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) =>
            ref.read(selectedTableFilterProvider.notifier).state = value,
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primaryLight,
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? AppColors.primary : AppColors.textSecondary,
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

  void _showTableDetails(
    BuildContext context,
    WidgetRef ref,
    RestaurantTable table,
    bool isAdmin,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: AppColors.surface,
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.spaceMd),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MEJA ${table.tableNumber}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '${table.name} • Kapasitas: ${table.capacity} Orang',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    _buildStatusBadge(table.status),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // Status Actions
                const Text(
                  'Ubah Status Meja:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _statusBtn(sheetCtx, ref, table, TableStatus.available, 'Tersedia'),
                    _statusBtn(sheetCtx, ref, table, TableStatus.occupied, 'Terisi'),
                    _statusBtn(sheetCtx, ref, table, TableStatus.reserved, 'Dipesan'),
                    _statusBtn(sheetCtx, ref, table, TableStatus.cleaning, 'Dibersihkan'),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // Table Session Bill Button
                AppButton(
                  text: 'Rincian Tagihan Sesi Meja (Bill)',
                  icon: Icons.receipt_long_rounded,
                  variant: ButtonVariant.secondary,
                  height: 42,
                  onPressed: () {
                    Navigator.pop(sheetCtx);
                    TableSessionBillDialog.show(context, table: table);
                  },
                ),
                const SizedBox(height: 8),

                // Make Reservation Button
                AppButton(
                  text: 'Reservasi Meja Ini',
                  icon: Icons.event_seat_rounded,
                  variant: ButtonVariant.secondary,
                  height: 42,
                  onPressed: () {
                    Navigator.pop(sheetCtx);
                    ReservationDialog.show(context, preselectedTable: table);
                  },
                ),
                const SizedBox(height: 10),

                // Main Buttons
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        text: 'Lihat QR Code Meja',
                        icon: Icons.qr_code_2_rounded,
                        variant: ButtonVariant.primary,
                        height: 42,
                        onPressed: () {
                          Navigator.pop(sheetCtx);
                          TableQrDialog.show(context, table: table);
                        },
                      ),
                    ),
                    if (isAdmin) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Edit Meja',
                        icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary),
                        onPressed: () {
                          Navigator.pop(sheetCtx);
                          TableFormDialog.show(context, table: table);
                        },
                      ),
                      IconButton(
                        tooltip: 'Hapus Meja',
                        icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                        onPressed: () async {
                          Navigator.pop(sheetCtx);
                          await ref.read(tableControllerProvider.notifier).deleteTable(table.id);
                        },
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _statusBtn(
    BuildContext ctx,
    WidgetRef ref,
    RestaurantTable table,
    TableStatus status,
    String label,
  ) {
    final isCurrent = table.status == status;
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        backgroundColor: isCurrent ? AppColors.primaryLight : Colors.transparent,
        side: BorderSide(
          color: isCurrent ? AppColors.primary : AppColors.border,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      onPressed: () {
        Navigator.pop(ctx);
        ref.read(tableControllerProvider.notifier).updateStatus(table.id, status);
      },
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
          color: isCurrent ? AppColors.primary : AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(TableStatus status) {
    Color bg;
    Color fg;
    switch (status) {
      case TableStatus.available:
        bg = AppColors.successBg;
        fg = AppColors.success;
      case TableStatus.occupied:
        bg = AppColors.primaryLight;
        fg = AppColors.primary;
      case TableStatus.reserved:
        bg = AppColors.warningBg;
        fg = AppColors.warning;
      case TableStatus.cleaning:
        bg = const Color(0xFFF5F3FF);
        fg = const Color(0xFF8B5CF6);
      case TableStatus.inactive:
        bg = AppColors.secondaryBtnBg;
        fg = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
      ),
      child: Text(
        status.label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}

class _TableGridCard extends StatelessWidget {
  final RestaurantTable table;
  final bool isAdmin;
  final VoidCallback onTap;

  const _TableGridCard({
    required this.table,
    required this.isAdmin,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color borderAccent;
    Color statusBg;
    Color statusFg;

    switch (table.status) {
      case TableStatus.available:
        borderAccent = AppColors.success;
        statusBg = AppColors.successBg;
        statusFg = AppColors.success;
      case TableStatus.occupied:
        borderAccent = AppColors.primary;
        statusBg = AppColors.primaryLight;
        statusFg = AppColors.primary;
      case TableStatus.reserved:
        borderAccent = AppColors.warning;
        statusBg = AppColors.warningBg;
        statusFg = AppColors.warning;
      case TableStatus.cleaning:
        borderAccent = const Color(0xFF8B5CF6);
        statusBg = const Color(0xFFF5F3FF);
        statusFg = const Color(0xFF8B5CF6);
      case TableStatus.inactive:
        borderAccent = AppColors.border;
        statusBg = AppColors.secondaryBtnBg;
        statusFg = AppColors.textSecondary;
    }

    return AppCard(
      padding: const EdgeInsets.all(12),
      onTap: onTap,
      border: BorderSide(color: borderAccent, width: 1.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.secondaryBtnBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.people_alt_outlined, size: 13, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '${table.capacity}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  table.status.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusFg,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),

          // Big Table Number
          Text(
            'MEJA ${table.tableNumber}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: 0.5,
            ),
          ),
          Text(
            table.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),

          // QR Code hint & quick button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (table.status == TableStatus.occupied)
                InkWell(
                  onTap: () => TableSessionBillDialog.show(context, table: table),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.receipt_long, size: 13, color: AppColors.primary),
                        SizedBox(width: 4),
                        Text(
                          'Tagihan Sesi',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                const Text(
                  'QR Stand Aktif',
                  style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                ),
              InkWell(
                onTap: () => TableQrDialog.show(context, table: table),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.qr_code_2, size: 16, color: AppColors.primary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  final Color bgColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _MetricTile({
    required this.title,
    required this.count,
    required this.color,
    required this.bgColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      onTap: onTap,
      border: isSelected ? BorderSide(color: color, width: 2) : null,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(Icons.table_restaurant_rounded, size: 16, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  count.toString(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? color : AppColors.textSecondary,
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
