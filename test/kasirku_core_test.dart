import 'package:flutter_test/flutter_test.dart';
import 'package:kasirku/core/utils/currency_formatter.dart';
import 'package:kasirku/core/utils/pricing_calculator.dart';
import 'package:kasirku/models/online_payment.dart';
import 'package:kasirku/models/product.dart';
import 'package:kasirku/models/product_modifier.dart';
import 'package:kasirku/models/reservation.dart';
import 'package:kasirku/models/restaurant_order.dart';
import 'package:kasirku/models/restaurant_table.dart';
import 'package:kasirku/models/stock_movement.dart';
import 'package:kasirku/models/table_session.dart';
import 'package:kasirku/models/transaction.dart';
import 'package:kasirku/models/user_profile.dart';
import 'package:kasirku/models/waiter_call.dart';
import 'package:kasirku/features/pos/presentation/cart_provider.dart';
import 'package:kasirku/repositories/reservation_repository.dart';

void main() {
  test('KasirKu comprehensive core test', () async {
    // 1. Currency test
    final cur15k = CurrencyFormatter.format(15000);
    expect(cur15k.contains('15.000'), isTrue);
    final curMillion = CurrencyFormatter.format(1250000);
    expect(curMillion.contains('1.250.000'), isTrue);

    // 2. Product stock & active status test
    final now = DateTime.now();
    final p = Product(
      id: '1',
      name: 'Kopi',
      sku: 'KOP-1',
      categoryId: 'minuman',
      price: 15000,
      costPrice: 8000,
      stock: 20,
      minimumStock: 5,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );
    expect(p.isAvailable, isTrue);
    expect(p.isLowStock, isFalse);
    expect(p.isOutOfStock, isFalse);
    expect(p.isActive, isTrue);

    final low = p.copyWith(stock: 3);
    expect(low.isAvailable, isFalse);
    expect(low.isLowStock, isTrue);

    final empty = p.copyWith(stock: 0);
    expect(empty.isOutOfStock, isTrue);

    final inactive = p.copyWith(isActive: false);
    expect(inactive.isActive, isFalse);

    // 3. Pricing Calculator test (Discounts & Tax)
    final pricingFixed = PricingCalculator.calculate(
      subtotal: 100000,
      discountType: DiscountType.fixed,
      discountValue: 10000,
      taxRate: 11, // 11%
    );
    expect(pricingFixed.subtotal, 100000);
    expect(pricingFixed.discountAmount, 10000);
    expect(pricingFixed.taxAmount, 9900);
    expect(pricingFixed.grandTotal, 99900);
    expect(pricingFixed.calculateChange(100000), 100);
    expect(pricingFixed.isPaymentValid(100000), isTrue);
    expect(pricingFixed.isPaymentValid(90000), isFalse);

    final pricingPct = PricingCalculator.calculate(
      subtotal: 50000,
      discountType: DiscountType.percentage,
      discountValue: 20, // 20%
      taxRate: 0,
    );
    expect(pricingPct.discountAmount, 10000);
    expect(pricingPct.grandTotal, 40000);

    // 4. Cart Notifier test (including POS Dine-in vs Takeaway & Table selector)
    final cart = CartNotifier();
    expect(cart.state.isEmpty, isTrue);
    expect(cart.state.isDineIn, isTrue);

    cart.addItem(p);
    expect(cart.state.totalItemsCount, 1);
    expect(cart.state.subtotal, 15000);

    cart.addItem(p);
    expect(cart.state.totalItemsCount, 2);
    expect(cart.state.subtotal, 30000);

    // Inactive product cannot be added to cart
    cart.addItem(inactive);
    expect(cart.state.totalItemsCount, 2);

    cart.setDiscount(type: DiscountType.fixed, value: 5000);
    expect(cart.state.total, 25000);

    // Test Dine-in vs Takeaway toggle
    final table1 = RestaurantTable(
      id: 'tbl-1',
      tableNumber: '01',
      name: 'Meja 01',
      capacity: 4,
      status: TableStatus.available,
      qrToken: 'tok_01_xyz',
      createdAt: now,
      updatedAt: now,
    );
    cart.setSelectedTable(table1);
    expect(cart.state.selectedTable?.tableNumber, '01');

    cart.setOrderType(PosOrderType.takeaway);
    expect(cart.state.isTakeaway, isTrue);
    expect(cart.state.selectedTable, isNull);

    cart.setOrderType(PosOrderType.dineIn);
    cart.setSelectedTable(table1);
    expect(cart.state.isDineIn, isTrue);
    expect(cart.state.selectedTable?.id, 'tbl-1');

    cart.decrementItem(p.id);
    expect(cart.state.totalItemsCount, 1);

    cart.clearCart();
    expect(cart.state.isEmpty, isTrue);

    // 5. Stock movement test
    final movement = StockMovement(
      id: 'SM-001',
      productId: p.id,
      productName: p.name,
      type: StockMovementType.adjustment,
      quantity: -5,
      previousStock: 20,
      newStock: 15,
      reason: 'Barang rusak',
      createdAt: now,
      createdBy: 'Admin',
    );
    expect(movement.quantity, -5);
    expect(movement.newStock, 15);

    // 6. Role permissions test (4 roles: admin, cashier, waiter, kitchen)
    final adminUser = UserProfile(
      id: 'usr-1',
      name: 'Admin',
      email: 'admin@kasirku.id',
      role: 'admin',
      createdAt: now,
    );
    final cashierUser = UserProfile(
      id: 'usr-2',
      name: 'Kasir',
      email: 'kasir@kasirku.id',
      role: 'cashier',
      createdAt: now,
    );
    final waiterUser = UserProfile(
      id: 'usr-3',
      name: 'Pelayan',
      email: 'waiter@kasirku.id',
      role: 'waiter',
      createdAt: now,
    );
    final kitchenUser = UserProfile(
      id: 'usr-4',
      name: 'Koki',
      email: 'kitchen@kasirku.id',
      role: 'kitchen',
      createdAt: now,
    );

    expect(adminUser.isAdmin, isTrue);
    expect(adminUser.roleDisplayName, 'Admin');

    expect(cashierUser.isCashier, isTrue);
    expect(cashierUser.isAdmin, isFalse);
    expect(cashierUser.roleDisplayName, 'Kasir');

    expect(waiterUser.isWaiter, isTrue);
    expect(waiterUser.isAdmin, isFalse);
    expect(waiterUser.roleDisplayName, 'Pelayan');

    expect(kitchenUser.isKitchen, isTrue);
    expect(kitchenUser.isAdmin, isFalse);
    expect(kitchenUser.roleDisplayName, 'Koki');

    // 7. Table and Session tests (Bill & Close Table)
    expect(table1.isAvailable, isTrue);
    expect(table1.isOccupied, isFalse);

    final session = TableSession(
      id: 'sess-1',
      tableId: 'tbl-1',
      tableNumber: '01',
      status: SessionStatus.open,
      totalAmount: 100000,
      paidAmount: 100000,
      startedAt: now,
    );
    expect(session.outstandingAmount, 0.0);
    expect(session.canClose, isTrue);

    final unpaidSession = session.copyWith(paidAmount: 50000);
    expect(unpaidSession.outstandingAmount, 50000.0);
    expect(unpaidSession.canClose, isFalse);

    // 8. Product Modifiers and Customer Cart calculation
    const extraCheese = SelectedModifier(
      groupId: 'grp-topping',
      groupName: 'Topping',
      optionId: 'opt-cheese',
      optionName: 'Keju',
      extraPrice: 4000,
    );
    final cartItem = CustomerCartItem(
      id: 'ci-1',
      product: p, // price: 15000
      quantity: 2,
      selectedModifiers: const [extraCheese],
      note: 'Pedas',
    );
    expect(cartItem.unitPrice, 19000);
    expect(cartItem.subtotal, 38000);

    // 9. Restaurant Order State Machine & Online Payment
    final orderItem = RestaurantOrderItem.fromCustomerCartItem(cartItem);
    final order = RestaurantOrder(
      id: 'ord-1',
      tableId: 'tbl-1',
      tableNumber: '01',
      orderNumber: 'ORD-01-001',
      customerName: 'Budi',
      items: [orderItem],
      subtotal: 38000,
      total: 38000,
      paymentStatus: 'pending',
      orderStatus: OrderStatus.pendingPayment,
      createdAt: now,
      updatedAt: now,
    );
    expect(order.isPaid, isFalse);
    expect(order.orderStatus, OrderStatus.pendingPayment);

    final payment = OnlinePayment(
      id: 'pay-1',
      orderId: 'ord-1',
      tableId: 'tbl-1',
      tableNumber: '01',
      customerName: 'Budi',
      amount: 38000,
      method: OnlinePaymentMethod.qris,
      paymentReference: 'QRIS-REF-123',
      createdAt: now,
    );
    expect(payment.isPaid, isFalse);

    // 10. Waiter Call
    final call = WaiterCall(
      id: 'call-1',
      tableId: 'tbl-1',
      tableNumber: '01',
      type: 'Minta Bill',
      createdAt: now,
    );
    expect(call.status, WaiterCallStatus.pending);

    // 11. Table Reservation System test
    final reservation = Reservation(
      id: 'res-test-01',
      customerName: 'Pak Denny',
      phone: '081234567890',
      tableId: 'tbl-1',
      tableNumber: '01',
      date: now.add(const Duration(hours: 2)),
      time: '20:00',
      guestCount: 4,
      status: ReservationStatus.confirmed,
      notes: 'Dekat stopkontak',
      createdAt: now,
    );
    expect(reservation.isConfirmed, isTrue);

    final resRepo = HybridReservationRepository();
    await resRepo.createReservation(reservation);
    final resList = await resRepo.getReservations();
    expect(resList.any((r) => r.id == 'res-test-01'), isTrue);

    // 12. Transaction Record with OrderType & Table
    final trx = TransactionRecord(
      id: 'trx-test-01',
      cashierId: 'cashier-01',
      cashierName: 'Kasir Utama',
      items: const [],
      subtotal: 50000,
      total: 50000,
      paymentMethod: PaymentMethod.cash,
      paymentAmount: 50000,
      change: 0,
      orderType: 'dineIn',
      tableId: 'tbl-1',
      tableNumber: '01',
      createdAt: now,
    );
    expect(trx.isDineIn, isTrue);
    expect(trx.tableNumber, '01');
  });
}
