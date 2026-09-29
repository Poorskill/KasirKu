import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/product.dart';
import '../../../models/stock_movement.dart';
import '../../../repositories/product_repository.dart';
import '../../../repositories/stock_repository.dart';
import '../../products/presentation/products_provider.dart';

final stockRepositoryProvider = Provider<StockRepository>((ref) {
  return HybridStockRepository();
});

final stockMovementsStreamProvider = StreamProvider<List<StockMovement>>((ref) {
  final repo = ref.watch(stockRepositoryProvider);
  return repo.watchMovements();
});

final stockMovementTypeFilterProvider = StateProvider<String>((ref) => 'all');
final stockMovementSearchProvider = StateProvider<String>((ref) => '');

final filteredStockMovementsProvider = Provider<List<StockMovement>>((ref) {
  final asyncMovements = ref.watch(stockMovementsStreamProvider);
  final typeFilter = ref.watch(stockMovementTypeFilterProvider);
  final search = ref.watch(stockMovementSearchProvider).trim().toLowerCase();

  return asyncMovements.maybeWhen(
    data: (movements) {
      return movements.where((m) {
        if (typeFilter != 'all' && m.type.name != typeFilter) return false;
        if (search.isNotEmpty) {
          final matchProd = m.productName.toLowerCase().contains(search);
          final matchReason = m.reason.toLowerCase().contains(search);
          final matchUser = m.createdBy.toLowerCase().contains(search);
          if (!matchProd && !matchReason && !matchUser) return false;
        }
        return true;
      }).toList();
    },
    orElse: () => [],
  );
});

class StockAdjustmentController extends StateNotifier<AsyncValue<void>> {
  final ProductRepository _productRepo;
  final StockRepository _stockRepo;

  StockAdjustmentController(this._productRepo, this._stockRepo)
      : super(const AsyncValue.data(null));

  Future<bool> adjustStock({
    required Product product,
    required StockMovementType type,
    required int quantityDelta, // positive for in, negative for out/damage
    required String reason,
    required String userName,
  }) async {
    state = const AsyncValue.loading();
    try {
      final prevStock = product.stock;
      final newStock = (prevStock + quantityDelta).clamp(0, 999999);
      final now = DateTime.now();

      // 1. Update product
      final updatedProduct = product.copyWith(
        stock: newStock,
        updatedAt: now,
      );
      await _productRepo.updateProduct(updatedProduct);

      // 2. Record movement
      final movement = StockMovement(
        id: 'SM-${now.millisecondsSinceEpoch}',
        productId: product.id,
        productName: product.name,
        type: type,
        quantity: quantityDelta,
        previousStock: prevStock,
        newStock: newStock,
        reason: reason,
        createdAt: now,
        createdBy: userName,
      );
      await _stockRepo.recordMovement(movement);

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final stockAdjustmentControllerProvider =
    StateNotifierProvider<StockAdjustmentController, AsyncValue<void>>((ref) {
  final productRepo = ref.watch(productRepositoryProvider);
  final stockRepo = ref.watch(stockRepositoryProvider);
  return StockAdjustmentController(productRepo, stockRepo);
});
