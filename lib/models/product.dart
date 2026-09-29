class Product {
  final String id;
  final String name;
  final String sku;
  final String categoryId;
  final double price;
  final double costPrice;
  final int stock;
  final int minimumStock;
  final String? imageUrl;
  final String? description;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Product({
    required this.id,
    required this.name,
    required this.sku,
    required this.categoryId,
    required this.price,
    required this.costPrice,
    required this.stock,
    this.minimumStock = 5,
    this.imageUrl,
    this.description,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isOutOfStock => stock <= 0;
  bool get isLowStock => stock > 0 && stock <= minimumStock;
  bool get isAvailable => stock > minimumStock;

  factory Product.fromJson(Map<String, dynamic> json, {String? id}) {
    return Product(
      id: id ?? json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      sku: json['sku'] as String? ?? '',
      categoryId: json['categoryId'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      costPrice: (json['costPrice'] as num?)?.toDouble() ?? 0.0,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      minimumStock: (json['minimumStock'] as num?)?.toInt() ?? 5,
      imageUrl: json['imageUrl'] as String?,
      description: json['description'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sku': sku,
      'categoryId': categoryId,
      'price': price,
      'costPrice': costPrice,
      'stock': stock,
      'minimumStock': minimumStock,
      'imageUrl': imageUrl,
      'description': description,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Product copyWith({
    String? id,
    String? name,
    String? sku,
    String? categoryId,
    double? price,
    double? costPrice,
    int? stock,
    int? minimumStock,
    String? imageUrl,
    String? description,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      categoryId: categoryId ?? this.categoryId,
      price: price ?? this.price,
      costPrice: costPrice ?? this.costPrice,
      stock: stock ?? this.stock,
      minimumStock: minimumStock ?? this.minimumStock,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
