import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/pricing_calculator.dart';
import '../../../models/product.dart';
import '../../../models/restaurant_table.dart';
import '../../../models/transaction_item.dart';

enum PosOrderType {
  dineIn('Makan di Tempat (Dine-in)'),
  takeaway('Bawa Pulang (Takeaway)');

  final String label;
  const PosOrderType(this.label);
}

class CartItem {
  final Product product;
  final int quantity;

  const CartItem({
    required this.product,
    required this.quantity,
  });

  double get subtotal => product.price * quantity;

  CartItem copyWith({Product? product, int? quantity}) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }

  TransactionItem toTransactionItem() {
    return TransactionItem(
      productId: product.id,
      productName: product.name,
      price: product.price,
      costPrice: product.costPrice,
      quantity: quantity,
      subtotal: subtotal,
    );
  }
}

class CartState {
  final List<CartItem> items;
  final DiscountType discountType;
  final double discountValue;
  final double taxRate; // in percent: e.g. 0.0 or 11.0
  final PosOrderType orderType;
  final RestaurantTable? selectedTable;

  const CartState({
    this.items = const [],
    this.discountType = DiscountType.fixed,
    this.discountValue = 0.0,
    this.taxRate = 0.0,
    this.orderType = PosOrderType.dineIn,
    this.selectedTable,
  });

  bool get isDineIn => orderType == PosOrderType.dineIn;
  bool get isTakeaway => orderType == PosOrderType.takeaway;

  int get totalItemsCount =>
      items.fold(0, (sum, item) => sum + item.quantity);

  double get rawSubtotal =>
      items.fold(0.0, (sum, item) => sum + item.subtotal);

  OrderPricingResult get pricing => PricingCalculator.calculate(
        subtotal: rawSubtotal,
        discountType: discountType,
        discountValue: discountValue,
        taxRate: taxRate,
      );

  double get subtotal => pricing.subtotal;
  double get discount => pricing.discountAmount;
  double get taxAmount => pricing.taxAmount;
  double get total => pricing.grandTotal;

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;

  CartState copyWith({
    List<CartItem>? items,
    DiscountType? discountType,
    double? discountValue,
    double? taxRate,
    PosOrderType? orderType,
    RestaurantTable? selectedTable,
    bool clearTable = false,
  }) {
    return CartState(
      items: items ?? this.items,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      taxRate: taxRate ?? this.taxRate,
      orderType: orderType ?? this.orderType,
      selectedTable: clearTable ? null : (selectedTable ?? this.selectedTable),
    );
  }
}

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(const CartState());

  void setOrderType(PosOrderType type) {
    if (type == PosOrderType.takeaway) {
      state = state.copyWith(orderType: type, clearTable: true);
    } else {
      state = state.copyWith(orderType: type);
    }
  }

  void setSelectedTable(RestaurantTable? table) {
    state = state.copyWith(selectedTable: table, clearTable: table == null);
  }

  void addItem(Product product) {
    if (product.isOutOfStock || !product.isActive) return;

    final index = state.items.indexWhere((item) => item.product.id == product.id);
    if (index >= 0) {
      final currentItem = state.items[index];
      if (currentItem.quantity < product.stock) {
        final updatedItems = List<CartItem>.from(state.items);
        updatedItems[index] = currentItem.copyWith(
          quantity: currentItem.quantity + 1,
        );
        state = state.copyWith(items: updatedItems);
      }
    } else {
      final newItems = List<CartItem>.from(state.items)
        ..add(CartItem(product: product, quantity: 1));
      state = state.copyWith(items: newItems);
    }
  }

  void incrementItem(String productId) {
    final index = state.items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      final item = state.items[index];
      if (item.quantity < item.product.stock) {
        final updated = List<CartItem>.from(state.items);
        updated[index] = item.copyWith(quantity: item.quantity + 1);
        state = state.copyWith(items: updated);
      }
    }
  }

  void decrementItem(String productId) {
    final index = state.items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      final item = state.items[index];
      final updated = List<CartItem>.from(state.items);
      if (item.quantity > 1) {
        updated[index] = item.copyWith(quantity: item.quantity - 1);
      } else {
        updated.removeAt(index);
      }
      state = state.copyWith(items: updated);
    }
  }

  void removeItem(String productId) {
    final updated = state.items.where((i) => i.product.id != productId).toList();
    state = state.copyWith(items: updated);
  }

  void setDiscount({required DiscountType type, required double value}) {
    state = state.copyWith(discountType: type, discountValue: value);
  }

  void setTaxRate(double rate) {
    state = state.copyWith(taxRate: rate);
  }

  void clearCart() {
    state = CartState(
      orderType: state.orderType,
      selectedTable: state.selectedTable,
    );
  }
}

final cartNotifierProvider =
    StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});
