import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../repositories/settings_repository.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository();
});

final storeSettingsStreamProvider = StreamProvider<StoreSettings>((ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return repo.watchSettings();
});

final currentStoreSettingsProvider = Provider<StoreSettings>((ref) {
  final async = ref.watch(storeSettingsStreamProvider);
  return async.maybeWhen(
    data: (s) => s,
    orElse: () => ref.watch(settingsRepositoryProvider).getSettings(),
  );
});
