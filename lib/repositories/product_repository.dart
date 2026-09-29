import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/category.dart';
import '../models/product.dart';

abstract class ProductRepository {
  Stream<List<Product>> watchProducts();
  Future<List<Product>> getProducts();
  Future<void> addProduct(Product product);
  Future<void> updateProduct(Product product);
  Future<void> deleteProduct(String id, {bool permanent = false});
  Future<void> toggleProductActive(String id);
  Future<void> adjustStock(String productId, int quantityDelta);
  Future<List<ProductCategory>> getCategories();
}

class HybridProductRepository implements ProductRepository {
  final _inMemoryController = StreamController<List<Product>>.broadcast();
  List<Product> _inMemoryProducts = [];
  bool _firebaseReady = false;

  HybridProductRepository() {
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
      _seedInitialData();
    }
  }

  void _seedInitialData() {
    final now = DateTime.now();
    _inMemoryProducts = [
      Product(
        id: 'prod-1',
        name: 'Kopi Susu Gula Aren',
        sku: 'KOP-001',
        categoryId: 'cat-minuman',
        price: 18000,
        costPrice: 8000,
        stock: 35,
        minimumStock: 10,
        isActive: true,
        imageUrl:
            'https://images.unsplash.com/photo-1541167760496-1628856ab772?w=500&auto=format&fit=crop&q=80',
        description: 'Espresso dengan susu segar dan gula aren asli',
        createdAt: now.subtract(const Duration(days: 30)),
        updatedAt: now,
      ),
      Product(
        id: 'prod-2',
        name: 'Es Teh Manis',
        sku: 'TEH-001',
        categoryId: 'cat-minuman',
        price: 6000,
        costPrice: 2000,
        stock: 80,
        minimumStock: 15,
        isActive: true,
        imageUrl:
            'https://images.unsplash.com/photo-1556679343-c7306c1976bc?w=500&auto=format&fit=crop&q=80',
        description: 'Teh melati manis segar dingin',
        createdAt: now.subtract(const Duration(days: 28)),
        updatedAt: now,
      ),
      Product(
        id: 'prod-3',
        name: 'Mie Goreng Spesial',
        sku: 'MKN-001',
        categoryId: 'cat-makanan',
        price: 22000,
        costPrice: 12000,
        stock: 18,
        minimumStock: 5,
        isActive: true,
        imageUrl:
            'https://images.unsplash.com/photo-1612927601601-6638404737ce?w=500&auto=format&fit=crop&q=80',
        description: 'Mie goreng komplit dengan telur, ayam suwir, dan sayuran',
        createdAt: now.subtract(const Duration(days: 25)),
        updatedAt: now,
      ),
      Product(
        id: 'prod-4',
        name: 'Roti Bakar Cokelat Keju',
        sku: 'SNK-001',
        categoryId: 'cat-snack',
        price: 15000,
        costPrice: 7000,
        stock: 7,
        minimumStock: 10,
        isActive: true,
        imageUrl:
            'https://images.unsplash.com/photo-1584776296944-ab6fb57b0bdd?w=500&auto=format&fit=crop&q=80',
        description: 'Roti bakar lezat dengan taburan cokelat melimpah dan keju parut',
        createdAt: now.subtract(const Duration(days: 20)),
        updatedAt: now,
      ),
      Product(
        id: 'prod-5',
        name: 'Air Mineral 600ml',
        sku: 'MNR-001',
        categoryId: 'cat-minuman',
        price: 5000,
        costPrice: 2500,
        stock: 50,
        minimumStock: 12,
        isActive: true,
        imageUrl:
            'https://images.unsplash.com/photo-1548839140-29a749e1bc4e?w=500&auto=format&fit=crop&q=80',
        description: 'Air mineral pegunungan dalam kemasan botol',
        createdAt: now.subtract(const Duration(days: 15)),
        updatedAt: now,
      ),
      Product(
        id: 'prod-6',
        name: 'Pisang Goreng Crispy',
        sku: 'SNK-002',
        categoryId: 'cat-snack',
        price: 12000,
        costPrice: 5000,
        stock: 4,
        minimumStock: 8,
        isActive: true,
        imageUrl:
            'https://images.unsplash.com/photo-1528735602780-2552fd46c7af?w=500&auto=format&fit=crop&q=80',
        description: 'Pisang raja goreng renyah dengan susu kental manis',
        createdAt: now.subtract(const Duration(days: 10)),
        updatedAt: now,
      ),
      Product(
        id: 'prod-7',
        name: 'Nasi Goreng Kampung',
        sku: 'MKN-002',
        categoryId: 'cat-makanan',
        price: 25000,
        costPrice: 13000,
        stock: 0,
        minimumStock: 5,
        isActive: true,
        imageUrl:
            'https://images.unsplash.com/photo-1603133872878-684f208fb84b?w=500&auto=format&fit=crop&q=80',
        description: 'Nasi goreng bumbu terasi tradisional dengan telur ceplok',
        createdAt: now.subtract(const Duration(days: 8)),
        updatedAt: now,
      ),
      Product(
        id: 'prod-8',
        name: 'Caffè Americano',
        sku: 'KOP-002',
        categoryId: 'cat-minuman',
        price: 16000,
        costPrice: 6000,
        stock: 22,
        minimumStock: 8,
        isActive: true,
        imageUrl:
            'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?w=500&auto=format&fit=crop&q=80',
        description: 'Double shot espresso dengan air panas',
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now,
      ),
    ];
    _inMemoryController.add(List.unmodifiable(_inMemoryProducts));
  }

  @override
  Stream<List<Product>> watchProducts() async* {
    if (_firebaseReady) {
      try {
        yield* FirebaseFirestore.instance
            .collection('products')
            .orderBy('name')
            .snapshots()
            .map((snap) {
          if (snap.docs.isEmpty) {
            return List.unmodifiable(_inMemoryProducts);
          }
          return snap.docs
              .map((doc) => Product.fromJson(doc.data(), id: doc.id))
              .toList();
        });
        return;
      } catch (_) {
        // fallback to local
      }
    }
    yield List.unmodifiable(_inMemoryProducts);
    yield* _inMemoryController.stream;
  }

  @override
  Future<List<Product>> getProducts() async {
    if (_firebaseReady) {
      try {
        final snap = await FirebaseFirestore.instance
            .collection('products')
            .orderBy('name')
            .get();
        return snap.docs
            .map((doc) => Product.fromJson(doc.data(), id: doc.id))
            .toList();
      } catch (_) {}
    }
    return List.unmodifiable(_inMemoryProducts);
  }

  @override
  Future<void> addProduct(Product product) async {
    if (_firebaseReady) {
      try {
        final docRef = FirebaseFirestore.instance.collection('products').doc();
        final toSave = product.copyWith(id: docRef.id);
        await docRef.set(toSave.toJson());
        return;
      } catch (_) {}
    }

    _inMemoryProducts.insert(0, product);
    _inMemoryController.add(List.unmodifiable(_inMemoryProducts));
  }

  @override
  Future<void> updateProduct(Product product) async {
    if (_firebaseReady) {
      try {
        await FirebaseFirestore.instance
            .collection('products')
            .doc(product.id)
            .update(product.toJson());
        return;
      } catch (_) {}
    }

    final index = _inMemoryProducts.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      _inMemoryProducts[index] = product;
      _inMemoryController.add(List.unmodifiable(_inMemoryProducts));
    }
  }

  @override
  Future<void> deleteProduct(String id, {bool permanent = false}) async {
    if (permanent) {
      if (_firebaseReady) {
        try {
          await FirebaseFirestore.instance.collection('products').doc(id).delete();
          return;
        } catch (_) {}
      }
      _inMemoryProducts.removeWhere((p) => p.id == id);
    } else {
      // Soft delete: marks product as inactive
      if (_firebaseReady) {
        try {
          await FirebaseFirestore.instance.collection('products').doc(id).update({
            'isActive': false,
            'updatedAt': DateTime.now().toIso8601String(),
          });
          return;
        } catch (_) {}
      }
      final index = _inMemoryProducts.indexWhere((p) => p.id == id);
      if (index != -1) {
        _inMemoryProducts[index] = _inMemoryProducts[index].copyWith(
          isActive: false,
          updatedAt: DateTime.now(),
        );
      }
    }
    _inMemoryController.add(List.unmodifiable(_inMemoryProducts));
  }

  @override
  Future<void> toggleProductActive(String id) async {
    final index = _inMemoryProducts.indexWhere((p) => p.id == id);
    if (index != -1) {
      final updated = _inMemoryProducts[index].copyWith(
        isActive: !_inMemoryProducts[index].isActive,
        updatedAt: DateTime.now(),
      );
      if (_firebaseReady) {
        try {
          await FirebaseFirestore.instance
              .collection('products')
              .doc(id)
              .update(updated.toJson());
        } catch (_) {}
      }
      _inMemoryProducts[index] = updated;
      _inMemoryController.add(List.unmodifiable(_inMemoryProducts));
    }
  }

  @override
  Future<void> adjustStock(String productId, int quantityDelta) async {
    if (_firebaseReady) {
      try {
        final docRef =
            FirebaseFirestore.instance.collection('products').doc(productId);
        await FirebaseFirestore.instance.runTransaction((tx) async {
          final snap = await tx.get(docRef);
          if (snap.exists) {
            final currentStock = (snap.data()?['stock'] as num?)?.toInt() ?? 0;
            final newStock = (currentStock - quantityDelta).clamp(0, 999999);
            tx.update(docRef, {
              'stock': newStock,
              'updatedAt': DateTime.now().toIso8601String(),
            });
          }
        });
        return;
      } catch (_) {}
    }

    final index = _inMemoryProducts.indexWhere((p) => p.id == productId);
    if (index != -1) {
      final cur = _inMemoryProducts[index];
      final newStock = (cur.stock - quantityDelta).clamp(0, 999999);
      _inMemoryProducts[index] = cur.copyWith(
        stock: newStock,
        updatedAt: DateTime.now(),
      );
      _inMemoryController.add(List.unmodifiable(_inMemoryProducts));
    }
  }

  @override
  Future<List<ProductCategory>> getCategories() async {
    return const [
      ProductCategory(id: 'all', name: 'Semua Kategori', icon: 'apps'),
      ProductCategory(id: 'cat-makanan', name: 'Makanan', icon: 'restaurant'),
      ProductCategory(id: 'cat-minuman', name: 'Minuman', icon: 'local_cafe'),
      ProductCategory(id: 'cat-snack', name: 'Snack / Camilan', icon: 'bakery_dining'),
    ];
  }
}
