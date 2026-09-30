import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/online_payment.dart';
import '../models/restaurant_order.dart';
import '../models/restaurant_table.dart';
import '../models/stock_movement.dart';
import '../models/transaction.dart';
import '../models/transaction_item.dart';
import 'product_repository.dart';
import 'stock_repository.dart';
import 'table_repository.dart';
import 'transaction_repository.dart';

abstract class OrderRepository {
  Stream<List<RestaurantOrder>> watchOrders();
  Future<List<RestaurantOrder>> getOrders();
  Future<RestaurantOrder?> getOrderById(String id);
  Future<void> createOrder(RestaurantOrder order);
  Future<void> updateOrderStatus(String orderId, OrderStatus status);
  Future<void> markOrderPaid(String orderId);
  Future<void> cancelOrder(String orderId, {String reason = 'Dibatalkan'});
  Future<bool> verifyAndSettlePayment(String paymentId);

  Stream<List<OnlinePayment>> watchPayments();
  Future<void> createPayment(OnlinePayment payment);
  Future<OnlinePayment?> getPaymentByOrderId(String orderId);
}

class HybridOrderRepository implements OrderRepository {
  final ProductRepository _productRepo;
  final StockRepository _stockRepo;
  final TableRepository _tableRepo;
  final TransactionRepository? _transactionRepo;

  final _ordersController = StreamController<List<RestaurantOrder>>.broadcast();
  final _paymentsController = StreamController<List<OnlinePayment>>.broadcast();

  List<RestaurantOrder> _orders = [];
  List<OnlinePayment> _payments = [];
  bool _firebaseReady = false;

