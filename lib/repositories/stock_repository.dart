import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/stock_movement.dart';

abstract class StockRepository {
  Stream<List<StockMovement>> watchMovements();
  Future<List<StockMovement>> getMovements();
  Future<void> recordMovement(StockMovement movement);
}

class HybridStockRepository implements StockRepository {
  final _inMemoryController = StreamController<List<StockMovement>>.broadcast();
  List<StockMovement> _movements = [];
  bool _firebaseReady = false;

  HybridStockRepository() {
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
      _seedMovements();
    }
  }

  void _seedMovements() {
    final now = DateTime.now();
    _movements = [
      StockMovement(
        id: 'SM-001',
        productId: 'prod-4',
        productName: 'Roti Bakar Cokelat Keju',
        type: StockMovementType.adjustment,
        quantity: -3,
        previousStock: 10,
        newStock: 7,
        reason: 'Bahan roti kedaluwarsa / rusak',
        createdAt: now.subtract(const Duration(hours: 3)),
        createdBy: 'Admin KasirKu',
      ),
      StockMovement(
        id: 'SM-002',
        productId: 'prod-1',
        productName: 'Kopi Susu Gula Aren',
        type: StockMovementType.sale,
        quantity: -2,
        previousStock: 37,
        newStock: 35,
        reason: 'Penjualan kasir #TRX-001',
        createdAt: now.subtract(const Duration(hours: 2)),
        createdBy: 'Admin KasirKu',
      ),
      StockMovement(
        id: 'SM-003',
        productId: 'prod-5',
        productName: 'Air Mineral 600ml',
        type: StockMovementType.stockIn,
        quantity: 24,
        previousStock: 26,
        newStock: 50,
        reason: 'Restock supplier minuman',
        createdAt: now.subtract(const Duration(days: 1)),
        createdBy: 'Admin KasirKu',
      ),
      StockMovement(
        id: 'SM-004',
        productId: 'prod-7',
        productName: 'Nasi Goreng Kampung',
        type: StockMovementType.adjustment,
        quantity: -5,
        previousStock: 5,
        newStock: 0,
        reason: 'Bahan baku beras dan telur habis untuk opname',
        createdAt: now.subtract(const Duration(days: 2)),
        createdBy: 'Admin KasirKu',
      ),
    ];
    _inMemoryController.add(List.unmodifiable(_movements));
  }

  @override
  Stream<List<StockMovement>> watchMovements() {
    if (_firebaseReady) {
      try {
        return FirebaseFirestore.instance
            .collection('stock_movements')
            .orderBy('createdAt', descending: true)
            .snapshots()
            .map((snap) => snap.docs
                .map((d) => StockMovement.fromJson(d.data(), id: d.id))
                .toList());
      } catch (_) {}
    }
    return _inMemoryController.stream;
  }

  @override
  Future<List<StockMovement>> getMovements() async {
    if (_firebaseReady) {
      try {
        final snap = await FirebaseFirestore.instance
            .collection('stock_movements')
            .orderBy('createdAt', descending: true)
            .get();
        return snap.docs
            .map((d) => StockMovement.fromJson(d.data(), id: d.id))
            .toList();
      } catch (_) {}
    }
    return List.unmodifiable(_movements);
  }

  @override
  Future<void> recordMovement(StockMovement movement) async {
    if (_firebaseReady) {
      try {
        await FirebaseFirestore.instance
            .collection('stock_movements')
            .doc(movement.id)
            .set(movement.toJson());
        return;
      } catch (_) {}
    }

    _movements.insert(0, movement);
    _inMemoryController.add(List.unmodifiable(_movements));
  }
}
