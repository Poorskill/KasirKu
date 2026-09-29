enum StockMovementType {
  stockIn('Masuk (Restock)'),
  stockOut('Keluar'),
  adjustment('Penyesuaian (Opname)'),
  sale('Penjualan POS');

  final String label;
  const StockMovementType(this.label);

  static StockMovementType fromString(String val) {
    switch (val.toLowerCase()) {
      case 'stockin':
      case 'in':
        return StockMovementType.stockIn;
      case 'stockout':
      case 'out':
        return StockMovementType.stockOut;
      case 'sale':
        return StockMovementType.sale;
      case 'adjustment':
      default:
        return StockMovementType.adjustment;
    }
  }
}

class StockMovement {
  final String id;
  final String productId;
  final String productName;
  final StockMovementType type;
  final int quantity; // change amount: e.g. +10 or -3
  final int previousStock;
  final int newStock;
  final String reason;
  final DateTime createdAt;
  final String createdBy;

  const StockMovement({
    required this.id,
    required this.productId,
    required this.productName,
    required this.type,
    required this.quantity,
    required this.previousStock,
    required this.newStock,
    required this.reason,
    required this.createdAt,
    this.createdBy = 'Admin',
  });

  factory StockMovement.fromJson(Map<String, dynamic> json, {String? id}) {
    return StockMovement(
      id: id ?? json['id'] as String? ?? '',
      productId: json['productId'] as String? ?? '',
      productName: json['productName'] as String? ?? '',
      type: StockMovementType.fromString(json['type'] as String? ?? 'adjustment'),
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      previousStock: (json['previousStock'] as num?)?.toInt() ?? 0,
      newStock: (json['newStock'] as num?)?.toInt() ?? 0,
      reason: json['reason'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      createdBy: json['createdBy'] as String? ?? 'Admin',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'type': type.name,
      'quantity': quantity,
      'previousStock': previousStock,
      'newStock': newStock,
      'reason': reason,
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
    };
  }
}
