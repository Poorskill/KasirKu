import 'transaction_item.dart';

enum PaymentMethod {
  cash('Tunai'),
  transfer('Transfer Bank'),
  qris('QRIS');

  final String label;
  const PaymentMethod(this.label);

  static PaymentMethod fromString(String val) {
    switch (val.toLowerCase()) {
      case 'transfer':
      case 'bank':
        return PaymentMethod.transfer;
      case 'qris':
        return PaymentMethod.qris;
      case 'cash':
      case 'tunai':
      default:
        return PaymentMethod.cash;
    }
  }
}

class TransactionRecord {
  final String id;
  final String cashierId;
  final String cashierName;
  final List<TransactionItem> items;
  final double subtotal;
  final double discount;
  final double tax;
  final double total;
  final PaymentMethod paymentMethod;
  final double paymentAmount;
  final double change;
  final String orderType; // 'dineIn' | 'takeaway'
  final String? tableId;
  final String? tableNumber;
  final DateTime createdAt;
  final String status; // 'success' | 'cancelled'

  const TransactionRecord({
    required this.id,
    required this.cashierId,
    this.cashierName = 'Admin',
    required this.items,
    required this.subtotal,
    this.discount = 0.0,
    this.tax = 0.0,
    required this.total,
    required this.paymentMethod,
    required this.paymentAmount,
    required this.change,
    this.orderType = 'takeaway',
    this.tableId,
    this.tableNumber,
    required this.createdAt,
    this.status = 'success',
  });

  bool get isDineIn => orderType == 'dineIn';
  bool get isTakeaway => orderType == 'takeaway';

  factory TransactionRecord.fromJson(Map<String, dynamic> json, {String? id}) {
    return TransactionRecord(
      id: id ?? json['id'] as String? ?? '',
      cashierId: json['cashierId'] as String? ?? '',
      cashierName: json['cashierName'] as String? ?? 'Admin',
      items: (json['items'] as List<dynamic>? ?? [])
          .map((item) => TransactionItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      tax: (json['tax'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: PaymentMethod.fromString(json['paymentMethod'] as String? ?? 'cash'),
      paymentAmount: (json['paymentAmount'] as num?)?.toDouble() ?? 0.0,
      change: (json['change'] as num?)?.toDouble() ?? 0.0,
      orderType: json['orderType'] as String? ?? 'takeaway',
      tableId: json['tableId'] as String?,
      tableNumber: json['tableNumber'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      status: json['status'] as String? ?? 'success',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cashierId': cashierId,
      'cashierName': cashierName,
      'items': items.map((i) => i.toJson()).toList(),
      'subtotal': subtotal,
      'discount': discount,
      'tax': tax,
      'total': total,
      'paymentMethod': paymentMethod.name,
      'paymentAmount': paymentAmount,
      'change': change,
      'orderType': orderType,
      'tableId': tableId,
      'tableNumber': tableNumber,
      'createdAt': createdAt.toIso8601String(),
      'status': status,
    };
  }
}
