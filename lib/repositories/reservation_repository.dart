import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/reservation.dart';
import '../models/restaurant_table.dart';
import 'table_repository.dart';

abstract class ReservationRepository {
  Stream<List<Reservation>> watchReservations();
  Future<List<Reservation>> getReservations();
  Future<void> createReservation(Reservation reservation);
  Future<void> updateReservationStatus(String id, ReservationStatus status);
  Future<void> deleteReservation(String id);
}

class HybridReservationRepository implements ReservationRepository {
  final TableRepository? _tableRepo;
  final _reservationsController =
      StreamController<List<Reservation>>.broadcast();

  List<Reservation> _inMemoryReservations = [];
  bool _firebaseReady = false;

  HybridReservationRepository([this._tableRepo]) {
    _init();
  }

  void _init() {
    try {
      if (Firebase.apps.isNotEmpty) {
        _firebaseReady = true;
      }
    } catch (_) {
      _firebaseReady = false;
    }

    if (!_firebaseReady) {
      _seedReservations();
    }
  }

  void _seedReservations() {
    final now = DateTime.now();
    _inMemoryReservations = [
      Reservation(
        id: 'res-01',
        customerName: 'Ibu Rahma & Keluarga',
        phone: '0812-9876-5432',
        tableId: 'tbl-03',
        tableNumber: '03',
        date: DateTime(now.year, now.month, now.day, 19, 0),
        time: '19:00',
        guestCount: 6,
        status: ReservationStatus.confirmed,
        notes: 'Ulang tahun anak, butuh baby chair',
        createdAt: now.subtract(const Duration(hours: 3)),
      ),
    ];
    _reservationsController.add(List.unmodifiable(_inMemoryReservations));
  }

  @override
  Stream<List<Reservation>> watchReservations() async* {
    if (_firebaseReady) {
      try {
        yield* FirebaseFirestore.instance
            .collection('reservations')
            .orderBy('date', descending: false)
            .snapshots()
            .map((snap) {
          if (snap.docs.isEmpty) {
            return List.unmodifiable(_inMemoryReservations);
          }
          return snap.docs
              .map((d) => Reservation.fromJson(d.data(), id: d.id))
              .toList();
        });
        return;
      } catch (_) {}
    }
    yield List.unmodifiable(_inMemoryReservations);
    yield* _reservationsController.stream;
  }

  @override
  Future<List<Reservation>> getReservations() async {
    if (_firebaseReady) {
      try {
        final snap = await FirebaseFirestore.instance
            .collection('reservations')
            .orderBy('date', descending: false)
            .get();
        if (snap.docs.isNotEmpty) {
          return snap.docs
              .map((d) => Reservation.fromJson(d.data(), id: d.id))
              .toList();
        }
      } catch (_) {}
    }
    return List.unmodifiable(_inMemoryReservations);
  }

  @override
  Future<void> createReservation(Reservation reservation) async {
    if (_firebaseReady) {
      try {
        await FirebaseFirestore.instance
            .collection('reservations')
            .doc(reservation.id)
            .set(reservation.toJson());
      } catch (_) {}
    }

    _inMemoryReservations.add(reservation);
    _reservationsController.add(List.unmodifiable(_inMemoryReservations));

    // Update table status if confirmed
    if (reservation.status == ReservationStatus.confirmed &&
        _tableRepo != null &&
        reservation.tableId.isNotEmpty) {
      await _tableRepo.updateTableStatus(
          reservation.tableId, TableStatus.reserved);
    }
  }

  @override
  Future<void> updateReservationStatus(
      String id, ReservationStatus status) async {
    final now = DateTime.now();
    if (_firebaseReady) {
      try {
        await FirebaseFirestore.instance
            .collection('reservations')
            .doc(id)
            .update({
          'status': status.name,
          'updatedAt': now.toIso8601String(),
        });
      } catch (_) {}
    }

    final index = _inMemoryReservations.indexWhere((r) => r.id == id);
    if (index != -1) {
      final cur = _inMemoryReservations[index];
      _inMemoryReservations[index] = cur.copyWith(status: status);
      _reservationsController.add(List.unmodifiable(_inMemoryReservations));

      if (_tableRepo != null && cur.tableId.isNotEmpty) {
        if (status == ReservationStatus.seated) {
          await _tableRepo.updateTableStatus(
              cur.tableId, TableStatus.occupied);
        } else if (status == ReservationStatus.confirmed) {
          await _tableRepo.updateTableStatus(
              cur.tableId, TableStatus.reserved);
        } else if (status == ReservationStatus.cancelled) {
          await _tableRepo.updateTableStatus(
              cur.tableId, TableStatus.available);
        }
      }
    }
  }

  @override
  Future<void> deleteReservation(String id) async {
    if (_firebaseReady) {
      try {
        await FirebaseFirestore.instance
            .collection('reservations')
            .doc(id)
            .delete();
      } catch (_) {}
    }

    _inMemoryReservations.removeWhere((r) => r.id == id);
    _reservationsController.add(List.unmodifiable(_inMemoryReservations));
  }
}
