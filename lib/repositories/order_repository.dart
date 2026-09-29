import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/online_payment.dart';
import '../models/restaurant_order.dart';
import '../models/restaurant_table.dart';
import '../models/stock_movement.dart';
import 'product_repository.dart';
import 'stock_repository.dart';
import 'table_repository.dart';

abstract class OrderRepository {
  Stream<List<RestaurantOrder>> watchOrders();
  Future<List<RestaurantOrder>> getOrders();
  Future<RestaurantOrder?> getOrderById(String id);
  Future<void> createOrder(RestaurantOrder order);
  Future<void> updateOrderStatus(String orderId, OrderStatus status);
  Future<bool> verifyAndSettlePayment(String paymentId);

  Stream<List<OnlinePayment>> watchPayments();
  Future<void> createPayment(OnlinePayment payment);
  Future<OnlinePayment?> getPaymentByOrderId(String orderId);
}

class HybridOrderRepository implements OrderRepository {
  final ProductRepository _productRepo;
  final StockRepository _stockRepo;
  final TableRepository _tableRepo;

  final _ordersController = StreamController<List<RestaurantOrder>>.broadcast();
  final _paymentsController = StreamController<List<OnlinePayment>>.broadcast();

  List<RestaurantOrder> _orders = [];
  List<OnlinePayment> _payments = [];
  bool _firebaseReady = false;

