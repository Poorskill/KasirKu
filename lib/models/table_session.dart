enum SessionStatus {
  open('Aktif'),
  closing('Menunggu Pembayaran'),
  closed('Ditutup');

  final String label;
  const SessionStatus(this.label);

  static SessionStatus fromString(String val) {
    switch (val.toLowerCase()) {
      case 'closing':
        return SessionStatus.closing;
      case 'closed':
        return SessionStatus.closed;
      case 'open':
      default:
        return SessionStatus.open;
    }
  }
}

class TableSession {
  final String id;
  final String tableId;
  final String tableNumber;
  final String storeId;
  final SessionStatus status;
  final double totalAmount;
  final double paidAmount;
  final List<String> orderIds;
  final DateTime startedAt;
  final DateTime? closedAt;
  final String createdBy;

  const TableSession({
    required this.id,
    required this.tableId,
    required this.tableNumber,
    this.storeId = 'store-default',
    this.status = SessionStatus.open,
    this.totalAmount = 0.0,
    this.paidAmount = 0.0,
    this.orderIds = const [],
    required this.startedAt,
    this.closedAt,
    this.createdBy = 'System',
  });

  double get outstandingAmount =>
      (totalAmount - paidAmount).clamp(0.0, double.infinity);

  bool get canClose => outstandingAmount <= 0.0;

  factory TableSession.fromJson(Map<String, dynamic> json, {String? id}) {
    return TableSession(
      id: id ?? json['id'] as String? ?? '',
      tableId: json['tableId'] as String? ?? '',
      tableNumber: json['tableNumber'] as String? ?? '',
      storeId: json['storeId'] as String? ?? 'store-default',
      status: SessionStatus.fromString(json['status'] as String? ?? 'open'),
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0.0,
      orderIds: (json['orderIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      startedAt: json['startedAt'] != null
          ? DateTime.tryParse(json['startedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      closedAt: json['closedAt'] != null
          ? DateTime.tryParse(json['closedAt'].toString())
          : null,
      createdBy: json['createdBy'] as String? ?? 'System',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tableId': tableId,
      'tableNumber': tableNumber,
      'storeId': storeId,
      'status': status.name,
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'orderIds': orderIds,
      'startedAt': startedAt.toIso8601String(),
      if (closedAt != null) 'closedAt': closedAt!.toIso8601String(),
      'createdBy': createdBy,
    };
  }

  TableSession copyWith({
    String? id,
    String? tableId,
    String? tableNumber,
    String? storeId,
    SessionStatus? status,
    double? totalAmount,
    double? paidAmount,
    List<String>? orderIds,
    DateTime? startedAt,
    DateTime? closedAt,
    String? createdBy,
  }) {
    return TableSession(
      id: id ?? this.id,
      tableId: tableId ?? this.tableId,
      tableNumber: tableNumber ?? this.tableNumber,
      storeId: storeId ?? this.storeId,
      status: status ?? this.status,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      orderIds: orderIds ?? this.orderIds,
      startedAt: startedAt ?? this.startedAt,
      closedAt: closedAt ?? this.closedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}
