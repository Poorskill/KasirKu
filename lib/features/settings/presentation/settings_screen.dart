import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../repositories/settings_repository.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../pos/presentation/cart_provider.dart';
import 'settings_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _storeNameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _footerController;
  late TextEditingController _taxController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final current = ref.read(currentStoreSettingsProvider);
    _storeNameController = TextEditingController(text: current.storeName);
    _phoneController = TextEditingController(text: current.phone);
    _addressController = TextEditingController(text: current.address);
    _footerController = TextEditingController(text: current.receiptFooter);
    _taxController = TextEditingController(
        text: current.taxRate > 0 ? current.taxRate.toStringAsFixed(0) : '0');
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _footerController.dispose();
    _taxController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    setState(() => _isSaving = true);
    final tax = double.tryParse(_taxController.text) ?? 0.0;
    final newSettings = StoreSettings(
      storeName: _storeNameController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      receiptFooter: _footerController.text.trim(),
      taxRate: tax.clamp(0.0, 100.0),
    );

    ref.read(settingsRepositoryProvider).updateSettings(newSettings);
    ref.read(cartNotifierProvider.notifier).setTaxRate(newSettings.taxRate);

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengaturan toko berhasil disimpan!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    });
  }

  Widget _buildThemeChip(
    WidgetRef ref,
    String label,
    ThemeMode mode,
    ThemeMode current,
  ) {
    final isSelected = mode == current;
    return Expanded(
      child: ChoiceChip(
        label: Center(child: Text(label)),
        selected: isSelected,
        onSelected: (_) {
          ref.read(themeModeProvider.notifier).state = mode;
        },
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primaryLight,
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? AppColors.primary : AppColors.textPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
          side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
        ),
        showCheckmark: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(
            context.isMobile
                ? AppDimensions.spaceSm
                : AppDimensions.spaceMd,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              const Text(
                'Pengaturan',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Text(
                'Kelola informasi usaha, profil kasir, dan preferensi cetak struk',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppDimensions.spaceMd),

              // Store Info Card
              AppCard(
                padding: const EdgeInsets.all(AppDimensions.spaceMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.storefront_outlined,
                            color: AppColors.primary, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Informasi Toko',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(height: 1),
                    const SizedBox(height: 14),
                    AppTextField(
                      label: 'Nama Usaha / Toko',
                      hint: 'Nama Toko Anda',
                      controller: _storeNameController,
                    ),
                    const SizedBox(height: AppDimensions.spaceSm),
                    AppTextField(
                      label: 'Nomor Telepon / WhatsApp',
                      hint: '0812-xxxx-xxxx',
                      controller: _phoneController,
                    ),
                    const SizedBox(height: AppDimensions.spaceSm),
                    AppTextField(
                      label: 'Alamat Toko',
                      hint: 'Alamat lengkap toko',
                      controller: _addressController,
                    ),
                    const SizedBox(height: AppDimensions.spaceSm),
                    AppTextField(
                      label: 'Catatan Kaki Struk (Receipt Footer)',
                      hint: 'Pesan untuk pelanggan di bagian bawah struk',
                      controller: _footerController,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.spaceMd),

              // Profile Card
              AppCard(
                padding: const EdgeInsets.all(AppDimensions.spaceMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.person_outline_rounded,
                            color: AppColors.primary, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Profil Pengguna & Hak Akses',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(height: 1),
                    const SizedBox(height: 14),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.primaryLight,
                        child: Text(
                          (user?.name.isNotEmpty ?? false)
                              ? user!.name[0].toUpperCase()
                              : 'A',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      title: Text(
                        user?.name ?? 'Admin KasirKu',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        '${user?.email ?? "admin@kasirku.id"} • Role: ${user?.role.toUpperCase() ?? "ADMIN"}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.spaceMd),

              // App Settings Card
              AppCard(
                padding: const EdgeInsets.all(AppDimensions.spaceMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.tune_rounded,
                            color: AppColors.primary, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Pengaturan Sistem POS',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(height: 1),
                    const SizedBox(height: 14),
                    AppTextField(
                      label: 'Tarif Pajak PPN (%)',
                      hint: '0',
                      controller: _taxController,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Tema Tampilan Aplikasi',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Consumer(
                      builder: (context, ref, _) {
                        final currentMode = ref.watch(themeModeProvider);
                        return Row(
                          children: [
                            _buildThemeChip(ref, 'Terang', ThemeMode.light, currentMode),
                            const SizedBox(width: 8),
                            _buildThemeChip(ref, 'Gelap', ThemeMode.dark, currentMode),
                            const SizedBox(width: 8),
                            _buildThemeChip(ref, 'Sistem', ThemeMode.system, currentMode),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Versi Aplikasi',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'KasirKu v0.1.0 • Build Ready',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.successBg,
                            borderRadius: BorderRadius.circular(
                                AppDimensions.radiusBadge),
                          ),
                          child: const Text(
                            'Stable MVP',
                            style: TextStyle(
                              color: AppColors.success,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.spaceLg),

              // Save Action
              Align(
                alignment: Alignment.centerRight,
                child: AppButton(
                  text: 'Simpan Semua Pengaturan',
                  icon: Icons.check,
                  isLoading: _isSaving,
                  width: context.isMobile ? double.infinity : 240,
                  onPressed: _saveSettings,
                ),
              ),
              const SizedBox(height: AppDimensions.spaceLg),
            ],
          ),
        ),
      ),
    );
  }
}