  HybridOrderRepository(
    this._productRepo,
    this._stockRepo,
    this._tableRepo, [
    this._transactionRepo,
  ]) {
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
  Future<void> markOrderPaid(String orderId) async {
    final now = DateTime.now();
    if (_firebaseReady) {
      try {
        await FirebaseFirestore.instance
            .collection('orders')
            .doc(orderId)
            .update({
          'paymentStatus': 'paid',
          'orderStatus': OrderStatus.paid.name,
          'updatedAt': now.toIso8601String(),
        });
        return;
      } catch (_) {}
    }

    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      final cur = _orders[index];
      _orders[index] = cur.copyWith(
        paymentStatus: 'paid',
        orderStatus: cur.orderStatus == OrderStatus.pendingPayment
            ? OrderStatus.paid
            : cur.orderStatus,
        updatedAt: now,
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
  Future<void> cancelOrder(String orderId, {String reason = 'Dibatalkan'}) async {
    final now = DateTime.now();
    final orderIndex = _orders.indexWhere((o) => o.id == orderId);
    if (orderIndex == -1) return;

    final curOrder = _orders[orderIndex];
    if (curOrder.orderStatus == OrderStatus.cancelled ||
        curOrder.orderStatus == OrderStatus.refunded) {
      return;
    }

    final wasPaid = curOrder.isPaid;

    if (_firebaseReady) {
      try {
        await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
          'orderStatus': OrderStatus.cancelled.name,
          'updatedAt': now.toIso8601String(),
        });
      } catch (_) {}
    }

    _orders[orderIndex] = curOrder.copyWith(
      orderStatus: OrderStatus.cancelled,
      updatedAt: now,
    );
    _ordersController.add(List.unmodifiable(_orders));

    // Rollback stock if order was already settled/paid
    if (wasPaid) {
      for (final item in curOrder.items) {
        await _productRepo.adjustStock(item.productId, -item.quantity);
        final prods = await _productRepo.getProducts();
        final matches = prods.where((p) => p.id == item.productId);
        final currentStock = matches.isNotEmpty ? matches.first.stock : 0;
        await _stockRepo.recordMovement(
          StockMovement(
            id: 'SM-RESTORE-${now.millisecondsSinceEpoch}-${item.productId}',
            productId: item.productId,
            productName: item.productName,
            type: StockMovementType.adjustment,
            quantity: item.quantity,
            previousStock: (currentStock - item.quantity).clamp(0, 999999),
            newStock: currentStock,
            reason: 'Pengembalian stok dari batal #${curOrder.orderNumber}: $reason',
            createdAt: now,
            createdBy: 'System / Kasir',
          ),
        );
      }
    }
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

    if (_firebaseReady) {
      try {
        await FirebaseFirestore.instance
            .collection('payments')
            .doc(paymentId)
            .update({
          'status': OnlinePaymentStatus.paid.name,
          'paidAt': now.toIso8601String(),
        });
      } catch (_) {}
    }

    // Update order
    final orderIndex = _orders.indexWhere((o) => o.id == curPayment.orderId);
    if (orderIndex != -1) {
      final curOrder = _orders[orderIndex];
      final updatedOrder = curOrder.copyWith(
        paymentStatus: 'paid',
        orderStatus: OrderStatus.paid,
        updatedAt: now,
      );
      _orders[orderIndex] = updatedOrder;
      _ordersController.add(List.unmodifiable(_orders));

      if (_firebaseReady) {
        try {
          await FirebaseFirestore.instance
              .collection('orders')
              .doc(curOrder.id)
              .update({
            'paymentStatus': 'paid',
            'orderStatus': OrderStatus.paid.name,
            'updatedAt': now.toIso8601String(),
          });
        } catch (_) {}
      }

      // Stock deduction with idempotency and safe product lookup
      for (final item in curOrder.items) {
        await _productRepo.adjustStock(item.productId, item.quantity);
        final prods = await _productRepo.getProducts();
        final matches = prods.where((p) => p.id == item.productId);
        final curStock = matches.isNotEmpty ? matches.first.stock : 0;
        await _stockRepo.recordMovement(
          StockMovement(
            id: 'SM-${now.millisecondsSinceEpoch}-${item.productId}',
            productId: item.productId,
            productName: item.productName,
            type: StockMovementType.sale,
            quantity: -item.quantity,
            previousStock: curStock + item.quantity,
            newStock: curStock,
            reason: 'Order QR Meja #${curOrder.orderNumber}',
            createdAt: now,
            createdBy: 'Online Customer',
          ),
        );
      }

      // Ensure table session and status
      if (curOrder.tableId.isNotEmpty) {
        final table = await _tableRepo.getTableById(curOrder.tableId);
        if (table != null) {
          String activeSessionId = table.currentSessionId ?? '';
          if (activeSessionId.isEmpty) {
            final session = await _tableRepo.openTableSession(
              table.id,
              createdBy: 'Customer QR',
            );
            activeSessionId = session.id;
          }

          // Update session amounts
          final existingSession =
              await _tableRepo.getSessionById(activeSessionId);
          final prevTotal = existingSession?.totalAmount ?? 0.0;
          final prevPaid = existingSession?.paidAmount ?? 0.0;
          final prevOrders = existingSession?.orderIds ?? [];

          await _tableRepo.updateSessionAmounts(
            activeSessionId,
            totalAmount: prevTotal + curOrder.total,
            paidAmount: prevPaid + curOrder.total,
            orderIds: [...prevOrders, curOrder.orderNumber],
          );
        }
        await _tableRepo.updateTableStatus(curOrder.tableId, TableStatus.occupied);
      }

      // Bridge to Transaction Record for Reports & History
      if (_transactionRepo != null) {
        final trxId = 'TRX-${curOrder.orderNumber}';
        final existingTrx = await _transactionRepo.getTransactionById(trxId);
        if (existingTrx == null) {
          final trxRecord = TransactionRecord(
            id: trxId,
            cashierId: 'online-customer',
            cashierName: curOrder.customerName,
            items: curOrder.items
                .map((i) => TransactionItem(
                      productId: i.productId,
                      productName: i.productName,
                      price: i.unitPrice,
                      costPrice: 0,
                      quantity: i.quantity,
                      subtotal: i.subtotal,
                    ))
                .toList(),
            subtotal: curOrder.subtotal,
            discount: curOrder.discount,
            tax: curOrder.tax,
            total: curOrder.total,
            paymentMethod: PaymentMethod.qris,
            paymentAmount: curOrder.total,
            change: 0,
            orderType: 'dineIn',
            tableId: curOrder.tableId,
            tableNumber: curOrder.tableNumber,
            createdAt: now,
            status: 'success',
          );
          await _transactionRepo.createTransaction(trxRecord);
        }
      }
    }

    return true;
  }
}
