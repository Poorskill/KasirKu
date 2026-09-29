import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../models/restaurant_table.dart';
import 'tables_provider.dart';

class TableFormDialog extends ConsumerStatefulWidget {
  final RestaurantTable? tableToEdit;

  const TableFormDialog({super.key, this.tableToEdit});

  static Future<void> show(BuildContext context, {RestaurantTable? table}) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => TableFormDialog(tableToEdit: table),
    );
  }

  @override
  ConsumerState<TableFormDialog> createState() => _TableFormDialogState();
}

class _TableFormDialogState extends ConsumerState<TableFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _numberController;
  late TextEditingController _nameController;
  late TextEditingController _capacityController;
  late TableStatus _status;

  bool get isEditing => widget.tableToEdit != null;

  @override
  void initState() {
    super.initState();
    final t = widget.tableToEdit;
    _numberController = TextEditingController(text: t?.tableNumber ?? '');
    _nameController = TextEditingController(text: t?.name ?? '');
    _capacityController =
        TextEditingController(text: t != null ? t.capacity.toString() : '4');
    _status = t?.status ?? TableStatus.available;
  }

  @override
  void dispose() {
    _numberController.dispose();
    _nameController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final numStr = _numberController.text.trim();
    final nameStr = _nameController.text.trim().isEmpty
        ? 'Meja $numStr'
        : _nameController.text.trim();
    final cap = int.tryParse(_capacityController.text) ?? 4;

    bool ok;
    if (isEditing) {
      final updated = widget.tableToEdit!.copyWith(
        tableNumber: numStr,
        name: nameStr,
        capacity: cap,
        status: _status,
        updatedAt: DateTime.now(),
      );
      ok = await ref.read(tableControllerProvider.notifier).updateTable(updated);
    } else {
      ok = await ref.read(tableControllerProvider.notifier).createTable(
            tableNumber: numStr,
            name: nameStr,
            capacity: cap,
          );
    }

    if (ok && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing
              ? 'Meja berhasil diubah'
              : 'Meja $numStr berhasil ditambahkan'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final actionState = ref.watch(tableControllerProvider);
    final isLoading = actionState.isLoading;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
      ),
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spaceMd),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                            borderRadius:
                                BorderRadius.circular(AppDimensions.radiusInput),
                          ),
                          child: const Icon(Icons.table_restaurant_rounded,
                              color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isEditing ? 'Edit Data Meja' : 'Tambah Meja Baru',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textSecondary),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const Divider(height: 1),
                const SizedBox(height: AppDimensions.spaceSm),

                // Fields
                AppTextField(
                  label: 'Nomor Meja *',
                  hint: 'Contoh: 01, 02, VIP-1',
                  controller: _numberController,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: AppDimensions.spaceSm),

                AppTextField(
                  label: 'Nama / Lokasi Meja',
                  hint: 'Contoh: Meja 01 (Indoor Jendela)',
                  controller: _nameController,
                ),
                const SizedBox(height: AppDimensions.spaceSm),

                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: 'Kapasitas (Orang) *',
                        hint: '4',
                        controller: _capacityController,
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Wajib diisi';
                          final n = int.tryParse(v);
                          if (n == null || n <= 0) return 'Kapasitas minimal 1';
                          return null;
                        },
                      ),
                    ),
                    if (isEditing) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Status Meja',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: AppDimensions.spaceXs),
                            Container(
                              height: 48,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusInput),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<TableStatus>(
                                  value: _status,
                                  isExpanded: true,
                                  items: TableStatus.values.map((s) {
                                    return DropdownMenuItem(
                                      value: s,
                                      child: Text(s.label),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) setState(() => _status = val);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppDimensions.spaceLg),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AppButton(
                      text: 'Batal',
                      variant: ButtonVariant.secondary,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 8),
                    AppButton(
                      text: isEditing ? 'Simpan' : 'Tambah Meja',
                      isLoading: isLoading,
                      onPressed: _save,
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
}
