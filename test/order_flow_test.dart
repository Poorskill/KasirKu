import 'package:flutter_test/flutter_test.dart';
import 'package:kasirku/models/online_payment.dart';
import 'package:kasirku/models/restaurant_order.dart';
import 'package:kasirku/models/restaurant_table.dart';
import 'package:kasirku/repositories/order_repository.dart';
import 'package:kasirku/repositories/product_repository.dart';
import 'package:kasirku/repositories/stock_repository.dart';
import 'package:kasirku/repositories/table_repository.dart';
import 'package:kasirku/repositories/transaction_repository.dart';

void main() {
  group('KasirKu Unified End-to-End Flow Tests', () {
    late HybridProductRepository productRepo;
    late HybridStockRepository stockRepo;
    late HybridTableRepository tableRepo;
    late HybridTransactionRepository trxRepo;
    late HybridOrderRepository orderRepo;

    setUp(() {
      productRepo = HybridProductRepository();
      stockRepo = HybridStockRepository();
      tableRepo = HybridTableRepository();
      trxRepo = HybridTransactionRepository();
      orderRepo = HybridOrderRepository(
        productRepo,
        stockRepo,
        tableRepo,
        trxRepo,
      );
    });

    test('QR Table Token Exact Matching Security', () async {
      // Valid token
      final table = await tableRepo.getTableByToken('tbl_tok_01_a9f82d');
      expect(table, isNotNull);
      expect(table?.tableNumber, '01');

      // Attempting to guess by substring/table number should return null!
      final guessed1 = await tableRepo.getTableByToken('tbl_tok_01_');
      expect(guessed1, isNull);

      final guessed2 = await tableRepo.getTableByToken('01');
      expect(guessed2, isNull);

      final empty = await tableRepo.getTableByToken('');
      expect(empty, isNull);
    });

    test('QR Order -> Settle -> Session Creation -> Transaction Record -> Stock Deduction', () async {
      final now = DateTime.now();

      // Product 1 initial stock is 35
      final products = await productRepo.getProducts();
      final p1 = products.firstWhere((p) => p.id == 'prod-1');
      final initialStock = p1.stock;
      expect(initialStock, 35);

      // 1. Create pending order on Table 01 (available)
      final orderItem = RestaurantOrderItem(
        productId: p1.id,
        productName: p1.name,
        unitPrice: p1.price, // 18000
        quantity: 2,
        subtotal: 36000,
      );

      final order = RestaurantOrder(
        id: 'ord-test-e2e',
        tableId: 'tbl-01',
        tableNumber: '01',
        orderNumber: 'ORD-01-999',
        customerName: 'Budi Test',
        items: [orderItem],
        subtotal: 36000,
        discount: 0,
        tax: 0,
        total: 36000,
        paymentStatus: 'pending',
        orderStatus: OrderStatus.pendingPayment,
        source: OrderSource.tableQr,
        createdAt: now,
        updatedAt: now,
      );

      final payment = OnlinePayment(
        id: 'pay-test-e2e',
        orderId: order.id,
        tableId: order.tableId,
        tableNumber: order.tableNumber,
        customerName: order.customerName,
        amount: order.total,
        paymentReference: 'QRIS-REF-999',
        createdAt: now,
      );

      await orderRepo.createOrder(order);
      await orderRepo.createPayment(payment);

      // Verify order is pending
      final createdOrder = await orderRepo.getOrderById(order.id);
      expect(createdOrder?.isPaid, isFalse);
      expect(createdOrder?.orderStatus, OrderStatus.pendingPayment);

      // 2. Settle payment
      final settled = await orderRepo.verifyAndSettlePayment(payment.id);
      expect(settled, isTrue);

      // Verify Order is now paid
      final updatedOrder = await orderRepo.getOrderById(order.id);
      expect(updatedOrder?.isPaid, isTrue);
      expect(updatedOrder?.orderStatus, OrderStatus.paid);

      // 3. Verify Table is now occupied and session opened
      final tbl01 = await tableRepo.getTableById('tbl-01');
      expect(tbl01?.status, TableStatus.occupied);
      expect(tbl01?.currentSessionId, isNotNull);

      final session = await tableRepo.getSessionById(tbl01!.currentSessionId!);
      expect(session, isNotNull);
      expect(session?.totalAmount, 36000.0);
      expect(session?.paidAmount, 36000.0);
      expect(session?.canClose, isTrue);

      // 4. Verify Stock deducted
      final updatedProducts = await productRepo.getProducts();
      final updatedP1 = updatedProducts.firstWhere((p) => p.id == 'prod-1');
      expect(updatedP1.stock, initialStock - 2);

      // 5. Verify Transaction Record bridged to transactions repository
      final trx = await trxRepo.getTransactionById('TRX-ORD-01-999');
      expect(trx, isNotNull);
      expect(trx?.total, 36000.0);
      expect(trx?.tableNumber, '01');
      expect(trx?.cashierName, 'Budi Test');
    });

    test('Order Cancellation restores stock safely', () async {
      final now = DateTime.now();
      final products = await productRepo.getProducts();
      final p2 = products.firstWhere((p) => p.id == 'prod-2'); // stock: 80
      final initialStock = p2.stock;

      final orderItem = RestaurantOrderItem(
        productId: p2.id,
        productName: p2.name,
        unitPrice: p2.price,
        quantity: 3,
        subtotal: p2.price * 3,
      );

      final order = RestaurantOrder(
        id: 'ord-cancel-test',
        tableId: 'tbl-04',
        tableNumber: '04',
        orderNumber: 'ORD-04-123',
        customerName: 'Siti',
        items: [orderItem],
        subtotal: orderItem.subtotal,
        total: orderItem.subtotal,
        paymentStatus: 'pending',
        orderStatus: OrderStatus.pendingPayment,
        source: OrderSource.tableQr,
        createdAt: now,
        updatedAt: now,
      );

      final payment = OnlinePayment(
        id: 'pay-cancel-test',
        orderId: order.id,
        tableId: order.tableId,
        tableNumber: order.tableNumber,
        customerName: order.customerName,
        amount: order.total,
        paymentReference: 'QRIS-REF-CANCEL',
        createdAt: now,
      );

      await orderRepo.createOrder(order);
      await orderRepo.createPayment(payment);
      await orderRepo.verifyAndSettlePayment(payment.id);

      // Verify stock was reduced by 3
      var curProducts = await productRepo.getProducts();
      var curP2 = curProducts.firstWhere((p) => p.id == 'prod-2');
      expect(curP2.stock, initialStock - 3);

      // Cancel the order
      await orderRepo.cancelOrder(order.id, reason: 'Pelanggan salah pesan');

      // Verify order status
      final cancelledOrder = await orderRepo.getOrderById(order.id);
      expect(cancelledOrder?.orderStatus, OrderStatus.cancelled);

      // Verify stock is restored!
      curProducts = await productRepo.getProducts();
      curP2 = curProducts.firstWhere((p) => p.id == 'prod-2');
      expect(curP2.stock, initialStock);
    });
  });
}
