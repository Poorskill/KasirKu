import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/online_payment.dart';
import '../../../models/restaurant_order.dart';
import '../../../repositories/order_repository.dart';
import '../../inventory/presentation/stock_provider.dart';
import '../../products/presentation/products_provider.dart';
import '../../tables/presentation/tables_provider.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  final prodRepo = ref.watch(productRepositoryProvider);
  final stockRepo = ref.watch(stockRepositoryProvider);
  final tableRepo = ref.watch(tableRepositoryProvider);
  return HybridOrderRepository(prodRepo, stockRepo, tableRepo);
});

final ordersStreamProvider = StreamProvider<List<RestaurantOrder>>((ref) {
  final repo = ref.watch(orderRepositoryProvider);
  return repo.watchOrders();
});

final paymentsStreamProvider = StreamProvider<List<OnlinePayment>>((ref) {
  final repo = ref.watch(orderRepositoryProvider);
  return repo.watchPayments();
});

// Orders for Kitchen (preparing / ready)
final kitchenOrdersProvider = Provider<List<RestaurantOrder>>((ref) {
  final ordersAsync = ref.watch(ordersStreamProvider);
  return ordersAsync.maybeWhen(
    data: (orders) => orders.where((o) {
      return o.orderStatus == OrderStatus.paid ||
          o.orderStatus == OrderStatus.confirmed ||
          o.orderStatus == OrderStatus.preparing ||
          o.orderStatus == OrderStatus.ready;
    }).toList(),
    orElse: () => [],
  );
});

// Orders for Waiter (ready to serve)
final waiterReadyOrdersProvider = Provider<List<RestaurantOrder>>((ref) {
  final ordersAsync = ref.watch(ordersStreamProvider);
  return ordersAsync.maybeWhen(
    data: (orders) => orders
        .where((o) => o.orderStatus == OrderStatus.ready)
        .toList(),
    orElse: () => [],
  );
});

class OrderController extends StateNotifier<AsyncValue<void>> {
  final OrderRepository _repo;

  OrderController(this._repo) : super(const AsyncValue.data(null));

  Future<bool> updateStatus(String orderId, OrderStatus status) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updateOrderStatus(orderId, status);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> verifyPayment(String paymentId) async {
    state = const AsyncValue.loading();
    try {
      final ok = await _repo.verifyAndSettlePayment(paymentId);
      state = const AsyncValue.data(null);
      return ok;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final orderControllerProvider =
    StateNotifierProvider<OrderController, AsyncValue<void>>((ref) {
  final repo = ref.watch(orderRepositoryProvider);
  return OrderController(repo);
});
