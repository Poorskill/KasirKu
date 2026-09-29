import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/product_modifier.dart';
import '../../../models/restaurant_table.dart';
import '../../../models/waiter_call.dart';
import '../../../repositories/waiter_repository.dart';
import '../../tables/presentation/tables_provider.dart';

final waiterRepositoryProvider = Provider<WaiterRepository>((ref) {
  return HybridWaiterRepository();
});

final waiterCallsStreamProvider = StreamProvider<List<WaiterCall>>((ref) {
  final repo = ref.watch(waiterRepositoryProvider);
  return repo.watchWaiterCalls();
});

final customerTableByTokenProvider =
    FutureProvider.family<RestaurantTable?, String>((ref, token) async {
  final repo = ref.watch(tableRepositoryProvider);
  return repo.getTableByToken(token);
});

class CustomerCartState {
  final List<CustomerCartItem> items;
  final String customerName;
  final String? tableToken;

  const CustomerCartState({
    this.items = const [],
    this.customerName = '',
    this.tableToken,
  });

  int get totalItemsCount => items.fold(0, (s, i) => s + i.quantity);

  double get subtotal => items.fold(0.0, (s, i) => s + i.subtotal);

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;

  CustomerCartState copyWith({
    List<CustomerCartItem>? items,
    String? customerName,
    String? tableToken,
  }) {
    return CustomerCartState(
      items: items ?? this.items,
      customerName: customerName ?? this.customerName,
      tableToken: tableToken ?? this.tableToken,
    );
  }
}

class CustomerCartNotifier extends StateNotifier<CustomerCartState> {
  CustomerCartNotifier() : super(const CustomerCartState());

  void setCustomerName(String name) {
    state = state.copyWith(customerName: name);
  }

  void addItem(CustomerCartItem newItem) {
    // Check if identical item (same product and same modifiers) exists
    final index = state.items.indexWhere((i) {
      if (i.product.id != newItem.product.id) return false;
      if (i.note != newItem.note) return false;
      if (i.selectedModifiers.length != newItem.selectedModifiers.length) {
        return false;
      }
      for (int m = 0; m < i.selectedModifiers.length; m++) {
        if (i.selectedModifiers[m].optionId !=
            newItem.selectedModifiers[m].optionId) {
          return false;
        }
      }
      return true;
    });

    if (index >= 0) {
      final existing = state.items[index];
      final updated = List<CustomerCartItem>.from(state.items);
      updated[index] = existing.copyWith(
        quantity: existing.quantity + newItem.quantity,
      );
      state = state.copyWith(items: updated);
    } else {
      final updated = List<CustomerCartItem>.from(state.items)..add(newItem);
      state = state.copyWith(items: updated);
    }
  }

  void incrementQuantity(String cartItemId) {
    final index = state.items.indexWhere((i) => i.id == cartItemId);
    if (index >= 0) {
      final item = state.items[index];
      if (item.quantity < item.product.stock) {
        final updated = List<CustomerCartItem>.from(state.items);
        updated[index] = item.copyWith(quantity: item.quantity + 1);
        state = state.copyWith(items: updated);
      }
    }
  }

  void decrementQuantity(String cartItemId) {
    final index = state.items.indexWhere((i) => i.id == cartItemId);
    if (index >= 0) {
      final item = state.items[index];
      final updated = List<CustomerCartItem>.from(state.items);
      if (item.quantity > 1) {
        updated[index] = item.copyWith(quantity: item.quantity - 1);
      } else {
        updated.removeAt(index);
      }
      state = state.copyWith(items: updated);
    }
  }

  void removeItem(String cartItemId) {
    final updated = state.items.where((i) => i.id != cartItemId).toList();
    state = state.copyWith(items: updated);
  }

  void clearCart() {
    state = state.copyWith(items: []);
  }
}

final customerCartNotifierProvider =
    StateNotifierProvider<CustomerCartNotifier, CustomerCartState>((ref) {
  return CustomerCartNotifier();
});
