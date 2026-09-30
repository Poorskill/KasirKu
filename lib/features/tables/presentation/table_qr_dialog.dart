import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../models/restaurant_table.dart';
import 'tables_provider.dart';

class TableQrDialog extends ConsumerStatefulWidget {
  final RestaurantTable table;

  const TableQrDialog({super.key, required this.table});

  static Future<void> show(BuildContext context, {required RestaurantTable table}) {
    return showDialog(
      context: context,
      builder: (context) => TableQrDialog(table: table),
    );
  }

  @override
  ConsumerState<TableQrDialog> createState() => _TableQrDialogState();
}

class _TableQrDialogState extends ConsumerState<TableQrDialog> {
  late RestaurantTable _currentTable;
  late TextEditingController _domainController;
  bool _isRegenerating = false;
  bool _showCustomDomain = false;

  @override
  void initState() {
    super.initState();
    _currentTable = widget.table;

    String initialOrigin = 'https://kasirku.vercel.app';
    if (kIsWeb) {
      final origin = Uri.base.origin;
      if (origin.isNotEmpty && !origin.startsWith('file:') && !origin.contains('localhost:0')) {
        initialOrigin = origin;
      }
    }
    _domainController = TextEditingController(text: initialOrigin);
  }

  @override
  void dispose() {
    _domainController.dispose();
    super.dispose();
  }

  String get _orderUrl {
    final base = _domainController.text.trim().replaceAll(RegExp(r'/+$'), '');
    return '$base/order/${_currentTable.storeId}/${_currentTable.qrToken}';
  }

  Future<void> _regenerateToken() async {
    setState(() => _isRegenerating = true);
    final newToken = await ref
        .read(tableControllerProvider.notifier)
        .regenerateQr(_currentTable.id);

    if (newToken.isNotEmpty && mounted) {
      setState(() {
        _currentTable = _currentTable.copyWith(qrToken: newToken);
        _isRegenerating = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('QR Code Meja berhasil diperbarui (token lama kadaluwarsa)'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      if (mounted) setState(() => _isRegenerating = false);
    }
  }

  void _copyLink() {
    Clipboard.setData(ClipboardData(text: _orderUrl));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tautan Order Meja disalin:\n$_orderUrl'),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 4),
      ),
    );
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
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spaceMd),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'QR Code Pemesanan Meja',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              // Domain Host Setting
              InkWell(
                onTap: () => setState(() => _showCustomDomain = !_showCustomDomain),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.language_rounded, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Host: ${_domainController.text}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        _showCustomDomain ? Icons.expand_less : Icons.edit_outlined,
                        size: 14,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
              if (_showCustomDomain) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: 'Alamat Domain Web/Vercel',
                        hint: 'https://nama-proyek.vercel.app',
                        controller: _domainController,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 10),

              // Printable Table Tent Stand Design Box
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                child: Column(
                  children: [
                    // Brand Logo
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.restaurant_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'KASIRKU DINING',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Table Number Banner
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
                      ),
                      child: Text(
                        'MEJA ${_currentTable.tableNumber}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currentTable.name,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // QR Code Image
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: QrImageView(
                        data: _orderUrl,
                        version: QrVersions.auto,
                        size: 180,
                        backgroundColor: Colors.white,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: AppColors.textPrimary,
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    const Text(
                      'Scan untuk melihat menu & memesan langsung dari meja',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Token: ${_currentTable.qrToken}',
                      style: const TextStyle(
                        fontSize: 9,
                        fontFamily: 'monospace',
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text: 'Salin Link',
                      icon: Icons.link_rounded,
                      variant: ButtonVariant.secondary,
                      height: 40,
                      onPressed: _copyLink,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AppButton(
                      text: 'Cetak QR',
                      icon: Icons.print_outlined,
                      variant: ButtonVariant.secondary,
                      height: 40,
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Menyiapkan format cetak stand meja...'),
                            backgroundColor: AppColors.primary,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              AppButton(
                text: 'Regenerasi Token QR',
                icon: Icons.refresh_rounded,
                variant: ButtonVariant.outline,
                height: 38,
                isLoading: _isRegenerating,
                onPressed: _regenerateToken,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
