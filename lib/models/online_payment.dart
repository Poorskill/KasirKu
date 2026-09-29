enum OnlinePaymentMethod {
  qris('QRIS Universal (GoPay/OVO/Dana/BCA)'),
  vaBca('BCA Virtual Account'),
  vaMandiri('Mandiri Virtual Account'),
  vaBri('BRI Virtual Account');

  final String label;
  const OnlinePaymentMethod(this.label);
}

enum OnlinePaymentStatus {
  pending('Menunggu Pembayaran'),
  paid('Lunas / Berhasil'),
  failed('Gagal'),
  expired('Kadaluwarsa'),
  cancelled('Dibatalkan'),
  refunded('Dikembalikan');

  final String label;
  const OnlinePaymentStatus(this.label);

  static OnlinePaymentStatus fromString(String val) {
    switch (val.toLowerCase()) {
      case 'paid':
        return OnlinePaymentStatus.paid;
      case 'failed':
        return OnlinePaymentStatus.failed;
      case 'expired':
        return OnlinePaymentStatus.expired;
      case 'cancelled':
        return OnlinePaymentStatus.cancelled;
      case 'refunded':
        return OnlinePaymentStatus.refunded;
      case 'pending':
      default:
        return OnlinePaymentStatus.pending;
    }
  }
}

class OnlinePayment {
  final String id;
  final String orderId;
  final String storeId;
  final String tableId;
  final String tableNumber;
  final String customerName;
  final double amount;
  final OnlinePaymentMethod method;
  final OnlinePaymentStatus status;
  final String paymentReference; // e.g. Midtrans Transaction ID / QR payload
  final DateTime? paidAt;
  final DateTime createdAt;

  const OnlinePayment({
    required this.id,
    required this.orderId,
    this.storeId = 'store-default',
    required this.tableId,
    required this.tableNumber,
    required this.customerName,
    required this.amount,
    this.method = OnlinePaymentMethod.qris,
    this.status = OnlinePaymentStatus.pending,
    required this.paymentReference,
    this.paidAt,
    required this.createdAt,
  });

  bool get isPaid => status == OnlinePaymentStatus.paid;

  factory OnlinePayment.fromJson(Map<String, dynamic> json, {String? id}) {
    return OnlinePayment(
      id: id ?? json['id'] as String? ?? '',
      orderId: json['orderId'] as String? ?? '',
      storeId: json['storeId'] as String? ?? 'store-default',
      tableId: json['tableId'] as String? ?? '',
      tableNumber: json['tableNumber'] as String? ?? '',
      customerName: json['customerName'] as String? ?? 'Pelanggan',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      method: OnlinePaymentMethod.values.firstWhere(
        (m) => m.name == json['method'],
        orElse: () => OnlinePaymentMethod.qris,
      ),
      status: OnlinePaymentStatus.fromString(json['status'] as String? ?? 'pending'),
      paymentReference: json['paymentReference'] as String? ?? '',
      paidAt: json['paidAt'] != null
          ? DateTime.tryParse(json['paidAt'].toString())
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderId': orderId,
      'storeId': storeId,
      'tableId': tableId,
      'tableNumber': tableNumber,
      'customerName': customerName,
      'amount': amount,
      'method': method.name,
      'status': status.name,
      'paymentReference': paymentReference,
      if (paidAt != null) 'paidAt': paidAt!.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  OnlinePayment copyWith({
    String? id,
    String? orderId,
    String? storeId,
    String? tableId,
    String? tableNumber,
    String? customerName,
    double? amount,
    OnlinePaymentMethod? method,
    OnlinePaymentStatus? status,
    String? paymentReference,
    DateTime? paidAt,
    DateTime? createdAt,
  }) {
    return OnlinePayment(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      storeId: storeId ?? this.storeId,
      tableId: tableId ?? this.tableId,
      tableNumber: tableNumber ?? this.tableNumber,
      customerName: customerName ?? this.customerName,
      amount: amount ?? this.amount,
      method: method ?? this.method,
      status: status ?? this.status,
      paymentReference: paymentReference ?? this.paymentReference,
      paidAt: paidAt ?? this.paidAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
