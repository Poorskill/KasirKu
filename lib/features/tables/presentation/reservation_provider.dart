import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/reservation.dart';
import '../../../repositories/reservation_repository.dart';
import 'tables_provider.dart';

final reservationRepositoryProvider = Provider<ReservationRepository>((ref) {
  final tableRepo = ref.watch(tableRepositoryProvider);
  return HybridReservationRepository(tableRepo);
});

final reservationsStreamProvider = StreamProvider<List<Reservation>>((ref) {
  final repo = ref.watch(reservationRepositoryProvider);
  return repo.watchReservations();
});

class ReservationController extends StateNotifier<AsyncValue<void>> {
  final ReservationRepository _repo;

  ReservationController(this._repo) : super(const AsyncValue.data(null));

  Future<bool> createReservation({
    required String customerName,
    required String phone,
    required String tableId,
    required String tableNumber,
    required DateTime date,
    required String time,
    required int guestCount,
    String notes = '',
  }) async {
    state = const AsyncValue.loading();
    try {
      final now = DateTime.now();
      final res = Reservation(
        id: 'res-${now.millisecondsSinceEpoch % 100000}',
        customerName: customerName.trim(),
        phone: phone.trim(),
        tableId: tableId,
        tableNumber: tableNumber,
        date: date,
        time: time.trim(),
        guestCount: guestCount,
        status: ReservationStatus.confirmed,
        notes: notes.trim(),
        createdAt: now,
      );
      await _repo.createReservation(res);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateStatus(String id, ReservationStatus status) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updateReservationStatus(id, status);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> deleteReservation(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repo.deleteReservation(id);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final reservationControllerProvider =
    StateNotifierProvider<ReservationController, AsyncValue<void>>((ref) {
  final repo = ref.watch(reservationRepositoryProvider);
  return ReservationController(repo);
});
