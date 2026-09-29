import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../models/restaurant_table.dart';
import '../../../../models/waiter_call.dart';
import '../customer_order_provider.dart';

class CallWaiterDialog extends ConsumerStatefulWidget {
  final RestaurantTable table;

  const CallWaiterDialog({super.key, required this.table});

  static Future<void> show(BuildContext context, {required RestaurantTable table}) {
    return showDialog(
      context: context,
      builder: (ctx) => CallWaiterDialog(table: table),
    );
  }

  @override
  ConsumerState<CallWaiterDialog> createState() => _CallWaiterDialogState();
}

class _CallWaiterDialogState extends ConsumerState<CallWaiterDialog> {
  String _selectedReason = 'Bantuan Pelayan';
  final _messageController = TextEditingController();
  bool _isSending = false;

  final List<Map<String, dynamic>> _reasons = [
    {'label': 'Bantuan Pelayan', 'icon': Icons.room_service_rounded},
    {'label': 'Minta Bill', 'icon': Icons.receipt_long_rounded},
    {'label': 'Minta Air Minum', 'icon': Icons.local_drink_rounded},
    {'label': 'Alat Makan Tambahan', 'icon': Icons.restaurant_rounded},
    {'label': 'Tambah Pesanan', 'icon': Icons.add_circle_outline_rounded},
    {'label': 'Lainnya', 'icon': Icons.more_horiz_rounded},
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendCall() async {
    setState(() => _isSending = true);

    final now = DateTime.now();
    final call = WaiterCall(
      id: 'CALL-${const Uuid().v4().substring(0, 8)}',
      storeId: widget.table.storeId,
      tableId: widget.table.id,
      tableNumber: widget.table.tableNumber,
      sessionId: widget.table.currentSessionId,
      type: _selectedReason,
      message: _messageController.text.trim(),
      status: WaiterCallStatus.pending,
      createdAt: now,
    );

    await ref.read(waiterRepositoryProvider).sendWaiterCall(call);

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Pelayan telah dipanggil untuk Meja ${widget.table.tableNumber}. Mohon tunggu sebentar!',
          ),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
      ),
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spaceMd),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppColors.warningBg,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.notifications_active_rounded,
                        color: AppColors.warning, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Panggil Pelayan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Meja ${widget.table.tableNumber} • ${widget.table.name}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(height: 1),
              const SizedBox(height: 14),

              // Reason Grid / Selection
              const Text(
                'Keperluan Anda:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _reasons.map((r) {
                  final isSelected = _selectedReason == r['label'];
                  return ChoiceChip(
                    avatar: Icon(r['icon'] as IconData,
                        size: 16,
                        color: isSelected ? Colors.white : AppColors.textSecondary),
                    label: Text(r['label'] as String),
                    selected: isSelected,
                    onSelected: (_) =>
                        setState(() => _selectedReason = r['label'] as String),
                    backgroundColor: AppColors.secondaryBtnBg,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusButton),
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : AppColors.border,
                      ),
                    ),
                    showCheckmark: false,
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              // Additional Message
              AppTextField(
                label: 'Catatan Tambahan (Opsional)',
                hint: 'Tulis pesan untuk pelayan jika ada...',
                controller: _messageController,
                maxLines: 2,
              ),
              const SizedBox(height: 18),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text: 'Batal',
                      variant: ButtonVariant.secondary,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AppButton(
                      text: 'Panggil Sekarang',
                      icon: Icons.notifications_active_rounded,
                      isLoading: _isSending,
                      onPressed: _sendCall,
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
}
