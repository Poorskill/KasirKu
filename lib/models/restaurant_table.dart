enum TableStatus {
  available('Tersedia'),
  occupied('Terisi'),
  reserved('Dipesan'),
  cleaning('Dibersihkan'),
  inactive('Non-aktif');

  final String label;
  const TableStatus(this.label);

  static TableStatus fromString(String val) {
    switch (val.toLowerCase()) {
      case 'occupied':
        return TableStatus.occupied;
      case 'reserved':
        return TableStatus.reserved;
      case 'cleaning':
        return TableStatus.cleaning;
      case 'inactive':
        return TableStatus.inactive;
      case 'available':
      default:
        return TableStatus.available;
    }
  }
}

class RestaurantTable {
  final String id;
  final String storeId;
  final String tableNumber; // e.g. "01", "02"
  final String name; // e.g. "Meja 01 (Indoor)"
  final int capacity;
  final TableStatus status;
  final String qrToken; // unique secure unguessable token
  final bool isActive;
  final String? currentSessionId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RestaurantTable({
    required this.id,
    this.storeId = 'store-default',
    required this.tableNumber,
    required this.name,
    this.capacity = 4,
    this.status = TableStatus.available,
    required this.qrToken,
    this.isActive = true,
    this.currentSessionId,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isAvailable => status == TableStatus.available;
  bool get isOccupied => status == TableStatus.occupied;
  bool get isReserved => status == TableStatus.reserved;

  factory RestaurantTable.fromJson(Map<String, dynamic> json, {String? id}) {
    return RestaurantTable(
      id: id ?? json['id'] as String? ?? '',
      storeId: json['storeId'] as String? ?? 'store-default',
      tableNumber: json['tableNumber'] as String? ?? '',
      name: json['name'] as String? ?? '',
      capacity: (json['capacity'] as num?)?.toInt() ?? 4,
      status: TableStatus.fromString(json['status'] as String? ?? 'available'),
      qrToken: json['qrToken'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
      currentSessionId: json['currentSessionId'] as String?,
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
      'storeId': storeId,
      'tableNumber': tableNumber,
      'name': name,
      'capacity': capacity,
      'status': status.name,
      'qrToken': qrToken,
      'isActive': isActive,
      'currentSessionId': currentSessionId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  RestaurantTable copyWith({
    String? id,
    String? storeId,
    String? tableNumber,
    String? name,
    int? capacity,
    TableStatus? status,
    String? qrToken,
    bool? isActive,
    String? currentSessionId,
    bool clearSession = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RestaurantTable(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      tableNumber: tableNumber ?? this.tableNumber,
      name: name ?? this.name,
      capacity: capacity ?? this.capacity,
      status: status ?? this.status,
      qrToken: qrToken ?? this.qrToken,
      isActive: isActive ?? this.isActive,
      currentSessionId:
          clearSession ? null : (currentSessionId ?? this.currentSessionId),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