  HybridOrderRepository(this._productRepo, this._stockRepo, this._tableRepo) {
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
      _seedInitialOrders();
    }
  }

  void _seedInitialOrders() {
    final now = DateTime.now();
    _orders = [
      RestaurantOrder(
        id: 'ord-1028',
        tableId: 'tbl-02',
        tableSessionId: 'sess-02',
        tableNumber: '02',
        orderNumber: 'ORD-1028',
        customerName: 'Kak Budi',
        items: const [
          RestaurantOrderItem(
            productId: 'prod-3',
            productName: 'Mie Goreng Spesial',
            unitPrice: 22000,
            quantity: 2,
            subtotal: 44000,
            note: 'Pedas sedang, tanpa timun',
          ),
          RestaurantOrderItem(
            productId: 'prod-1',
            productName: 'Kopi Susu Gula Aren',
            unitPrice: 18000,
            quantity: 1,
            subtotal: 18000,
            note: 'Less ice',
          ),
          RestaurantOrderItem(
            productId: 'prod-2',
            productName: 'Es Teh Manis',
            unitPrice: 6000,
            quantity: 2,
            subtotal: 12000,
          ),
        ],
        subtotal: 74000,
        discount: 0,
        tax: 4000,
        total: 78000,
        paymentStatus: 'paid',
        orderStatus: OrderStatus.preparing,
        source: OrderSource.tableQr,
        createdAt: now.subtract(const Duration(minutes: 20)),
        updatedAt: now.subtract(const Duration(minutes: 10)),
      ),
    ];

    _payments = [
      OnlinePayment(
        id: 'pay-1028',
        orderId: 'ord-1028',
        tableId: 'tbl-02',
        tableNumber: '02',
        customerName: 'Kak Budi',
        amount: 78000,
        method: OnlinePaymentMethod.qris,
        status: OnlinePaymentStatus.paid,
        paymentReference: 'QRIS-MIDTRANS-908129381',
        paidAt: now.subtract(const Duration(minutes: 18)),
        createdAt: now.subtract(const Duration(minutes: 20)),
      ),
    ];

    _ordersController.add(List.unmodifiable(_orders));
    _paymentsController.add(List.unmodifiable(_payments));
  }

  @override
  Stream<List<RestaurantOrder>> watchOrders() async* {
    if (_firebaseReady) {
      try {
        yield* FirebaseFirestore.instance
            .collection('orders')
            .orderBy('createdAt', descending: true)
            .snapshots()
            .map((snap) {
          if (snap.docs.isEmpty) {
            return List.unmodifiable(_orders);
          }
          return snap.docs
              .map((d) => RestaurantOrder.fromJson(d.data(), id: d.id))
              .toList();
        });
        return;
      } catch (_) {}
    }
    yield List.unmodifiable(_orders);
    yield* _ordersController.stream;
  }

  @override
  Future<List<RestaurantOrder>> getOrders() async {
    if (_firebaseReady) {
      try {
        final snap = await FirebaseFirestore.instance
            .collection('orders')
            .orderBy('createdAt', descending: true)
            .get();
        if (snap.docs.isNotEmpty) {
          return snap.docs
              .map((d) => RestaurantOrder.fromJson(d.data(), id: d.id))
              .toList();
        }
      } catch (_) {}
    }
    return List.unmodifiable(_orders);
  }

  @override
  Future<RestaurantOrder?> getOrderById(String id) async {
    final list = await getOrders();
    final matches = list.where((o) => o.id == id);
    return matches.isNotEmpty ? matches.first : null;
  }

  @override
  Future<void> createOrder(RestaurantOrder order) async {
    if (_firebaseReady) {
      try {
        await FirebaseFirestore.instance
            .collection('orders')
            .doc(order.id)
            .set(order.toJson());
        return;
      } catch (_) {}
    }

    _orders.insert(0, order);
    _ordersController.add(List.unmodifiable(_orders));
  }

  @override
  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    final now = DateTime.now();
    if (_firebaseReady) {
      try {
        await FirebaseFirestore.instance
            .collection('orders')
            .doc(orderId)
            .update({
          'orderStatus': status.name,
          'updatedAt': now.toIso8601String(),
          if (status == OrderStatus.completed)
            'completedAt': now.toIso8601String(),
        });
        return;
      } catch (_) {}
    }

    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      _orders[index] = _orders[index].copyWith(
        orderStatus: status,
        updatedAt: now,
        completedAt: status == OrderStatus.completed ? now : null,
      );
      _ordersController.add(List.unmodifiable(_orders));
    }
  }

  @override
  Stream<List<OnlinePayment>> watchPayments() async* {
    if (_firebaseReady) {
      try {
        yield* FirebaseFirestore.instance
            .collection('payments')
            .orderBy('createdAt', descending: true)
            .snapshots()
            .map((snap) {
          if (snap.docs.isEmpty) {
            return List.unmodifiable(_payments);
          }
          return snap.docs
              .map((d) => OnlinePayment.fromJson(d.data(), id: d.id))
              .toList();
        });
        return;
      } catch (_) {}
    }
    yield List.unmodifiable(_payments);
    yield* _paymentsController.stream;
  }

  @override
  Future<void> createPayment(OnlinePayment payment) async {
    if (_firebaseReady) {
      try {
        await FirebaseFirestore.instance
            .collection('payments')
            .doc(payment.id)
            .set(payment.toJson());
        return;
      } catch (_) {}
    }

    _payments.insert(0, payment);
    _paymentsController.add(List.unmodifiable(_payments));
  }

  @override
  Future<OnlinePayment?> getPaymentByOrderId(String orderId) async {
    final list = _payments;
    final matches = list.where((p) => p.orderId == orderId);
    return matches.isNotEmpty ? matches.first : null;
  }

  @override
  Future<bool> verifyAndSettlePayment(String paymentId) async {
    final paymentIndex = _payments.indexWhere((p) => p.id == paymentId);
    if (paymentIndex == -1) return false;

    final curPayment = _payments[paymentIndex];
    if (curPayment.isPaid) {
      // Idempotency: Already settled
      return true;
    }

    final now = DateTime.now();
    final updatedPayment = curPayment.copyWith(
      status: OnlinePaymentStatus.paid,
      paidAt: now,
    );
    _payments[paymentIndex] = updatedPayment;
    _paymentsController.add(List.unmodifiable(_payments));

    // Update order
    final orderIndex = _orders.indexWhere((o) => o.id == curPayment.orderId);
    if (orderIndex != -1) {
      final curOrder = _orders[orderIndex];
      _orders[orderIndex] = curOrder.copyWith(
        paymentStatus: 'paid',
        orderStatus: OrderStatus.paid,
        updatedAt: now,
      );
      _ordersController.add(List.unmodifiable(_orders));

      // Stock deduction with idempotency
      for (final item in curOrder.items) {
        await _productRepo.adjustStock(item.productId, item.quantity);
        final prod = await _productRepo.getProducts().then(
            (l) => l.firstWhere((p) => p.id == item.productId));
        await _stockRepo.recordMovement(
          StockMovement(
            id: 'SM-${now.millisecondsSinceEpoch}-${item.productId}',
            productId: item.productId,
            productName: item.productName,
            type: StockMovementType.sale,
            quantity: -item.quantity,
            previousStock: prod.stock + item.quantity,
            newStock: prod.stock,
            reason: 'Order QR Meja #${curOrder.orderNumber}',
            createdAt: now,
            createdBy: 'Online Customer',
          ),
        );
      }

      // Ensure table status is occupied
      if (curOrder.tableId.isNotEmpty) {
        await _tableRepo.updateTableStatus(curOrder.tableId, TableStatus.occupied);
      }
    }

    return true;
  }
}
