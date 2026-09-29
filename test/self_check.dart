import 'package:kasirku/core/utils/currency_formatter.dart';
import 'package:kasirku/core/utils/pricing_calculator.dart';
import 'package:kasirku/models/product.dart';
import 'package:kasirku/models/restaurant_table.dart';
import 'package:kasirku/models/stock_movement.dart';
import 'package:kasirku/models/table_session.dart';
import 'package:kasirku/models/user_profile.dart';
import 'package:kasirku/features/pos/presentation/cart_provider.dart';

void main() {
  // 1. Currency test
  final cur15k = CurrencyFormatter.format(15000);
  assert(cur15k.contains('15.000'), 'Currency formatting failed: $cur15k');
  final curMillion = CurrencyFormatter.format(1250000);
  assert(curMillion.contains('1.250.000'), 'Currency million failed: $curMillion');

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
  assert(p.isAvailable, 'Product should be available');
  assert(!p.isLowStock, 'Product should not be low stock');
  assert(!p.isOutOfStock, 'Product should not be out of stock');
  assert(p.isActive, 'Product should be active');

  final low = p.copyWith(stock: 3);
  assert(!low.isAvailable, 'Low product should not be available');
  assert(low.isLowStock, 'Low product should be low stock');

  final empty = p.copyWith(stock: 0);
  assert(empty.isOutOfStock, 'Empty product should be out of stock');

  final inactive = p.copyWith(isActive: false);
  assert(!inactive.isActive, 'Product should be inactive');

  // 3. Pricing Calculator test (Discounts & Tax)
  final pricingFixed = PricingCalculator.calculate(
    subtotal: 100000,
    discountType: DiscountType.fixed,
    discountValue: 10000,
    taxRate: 11, // 11%
  );
  assert(pricingFixed.subtotal == 100000, 'Subtotal must be 100000');
  assert(pricingFixed.discountAmount == 10000, 'Discount must be 10000');
  // Taxable: 90000, Tax: 9900, Total: 99900
  assert(pricingFixed.taxAmount == 9900, 'Tax must be 9900');
  assert(pricingFixed.grandTotal == 99900, 'Grand total must be 99900');
  assert(pricingFixed.calculateChange(100000) == 100, 'Change must be 100');
  assert(pricingFixed.isPaymentValid(100000), 'Payment 100000 should be valid');
  assert(!pricingFixed.isPaymentValid(90000), 'Payment 90000 should be invalid');

  final pricingPct = PricingCalculator.calculate(
    subtotal: 50000,
    discountType: DiscountType.percentage,
    discountValue: 20, // 20%
    taxRate: 0,
  );
  assert(pricingPct.discountAmount == 10000, '20% of 50000 must be 10000');
  assert(pricingPct.grandTotal == 40000, 'Total must be 40000');

  // 4. Cart Notifier test
  final cart = CartNotifier();
  assert(cart.state.isEmpty, 'Cart must start empty');

  cart.addItem(p);
  assert(cart.state.totalItemsCount == 1, 'Cart items count must be 1');
  assert(cart.state.subtotal == 15000, 'Subtotal must be 15000');

  cart.addItem(p);
  assert(cart.state.totalItemsCount == 2, 'Cart items count must be 2');
  assert(cart.state.subtotal == 30000, 'Subtotal must be 30000');

  // Inactive product cannot be added to cart
  cart.addItem(inactive);
  assert(cart.state.totalItemsCount == 2, 'Inactive product must not be added');

  cart.setDiscount(type: DiscountType.fixed, value: 5000);
  assert(cart.state.total == 25000, 'Total after discount must be 25000');

  cart.decrementItem(p.id);
  assert(cart.state.totalItemsCount == 1, 'Cart items count must be 1 after decrement');

  cart.clearCart();
  assert(cart.state.isEmpty, 'Cart must be empty after clear');

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
  assert(movement.quantity == -5, 'Movement delta should be -5');
  assert(movement.newStock == 15, 'New stock should be 15');

  // 6. Role permissions test
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
  assert(adminUser.isAdmin, 'Admin should have admin rights');
  assert(!cashierUser.isAdmin, 'Cashier should not have admin rights');

  // 7. Table and Session tests
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
  assert(table1.isAvailable, 'Table should be available');
  assert(!table1.isOccupied, 'Table should not be occupied');

  final session = TableSession(
    id: 'sess-1',
    tableId: 'tbl-1',
    tableNumber: '01',
    status: SessionStatus.open,
    totalAmount: 100000,
    paidAmount: 100000,
    startedAt: now,
  );
  assert(session.outstandingAmount == 0.0, 'Outstanding amount should be 0');
  assert(session.canClose, 'Session with 0 outstanding can close');

  final unpaidSession = session.copyWith(paidAmount: 50000);
  assert(unpaidSession.outstandingAmount == 50000, 'Outstanding should be 50000');
  assert(!unpaidSession.canClose, 'Unpaid session cannot close');

  // Self check complete without throwing AssertionError
}
