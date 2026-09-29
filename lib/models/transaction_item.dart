class TransactionItem {
  final String productId;
  final String productName;
  final double price;
  final double costPrice;
  final int quantity;
  final double subtotal;

  const TransactionItem({
    required this.productId,
    required this.productName,
    required this.price,
    this.costPrice = 0.0,
    required this.quantity,
    required this.subtotal,
  });

  factory TransactionItem.fromJson(Map<String, dynamic> json) {
    return TransactionItem(
      productId: json['productId'] as String? ?? '',
      productName: json['productName'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      costPrice: (json['costPrice'] as num?)?.toDouble() ?? 0.0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'price': price,
      'costPrice': costPrice,
      'quantity': quantity,
      'subtotal': subtotal,
    };
  }

  TransactionItem copyWith({
    String? productId,
    String? productName,
    double? price,
    double? costPrice,
    int? quantity,
    double? subtotal,
  }) {
    return TransactionItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      price: price ?? this.price,
      costPrice: costPrice ?? this.costPrice,
      quantity: quantity ?? this.quantity,
      subtotal: subtotal ?? this.subtotal,
    );
  }
}
