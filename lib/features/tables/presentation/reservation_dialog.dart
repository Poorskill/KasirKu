import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../models/reservation.dart';
import '../../../models/restaurant_table.dart';
import 'reservation_provider.dart';
import 'tables_provider.dart';

class ReservationDialog extends ConsumerStatefulWidget {
  final RestaurantTable? preselectedTable;

  const ReservationDialog({super.key, this.preselectedTable});

  static Future<void> show(BuildContext context, {RestaurantTable? preselectedTable}) {
    return showDialog(
      context: context,
      builder: (context) => ReservationDialog(preselectedTable: preselectedTable),
    );
  }

  @override
  ConsumerState<ReservationDialog> createState() => _ReservationDialogState();
}

class _ReservationDialogState extends ConsumerState<ReservationDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _timeController = TextEditingController(text: '19:00');
  final _guestController = TextEditingController(text: '2');
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  RestaurantTable? _selectedTable;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedTable = widget.preselectedTable;
    if (_selectedTable != null) {
      _guestController.text = _selectedTable!.capacity.toString();
    }
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.preselectedTable != null ? 1 : 0,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _timeController.dispose();
    _guestController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTable == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih meja untuk reservasi'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final ok = await ref.read(reservationControllerProvider.notifier).createReservation(
          customerName: _nameController.text,
          phone: _phoneController.text,
          tableId: _selectedTable!.id,
          tableNumber: _selectedTable!.tableNumber,
          date: _selectedDate,
          time: _timeController.text,
          guestCount: int.tryParse(_guestController.text) ?? 2,
          notes: _notesController.text,
        );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (ok) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Reservasi atas nama ${_nameController.text} berhasil dicatat (Meja ${_selectedTable!.tableNumber}).',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      nav.pop();
    } else {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Gagal membuat reservasi. Silakan periksa kembali data.'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final reservationsAsync = ref.watch(reservationsStreamProvider);
    final reservations = reservationsAsync.value ?? [];
    final tables = ref.watch(tablesStreamProvider).value ?? [];

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
      ),
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 720),
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
                          Icons.event_seat_rounded,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sistem Reservasi Meja',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Pemesanan tempat & booking meja restoran',
                            style: TextStyle(
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
              const SizedBox(height: 8),

              // Tab Bar
              TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primary,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                tabs: [
                  Tab(text: 'Daftar Reservasi (${reservations.length})'),
                  const Tab(text: '+ Reservasi Baru'),
                ],
              ),
              const SizedBox(height: 12),

              // Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Reservations List
                    _buildReservationsList(reservations),

                    // Tab 2: New Reservation Form
                    _buildNewReservationForm(tables),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReservationsList(List<Reservation> reservations) {
    if (reservations.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.event_busy_rounded, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 12),
            const Text(
              'Belum ada reservasi aktif',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Pelanggan belum melakukan booking meja untuk hari ini.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            AppButton(
              text: 'Buat Reservasi Baru',
              icon: Icons.add,
              height: 38,
              onPressed: () => _tabController.animateTo(1),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: reservations.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final res = reservations[index];

        Color statusBg = AppColors.primaryLight;
        Color statusFg = AppColors.primary;
        if (res.isConfirmed) {
          statusBg = AppColors.warningBg;
          statusFg = AppColors.warning;
        } else if (res.isSeated) {
          statusBg = AppColors.successBg;
          statusFg = AppColors.success;
        } else if (res.isCancelled) {
          statusBg = AppColors.secondaryBtnBg;
          statusFg = AppColors.textSecondary;
        }

        return AppCard(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Meja ${res.tableNumber}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        res.customerName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      res.status.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: statusFg,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  const Icon(Icons.phone_outlined, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    res.phone,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(width: 14),
                  const Icon(Icons.access_time_rounded, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    '${DateFormatter.formatDate(res.date)} • ${res.time}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(width: 14),
                  const Icon(Icons.people_alt_outlined, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    '${res.guestCount} Tamu',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),

              if (res.notes.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  'Catatan: "${res.notes}"',
                  style: const TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 8),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!res.isSeated && !res.isCancelled) ...[
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        side: const BorderSide(color: AppColors.success),
                      ),
                      icon: const Icon(Icons.person_pin_circle_rounded,
                          size: 14, color: AppColors.success),
                      label: const Text(
                        'Tamu Tiba (Seated)',
                        style: TextStyle(fontSize: 11, color: AppColors.success),
                      ),
                      onPressed: () async {
                        await ref
                            .read(reservationControllerProvider.notifier)
                            .updateStatus(res.id, ReservationStatus.seated);
                      },
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        side: const BorderSide(color: AppColors.danger),
                      ),
                      child: const Text(
                        'Batal',
                        style: TextStyle(fontSize: 11, color: AppColors.danger),
                      ),
                      onPressed: () async {
                        await ref
                            .read(reservationControllerProvider.notifier)
                            .updateStatus(res.id, ReservationStatus.cancelled);
                      },
                    ),
                  ],
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.textMuted),
                    tooltip: 'Hapus Reservasi',
                    onPressed: () async {
                      await ref
                          .read(reservationControllerProvider.notifier)
                          .deleteReservation(res.id);
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNewReservationForm(List<RestaurantTable> tables) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              label: 'Nama Pelanggan',
              hint: 'contoh: Bapak Hendra',
              controller: _nameController,
              validator: (v) => v == null || v.trim().isEmpty ? 'Nama wajib diisi' : null,
            ),
            const SizedBox(height: 10),

            AppTextField(
              label: 'Nomor WhatsApp / Telepon',
              hint: 'contoh: 08123456789',
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              validator: (v) => v == null || v.trim().isEmpty ? 'Nomor telepon wajib diisi' : null,
            ),
            const SizedBox(height: 10),

            // Table Selector
            const Text(
              'Pilih Meja',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusInput),
                border: Border.all(color: AppColors.border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<RestaurantTable>(
                  isExpanded: true,
                  value: _selectedTable != null &&
                          tables.any((t) => t.id == _selectedTable!.id)
                      ? tables.firstWhere((t) => t.id == _selectedTable!.id)
                      : null,
                  hint: const Text('Pilih nomor meja restoran...'),
                  items: tables.map((t) {
                    return DropdownMenuItem<RestaurantTable>(
                      value: t,
                      child: Text(
                        'Meja ${t.tableNumber} - ${t.name} (Kapasitas: ${t.capacity} orang)',
                        style: const TextStyle(fontSize: 13),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedTable = val;
                      if (val != null) {
                        _guestController.text = val.capacity.toString();
                      }
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Date Selector
            const Text(
              'Tanggal Reservasi',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 1)),
                  lastDate: DateTime.now().add(const Duration(days: 90)),
                );
                if (picked != null) {
                  setState(() => _selectedDate = picked);
                }
              },
              borderRadius: BorderRadius.circular(AppDimensions.radiusInput),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusInput),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormatter.formatDate(_selectedDate),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    const Icon(Icons.calendar_today_rounded,
                        size: 16, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Jam Kedatangan',
                    hint: '19:00',
                    controller: _timeController,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Jam wajib diisi' : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppTextField(
                    label: 'Jumlah Tamu',
                    hint: '2',
                    controller: _guestController,
                    keyboardType: TextInputType.number,
                    validator: (v) =>
                        v == null || int.tryParse(v) == null ? 'Jumlah tamu harus angka' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            AppTextField(
              label: 'Catatan Khusus (Opsional)',
              hint: 'misal: Butuh kursi anak, dekat jendela, dsb.',
              controller: _notesController,
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            AppButton(
              text: 'Simpan Reservasi',
              icon: Icons.bookmark_added_rounded,
              isLoading: _isSubmitting,
              onPressed: _handleSubmit,
            ),
          ],
        ),
      ),
    );
  }
}
