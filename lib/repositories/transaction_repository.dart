import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/transaction.dart';
import '../models/transaction_item.dart';

abstract class TransactionRepository {
  Stream<List<TransactionRecord>> watchTransactions();
  Future<List<TransactionRecord>> getTransactions();
  Future<void> createTransaction(TransactionRecord transaction);
  Future<TransactionRecord?> getTransactionById(String id);
}

class HybridTransactionRepository implements TransactionRepository {
  final _inMemoryController = StreamController<List<TransactionRecord>>.broadcast();
  List<TransactionRecord> _inMemoryTransactions = [];
  bool _firebaseReady = false;

  HybridTransactionRepository() {
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
      _seedInitialTransactions();
    }
  }

  void _seedInitialTransactions() {
    final now = DateTime.now();
    _inMemoryTransactions = [
      TransactionRecord(
        id: 'TRX-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-001',
        cashierId: 'user-admin',
        cashierName: 'Admin KasirKu',
        items: const [
          TransactionItem(
            productId: 'prod-1',
            productName: 'Kopi Susu Gula Aren',
            price: 18000,
            costPrice: 8000,
            quantity: 2,
            subtotal: 36000,
          ),
          TransactionItem(
            productId: 'prod-4',
            productName: 'Roti Bakar Cokelat Keju',
            price: 15000,
            costPrice: 7000,
            quantity: 1,
            subtotal: 15000,
          ),
        ],
        subtotal: 51000,
        discount: 0,
        tax: 0,
        total: 51000,
        paymentMethod: PaymentMethod.qris,
        paymentAmount: 51000,
        change: 0,
        createdAt: now.subtract(const Duration(minutes: 25)),
      ),
      TransactionRecord(
        id: 'TRX-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-002',
        cashierId: 'user-admin',
        cashierName: 'Admin KasirKu',
        items: const [
          TransactionItem(
            productId: 'prod-3',
            productName: 'Mie Goreng Spesial',
            price: 22000,
            costPrice: 12000,
            quantity: 2,
            subtotal: 44000,
          ),
          TransactionItem(
            productId: 'prod-2',
            productName: 'Es Teh Manis',
            price: 6000,
            costPrice: 2000,
            quantity: 2,
            subtotal: 12000,
          ),
        ],
        subtotal: 56000,
        discount: 0,
        tax: 0,
        total: 56000,
        paymentMethod: PaymentMethod.cash,
        paymentAmount: 100000,
        change: 44000,
        createdAt: now.subtract(const Duration(hours: 1, minutes: 10)),
      ),
      TransactionRecord(
        id: 'TRX-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-003',
        cashierId: 'user-admin',
        cashierName: 'Admin KasirKu',
        items: const [
          TransactionItem(
            productId: 'prod-1',
            productName: 'Kopi Susu Gula Aren',
            price: 18000,
            costPrice: 8000,
            quantity: 1,
            subtotal: 18000,
          ),
        ],
        subtotal: 18000,
        discount: 0,
        tax: 0,
        total: 18000,
        paymentMethod: PaymentMethod.cash,
        paymentAmount: 20000,
        change: 2000,
        createdAt: now.subtract(const Duration(hours: 2, minutes: 40)),
      ),
      TransactionRecord(
        id: 'TRX-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-004',
        cashierId: 'user-admin',
        cashierName: 'Admin KasirKu',
        items: const [
          TransactionItem(
            productId: 'prod-6',
            productName: 'Pisang Goreng Crispy',
            price: 12000,
            costPrice: 5000,
            quantity: 2,
            subtotal: 24000,
          ),
          TransactionItem(
            productId: 'prod-5',
            productName: 'Air Mineral 600ml',
            price: 5000,
            costPrice: 2500,
            quantity: 2,
            subtotal: 10000,
          ),
        ],
        subtotal: 34000,
        discount: 0,
        tax: 0,
        total: 34000,
        paymentMethod: PaymentMethod.transfer,
        paymentAmount: 34000,
        change: 0,
        createdAt: now.subtract(const Duration(hours: 4)),
      ),
      TransactionRecord(
        id: 'TRX-YEST-091',
        cashierId: 'user-admin',
        cashierName: 'Admin KasirKu',
        items: const [
          TransactionItem(
            productId: 'prod-3',
            productName: 'Mie Goreng Spesial',
            price: 22000,
            costPrice: 12000,
            quantity: 3,
            subtotal: 66000,
          ),
          TransactionItem(
            productId: 'prod-2',
            productName: 'Es Teh Manis',
            price: 6000,
            costPrice: 2000,
            quantity: 3,
            subtotal: 18000,
          ),
        ],
        subtotal: 84000,
        discount: 0,
        tax: 0,
        total: 84000,
        paymentMethod: PaymentMethod.qris,
        paymentAmount: 84000,
        change: 0,
        createdAt: now.subtract(const Duration(days: 1, hours: 2)),
      ),
    ];
    _inMemoryController.add(List.unmodifiable(_inMemoryTransactions));
  }

  @override
  Stream<List<TransactionRecord>> watchTransactions() {
    if (_firebaseReady) {
      try {
        return FirebaseFirestore.instance
            .collection('transactions')
            .orderBy('createdAt', descending: true)
            .snapshots()
            .map((snap) => snap.docs
                .map((d) => TransactionRecord.fromJson(d.data(), id: d.id))
                .toList());
      } catch (_) {}
    }
    return _inMemoryController.stream;
  }

  @override
  Future<List<TransactionRecord>> getTransactions() async {
    if (_firebaseReady) {
      try {
        final snap = await FirebaseFirestore.instance
            .collection('transactions')
            .orderBy('createdAt', descending: true)
            .get();
        return snap.docs
            .map((d) => TransactionRecord.fromJson(d.data(), id: d.id))
            .toList();
      } catch (_) {}
    }
    return List.unmodifiable(_inMemoryTransactions);
  }

  @override
  Future<void> createTransaction(TransactionRecord transaction) async {
    if (_firebaseReady) {
      try {
        await FirebaseFirestore.instance
            .collection('transactions')
            .doc(transaction.id)
            .set(transaction.toJson());
        return;
      } catch (_) {}
    }

    _inMemoryTransactions.insert(0, transaction);
    _inMemoryController.add(List.unmodifiable(_inMemoryTransactions));
  }

  @override
  Future<TransactionRecord?> getTransactionById(String id) async {
    if (_firebaseReady) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('transactions')
            .doc(id)
            .get();
        if (doc.exists && doc.data() != null) {
          return TransactionRecord.fromJson(doc.data()!, id: doc.id);
        }
      } catch (_) {}
    }

    final matches = _inMemoryTransactions.where((t) => t.id == id);
    return matches.isNotEmpty ? matches.first : null;
  }
}
