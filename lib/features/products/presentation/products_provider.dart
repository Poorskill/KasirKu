import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/category.dart';
import '../../../models/product.dart';
import '../../../repositories/product_repository.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return HybridProductRepository();
});

final productsStreamProvider = StreamProvider<List<Product>>((ref) {
  final repo = ref.watch(productRepositoryProvider);
  return repo.watchProducts();
});

final categoriesProvider = FutureProvider<List<ProductCategory>>((ref) {
  final repo = ref.watch(productRepositoryProvider);
  return repo.getCategories();
});

final productSearchQueryProvider = StateProvider<String>((ref) => '');
final selectedCategoryFilterProvider = StateProvider<String>((ref) => 'all');
final productStockFilterProvider = StateProvider<String>((ref) => 'all'); // 'all', 'inStock', 'lowStock', 'outOfStock'
final productActiveFilterProvider = StateProvider<String>((ref) => 'active'); // 'all', 'active', 'inactive'
final productSortProvider = StateProvider<String>((ref) => 'nameAsc'); // 'nameAsc', 'priceAsc', 'priceDesc', 'stockAsc', 'stockDesc'

final filteredProductsProvider = Provider<List<Product>>((ref) {
  final productsAsync = ref.watch(productsStreamProvider);
  final search = ref.watch(productSearchQueryProvider).trim().toLowerCase();
  final category = ref.watch(selectedCategoryFilterProvider);
  final stockFilter = ref.watch(productStockFilterProvider);
  final activeFilter = ref.watch(productActiveFilterProvider);
  final sort = ref.watch(productSortProvider);

  return productsAsync.maybeWhen(
    data: (products) {
      final list = products.where((p) {
        // Active filter
        if (activeFilter == 'active' && !p.isActive) return false;
        if (activeFilter == 'inactive' && p.isActive) return false;

        // Category filter
        final matchesCategory = category == 'all' || p.categoryId == category;
        if (!matchesCategory) return false;

        // Stock status filter
        if (stockFilter == 'inStock' && !p.isAvailable) return false;
        if (stockFilter == 'lowStock' && !p.isLowStock) return false;
        if (stockFilter == 'outOfStock' && !p.isOutOfStock) return false;

        // Search query
        final matchesSearch = search.isEmpty ||
            p.name.toLowerCase().contains(search) ||
            p.sku.toLowerCase().contains(search);
        return matchesSearch;
      }).toList();

      // Sorting
      switch (sort) {
        case 'priceAsc':
          list.sort((a, b) => a.price.compareTo(b.price));
        case 'priceDesc':
          list.sort((a, b) => b.price.compareTo(a.price));
        case 'stockAsc':
          list.sort((a, b) => a.stock.compareTo(b.stock));
        case 'stockDesc':
          list.sort((a, b) => b.stock.compareTo(a.stock));
        case 'nameAsc':
        default:
          list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      }

      return list;
    },
    orElse: () => [],
  );
});

final posSearchQueryProvider = StateProvider<String>((ref) => '');
final posCategoryFilterProvider = StateProvider<String>((ref) => 'all');

final activeProductsForPosProvider = Provider<List<Product>>((ref) {
  final productsAsync = ref.watch(productsStreamProvider);
  final search = ref.watch(posSearchQueryProvider).trim().toLowerCase();
  final category = ref.watch(posCategoryFilterProvider);

  return productsAsync.maybeWhen(
    data: (products) {
      return products.where((p) {
        if (!p.isActive) return false;
        final matchesCategory = category == 'all' || p.categoryId == category;
        final matchesSearch = search.isEmpty ||
            p.name.toLowerCase().contains(search) ||
            p.sku.toLowerCase().contains(search);
        return matchesCategory && matchesSearch;
      }).toList();
    },
    orElse: () => [],
  );
});

class ProductController extends StateNotifier<AsyncValue<void>> {
  final ProductRepository _repo;

  ProductController(this._repo) : super(const AsyncValue.data(null));

  Future<bool> addProduct(Product product) async {
    state = const AsyncValue.loading();
    try {
      await _repo.addProduct(product);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateProduct(Product product) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updateProduct(product);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> deleteProduct(String id, {bool permanent = false}) async {
    state = const AsyncValue.loading();
    try {
      await _repo.deleteProduct(id, permanent: permanent);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> toggleActive(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repo.toggleProductActive(id);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final productControllerProvider =
    StateNotifierProvider<ProductController, AsyncValue<void>>((ref) {
  final repo = ref.watch(productRepositoryProvider);
  return ProductController(repo);
});
