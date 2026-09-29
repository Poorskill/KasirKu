import 'product_modifier.dart';

enum OrderSource {
  tableQr('QR Meja'),
  pos('Kasir POS'),
  waiter('Pelayan');

  final String label;
  const OrderSource(this.label);
}

enum OrderStatus {
  pendingPayment('Menunggu Bayar'),
  paid('Sudah Dibayar'),
  confirmed('Diterima Kasir'),
  preparing('Sedang Dimasak'),
  ready('Siap Diantar'),
  served('Disajikan'),
  completed('Selesai'),
  cancelled('Dibatalkan'),
  refunded('Dikembalikan');

  final String label;
  const OrderStatus(this.label);

  static OrderStatus fromString(String val) {
    switch (val.toLowerCase()) {
      case 'paid':
        return OrderStatus.paid;
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'preparing':
        return OrderStatus.preparing;
      case 'ready':
        return OrderStatus.ready;
      case 'served':
        return OrderStatus.served;
      case 'completed':
        return OrderStatus.completed;
      case 'cancelled':
        return OrderStatus.cancelled;
      case 'refunded':
        return OrderStatus.refunded;
      case 'pendingpayment':
      case 'pending_payment':
      default:
        return OrderStatus.pendingPayment;
    }
  }
}

class RestaurantOrderItem {
  final String productId;
  final String productName;
  final double unitPrice;
  final int quantity;
  final double subtotal;
  final List<SelectedModifier> modifiers;
  final String note;

  const RestaurantOrderItem({
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    required this.subtotal,
    this.modifiers = const [],
    this.note = '',
  });

  factory RestaurantOrderItem.fromCustomerCartItem(CustomerCartItem cartItem) {
    return RestaurantOrderItem(
      productId: cartItem.product.id,
      productName: cartItem.product.name,
      unitPrice: cartItem.unitPrice,
      quantity: cartItem.quantity,
      subtotal: cartItem.subtotal,
      modifiers: cartItem.selectedModifiers,
      note: cartItem.note,
    );
  }

  factory RestaurantOrderItem.fromJson(Map<String, dynamic> json) {
    return RestaurantOrderItem(
      productId: json['productId'] as String? ?? '',
      productName: json['productName'] as String? ?? '',
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      modifiers: (json['modifiers'] as List<dynamic>? ?? [])
          .map((m) => SelectedModifier.fromJson(m as Map<String, dynamic>))
          .toList(),
      note: json['note'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'unitPrice': unitPrice,
      'quantity': quantity,
      'subtotal': subtotal,
      'modifiers': modifiers.map((m) => m.toJson()).toList(),
      'note': note,
    };
  }
}

class RestaurantOrder {
  final String id;
  final String storeId;
  final String tableId;
  final String? tableSessionId;
  final String tableNumber;
  final String orderNumber; // e.g. "ORD-1028"
  final String customerName;
  final List<RestaurantOrderItem> items;
  final double subtotal;
  final double discount;
  final double tax;
  final double total;
  final String paymentStatus; // 'pending' | 'paid' | 'failed' | 'refunded'
  final OrderStatus orderStatus;
  final OrderSource source;
  final String? cashierId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;

  const RestaurantOrder({
    required this.id,
    this.storeId = 'store-default',
    required this.tableId,
    this.tableSessionId,
    required this.tableNumber,
    required this.orderNumber,
    required this.customerName,
    required this.items,
    required this.subtotal,
    this.discount = 0.0,
    this.tax = 0.0,
    required this.total,
    this.paymentStatus = 'pending',
    this.orderStatus = OrderStatus.pendingPayment,
    this.source = OrderSource.tableQr,
    this.cashierId,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
  });

  bool get isPaid => paymentStatus == 'paid';
  bool get isKitchenActive =>
      orderStatus == OrderStatus.confirmed ||
      orderStatus == OrderStatus.preparing;

  factory RestaurantOrder.fromJson(Map<String, dynamic> json, {String? id}) {
    return RestaurantOrder(
      id: id ?? json['id'] as String? ?? '',
      storeId: json['storeId'] as String? ?? 'store-default',
      tableId: json['tableId'] as String? ?? '',
      tableSessionId: json['tableSessionId'] as String?,
      tableNumber: json['tableNumber'] as String? ?? '',
      orderNumber: json['orderNumber'] as String? ?? '',
      customerName: json['customerName'] as String? ?? 'Pelanggan',
      items: (json['items'] as List<dynamic>? ?? [])
          .map((i) => RestaurantOrderItem.fromJson(i as Map<String, dynamic>))
          .toList(),
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      tax: (json['tax'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      paymentStatus: json['paymentStatus'] as String? ?? 'pending',
      orderStatus: OrderStatus.fromString(json['orderStatus'] as String? ?? 'pendingPayment'),
      source: OrderSource.values.firstWhere(
        (s) => s.name == json['source'],
        orElse: () => OrderSource.tableQr,
      ),
      cashierId: json['cashierId'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'storeId': storeId,
      'tableId': tableId,
      'tableSessionId': tableSessionId,
      'tableNumber': tableNumber,
      'orderNumber': orderNumber,
      'customerName': customerName,
      'items': items.map((i) => i.toJson()).toList(),
      'subtotal': subtotal,
      'discount': discount,
      'tax': tax,
      'total': total,
      'paymentStatus': paymentStatus,
      'orderStatus': orderStatus.name,
      'source': source.name,
      'cashierId': cashierId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
    };
  }

  RestaurantOrder copyWith({
    String? id,
    String? storeId,
    String? tableId,
    String? tableSessionId,
    String? tableNumber,
    String? orderNumber,
    String? customerName,
    List<RestaurantOrderItem>? items,
    double? subtotal,
    double? discount,
    double? tax,
    double? total,
    String? paymentStatus,
    OrderStatus? orderStatus,
    OrderSource? source,
    String? cashierId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
  }) {
    return RestaurantOrder(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      tableId: tableId ?? this.tableId,
      tableSessionId: tableSessionId ?? this.tableSessionId,
      tableNumber: tableNumber ?? this.tableNumber,
      orderNumber: orderNumber ?? this.orderNumber,
      customerName: customerName ?? this.customerName,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      tax: tax ?? this.tax,
      total: total ?? this.total,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      orderStatus: orderStatus ?? this.orderStatus,
      source: source ?? this.source,
      cashierId: cashierId ?? this.cashierId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
