import 'dart:async';

class StoreSettings {
  final String storeName;
  final String phone;
  final String address;
  final String receiptFooter;
  final double taxRate; // in percent, e.g. 0% or 11%

  const StoreSettings({
    this.storeName = 'KasirKu UMKM Store',
    this.phone = '0812-3456-7890',
    this.address = 'Jl. Malioboro No. 45, Yogyakarta',
    this.receiptFooter = 'Terima kasih atas kunjungan Anda!\nBarang yang sudah dibeli tidak dapat ditukar.',
    this.taxRate = 0.0,
  });

  StoreSettings copyWith({
    String? storeName,
    String? phone,
    String? address,
    String? receiptFooter,
    double? taxRate,
  }) {
    return StoreSettings(
      storeName: storeName ?? this.storeName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      receiptFooter: receiptFooter ?? this.receiptFooter,
      taxRate: taxRate ?? this.taxRate,
    );
  }
}

class SettingsRepository {
  final _controller = StreamController<StoreSettings>.broadcast();
  StoreSettings _settings = const StoreSettings();

  SettingsRepository() {
    _controller.add(_settings);
  }

  Stream<StoreSettings> watchSettings() => _controller.stream;
  StoreSettings getSettings() => _settings;

  void updateSettings(StoreSettings newSettings) {
    _settings = newSettings;
    _controller.add(_settings);
  }
}
