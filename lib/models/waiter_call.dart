enum WaiterCallStatus {
  pending('Menunggu'),
  acknowledged('Diproses'),
  resolved('Selesai'),
  cancelled('Dibatalkan');

  final String label;
  const WaiterCallStatus(this.label);

  static WaiterCallStatus fromString(String val) {
    switch (val.toLowerCase()) {
      case 'acknowledged':
        return WaiterCallStatus.acknowledged;
      case 'resolved':
        return WaiterCallStatus.resolved;
      case 'cancelled':
        return WaiterCallStatus.cancelled;
      case 'pending':
      default:
        return WaiterCallStatus.pending;
    }
  }
}

class WaiterCall {
  final String id;
  final String storeId;
  final String tableId;
  final String tableNumber;
  final String? sessionId;
  final String type; // e.g. "Minta Bill", "Minta Air Minum", "Bantuan Pelayan", "Alat Makan"
  final String message;
  final WaiterCallStatus status;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  const WaiterCall({
    required this.id,
    this.storeId = 'store-default',
    required this.tableId,
    required this.tableNumber,
    this.sessionId,
    required this.type,
    this.message = '',
    this.status = WaiterCallStatus.pending,
    required this.createdAt,
    this.resolvedAt,
  });

  factory WaiterCall.fromJson(Map<String, dynamic> json, {String? id}) {
    return WaiterCall(
      id: id ?? json['id'] as String? ?? '',
      storeId: json['storeId'] as String? ?? 'store-default',
      tableId: json['tableId'] as String? ?? '',
      tableNumber: json['tableNumber'] as String? ?? '',
      sessionId: json['sessionId'] as String?,
      type: json['type'] as String? ?? 'Bantuan Pelayan',
      message: json['message'] as String? ?? '',
      status: WaiterCallStatus.fromString(json['status'] as String? ?? 'pending'),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      resolvedAt: json['resolvedAt'] != null
          ? DateTime.tryParse(json['resolvedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'storeId': storeId,
      'tableId': tableId,
      'tableNumber': tableNumber,
      'sessionId': sessionId,
      'type': type,
      'message': message,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      if (resolvedAt != null) 'resolvedAt': resolvedAt!.toIso8601String(),
    };
  }

  WaiterCall copyWith({
    String? id,
    String? storeId,
    String? tableId,
    String? tableNumber,
    String? sessionId,
    String? type,
    String? message,
    WaiterCallStatus? status,
    DateTime? createdAt,
    DateTime? resolvedAt,
  }) {
    return WaiterCall(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      tableId: tableId ?? this.tableId,
      tableNumber: tableNumber ?? this.tableNumber,
      sessionId: sessionId ?? this.sessionId,
      type: type ?? this.type,
      message: message ?? this.message,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }
}
